"""Hold Expiration Worker

Background worker that restores expired HOLD requests to IN_PROGRESS.

The worker is deadline-aware rather than polling at a fixed interval:

- Sleeps until the next hold expires.
- PostgreSQL NOTIFY wakes it when a new hold is created.
- A 15-minute maximum wake interval acts as a safety net.
- PostgreSQL remains the source of truth for hold deadlines.

Run this as a separate container/process.
"""

import logging
import os
import select
import threading
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any
from dotenv import load_dotenv
from sqlalchemy import desc

# Configure logging before importing application modules.
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)

# Load environment variables from root .env.
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from config.database import SessionLocal, engine
from models.enums import RequestStatus, TrackEventType
from models.holding_request import HoldingRequest, HoldingRequestTable
from models.request import Request
from models.track import RequestTrack, RequestTrackTable
from services.notification_service import send_to_uid

# Initialize Firebase Admin.
from firebase_admin import credentials, get_app, initialize_app


logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

POLL_SAFETY_INTERVAL_SECONDS = 15 * 60
NOTIFY_CHANNEL = "hold_created"


# ---------------------------------------------------------------------------
# Worker wake state
# ---------------------------------------------------------------------------

class WakeController:
    """Thread-safe controller for the worker's next wake time."""

    def __init__(self) -> None:
        self.condition = threading.Condition()
        self.next_wake: datetime | None = None

    def set_earlier_wake(self, wake_at: datetime) -> None:
        """Move next_wake earlier and wake the worker if necessary."""
        with self.condition:
            if (
                self.next_wake is None
                or wake_at < self.next_wake
            ):
                self.next_wake = wake_at
                self.condition.notify()

    def set_next_wake(self, wake_at: datetime | None) -> None:
        """Set the worker's next wake time."""
        with self.condition:
            self.next_wake = wake_at
            self.condition.notify()

    def wait(self) -> None:
        """Wait until notified or until next_wake is reached."""
        with self.condition:
            while True:
                if self.next_wake is None:
                    self.condition.wait()
                    continue

                now = datetime.now(timezone.utc)
                timeout = (
                    self.next_wake - now
                ).total_seconds()

                if timeout <= 0:
                    return

                self.condition.wait(timeout=timeout)

                # Either a notification occurred or timeout elapsed.
                # Re-check the condition in case next_wake was changed.
                now = datetime.now(timezone.utc)

                if (
                    self.next_wake is not None
                    and now >= self.next_wake
                ):
                    return


wake_controller = WakeController()


# ---------------------------------------------------------------------------
# Firebase
# ---------------------------------------------------------------------------

cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH")

if not cred_path:
    raise ValueError(
        "FIREBASE_CREDENTIALS_PATH environment variable is not set"
    )

cred = credentials.Certificate(cred_path)

try:
    get_app()
    logger.info("Firebase already initialized")
except ValueError:
    initialize_app(cred)
    logger.info("Firebase initialized successfully")
except Exception:
    logger.exception("Failed to initialize Firebase")
    raise


# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

def get_now() -> datetime:
    """Return the current timezone-aware UTC time."""
    return datetime.now(timezone.utc)


def scan() -> tuple[list[HoldingRequestTable], datetime | None]:
    """Scan the database.

    Returns:
        (
            expired_holds,
            earliest_future_hold_until,
        )

    Expired holds are locked so multiple workers cannot process the same
    records simultaneously.
    """
    db = SessionLocal()

    try:
        now = get_now()

        expired_holds = (
            db.query(HoldingRequestTable)
            .filter(
                HoldingRequestTable.hold_until <= now,
            )
            .order_by(
                HoldingRequestTable.hold_until.asc(),
            )
            .with_for_update(
                skip_locked=True,
            )
            .all()
        )

        next_hold = (
            db.query(HoldingRequestTable.hold_until)
            .filter(
                HoldingRequestTable.hold_until > now,
            )
            .order_by(
                HoldingRequestTable.hold_until.asc(),
            )
            .first()
        )

        next_wake = None
        if next_hold:
            # Ensure the datetime is timezone-aware (UTC)
            dt = next_hold[0]
            if dt.tzinfo is None:
                next_wake = dt.replace(tzinfo=timezone.utc)
            else:
                next_wake = dt

        logger.info(
            "Scan complete: %d expired hold(s), next wake: %s",
            len(expired_holds),
            next_wake,
        )

        return expired_holds, next_wake

    finally:
        db.close()


# ---------------------------------------------------------------------------
# Hold processing
# ---------------------------------------------------------------------------

def process(expired_holds: list[HoldingRequestTable]) -> int:
    """Process expired holds.

    Each hold is processed in its own transaction so one bad record does not
    prevent other expired holds from being handled.
    """
    processed_count = 0

    for holding in expired_holds:
        db = SessionLocal()

        try:
            request_row = Request.get_for_update(
                db,
                {"id": holding.request_id},
            )

            if not request_row:
                logger.warning(
                    "Holding record exists but request not found: %s",
                    holding.request_id,
                )

                HoldingRequest.delete(
                    db,
                    {"id": holding.id},
                )

                db.commit()
                processed_count += 1
                continue

            # The request may have changed state after the hold was created.
            if request_row.status != RequestStatus.HOLD:
                logger.info(
                    "Request %s is no longer HOLD (%s); "
                    "deleting stale hold",
                    holding.request_id,
                    request_row.status.value,
                )

                HoldingRequest.delete(
                    db,
                    {"id": holding.id},
                )

                db.commit()
                processed_count += 1
                continue

            # Get the latest track.
            last_track = (
                db.query(RequestTrackTable)
                .filter(
                    RequestTrackTable.request_id
                    == holding.request_id,
                )
                .order_by(
                    desc(RequestTrackTable.created_at),
                )
                .first()
            )

            if not last_track:
                logger.error(
                    "No track found for held request: %s",
                    holding.request_id,
                )
                db.rollback()
                continue

            if last_track.event_type != TrackEventType.HOLD:
                logger.error(
                    "Latest track for held request %s is %s, "
                    "expected HOLD",
                    holding.request_id,
                    last_track.event_type,
                )
                db.rollback()
                continue

            # Restore request to IN_PROGRESS.
            Request.update(
                db,
                {"id": holding.request_id},
                {"status": RequestStatus.IN_PROGRESS},
            )

            # Attribute expiration to the staff member who started the hold.
            RequestTrack.create(
                db,
                {
                    "request_id": holding.request_id,
                    "event_type": TrackEventType.HOLD_EXPIRED,
                    "performed_by": last_track.performed_by,
                    "performed_by_role": last_track.performed_by_role,
                    "comment": "Hold period expired",
                },
            )

            # Delete processed hold.
            HoldingRequest.delete(
                db,
                {"id": holding.id},
            )

            db.commit()

            # Notify the staff member who placed the hold.
            if last_track.performed_by:
                send_to_uid(
                    last_track.performed_by,
                    "Hold Expired",
                    (
                        f"Your hold on request "
                        f"{holding.request_id[:8]} has expired "
                        "and been restored to IN_PROGRESS"
                    ),
                )

            logger.info(
                "Hold expired: request %s restored to IN_PROGRESS",
                holding.request_id,
            )

            processed_count += 1

        except Exception:
            db.rollback()

            logger.exception(
                "Error processing hold expiration for request %s",
                holding.request_id,
            )

        finally:
            db.close()

    return processed_count


# ---------------------------------------------------------------------------
# PostgreSQL notification listener
# ---------------------------------------------------------------------------

def listen_for_holds() -> None:
    """Listen for new hold notifications from PostgreSQL."""
    connection = None

    try:
        connection = engine.raw_connection()

        # SQLAlchemy exposes this as a generic DBAPI connection,
        # but this application uses psycopg2.
        dbapi_connection: Any = connection.driver_connection

        cursor = dbapi_connection.cursor()
        cursor.execute(f"LISTEN {NOTIFY_CHANNEL}")
        dbapi_connection.commit()
        cursor.close()

        logger.info(
            "Listening for PostgreSQL notifications on '%s'",
            NOTIFY_CHANNEL,
        )

        while True:
            select.select(
                [dbapi_connection],
                [],
                [],
            )

            dbapi_connection.poll()

            while dbapi_connection.notifies:
                notification = dbapi_connection.notifies.pop(0)

                logger.info(
                    "Received hold notification: %s",
                    notification.payload,
                )

                wake_controller.set_earlier_wake(
                    get_now()
                )

    except Exception:
        logger.exception(
            "Hold notification listener stopped"
        )

    finally:
        if connection is not None:
            connection.close()


# ---------------------------------------------------------------------------
# Worker loop
# ---------------------------------------------------------------------------

def run_worker() -> None:
    """Run the hold expiration worker."""

    logger.info(
        "Hold expiration worker started "
        "(safety interval: %ds)",
        POLL_SAFETY_INTERVAL_SECONDS,
    )

    # Start PostgreSQL LISTEN thread.
    listener_thread = threading.Thread(
        target=listen_for_holds,
        name="hold-notification-listener",
        daemon=True,
    )
    listener_thread.start()

    # Initial scan.
    expired_holds, scan_next_wake = scan()

    if expired_holds:
        process(expired_holds)

    now = get_now()
    safety_wake = now + timedelta(
        seconds=POLL_SAFETY_INTERVAL_SECONDS,
    )

    if scan_next_wake is None:
        wake_controller.set_next_wake(safety_wake)
    else:
        wake_controller.set_next_wake(
            min(scan_next_wake, safety_wake)
        )

    while True:
        # Sleep until:
        #   1. next hold expires,
        #   2. PostgreSQL sends a notification, or
        #   3. safety interval expires.
        wake_controller.wait()

        # We have woken up.
        #
        # Clear the old deadline before scanning. Otherwise an old
        # next_wake could incorrectly influence the new one.
        wake_controller.set_next_wake(None)

        try:
            expired_holds, scan_next_wake = scan()

            if expired_holds:
                processed = process(expired_holds)

                logger.info(
                    "Processed %d expired hold(s)",
                    processed,
                )

            # Calculate the next deadline.
            now = get_now()

            safety_wake = now + timedelta(
                seconds=POLL_SAFETY_INTERVAL_SECONDS,
            )

            if scan_next_wake is None:
                next_wake = safety_wake
            else:
                next_wake = min(
                    scan_next_wake,
                    safety_wake,
                )

            wake_controller.set_next_wake(next_wake)

            logger.info(
                "Worker sleeping until %s",
                next_wake,
            )

        except Exception:
            logger.exception("Worker cycle failed")

            # Never allow an unexpected error to create a permanently
            # sleeping worker.
            wake_controller.set_next_wake(
                get_now()
                + timedelta(
                    seconds=POLL_SAFETY_INTERVAL_SECONDS,
                )
            )


if __name__ == "__main__":
    run_worker()