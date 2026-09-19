"""Hold Expiration Worker

Background worker that periodically scans for expired holds and restores requests
to IN_PROGRESS status.

Run this as a separate container/process.
"""
import logging

# Configure logging first, before any imports that might use it
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)

import time
from datetime import datetime, timezone
from models.holding_request import HoldingRequest, HoldingRequestTable
from models.request import Request
from models.track import RequestTrack, RequestTrackTable
from models.enums import RequestStatus, TrackEventType
from dotenv import load_dotenv
from pathlib import Path
# Load environment variables from root .env
load_dotenv(Path(__file__).resolve().parent.parent / ".env")
from config.database import SessionLocal
from sqlalchemy import desc
from services.notification_service import send_to_uid

# Initialize Firebase Admin
import os
from firebase_admin import credentials, initialize_app, get_app

cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH")
if not cred_path:
    raise ValueError("FIREBASE_CREDENTIALS_PATH environment variable is not set")

cred = credentials.Certificate(cred_path)
try:
    get_app()
    logging.info("Firebase already initialized")
except ValueError:
    initialize_app(cred)
    logging.info("Firebase initialized successfully")
except Exception as e:
    logging.error(f"Failed to initialize Firebase: {str(e)}")
    raise

logger = logging.getLogger(__name__)

# Worker configuration
POLL_INTERVAL_SECONDS = 30

def process_expired_holds() -> int:
    """
    Scan for expired holds and restore requests to IN_PROGRESS.
    
    Returns count of holds processed.
    Transactional and idempotent.
    """
    db = SessionLocal()
    processed_count = 0
    
    try:
        # Find all expired holds (with row lock to prevent race conditions)
        expired_holds = (
            db.query(HoldingRequestTable)
            .with_for_update()
            .filter(HoldingRequestTable.hold_until <= datetime.now(timezone.utc))
            .all()
        )
        
        logger.info(
            "Found %d expired hold(s)",
            len(expired_holds),
        )
        
        for holding in expired_holds:
            try:
                # Lock the request row
                request_row = Request.get_for_update(
                    db, {"id": holding.request_id}
                )

                if not request_row:
                    logger.warning(
                        "Holding record exists but request not found: %s",
                        holding.request_id,
                    )
                    HoldingRequest.delete(db, {"id": holding.id})
                    db.commit()
                    processed_count += 1
                    continue

                # If request is no longer on hold, this holding record is stale.
                if request_row.status != RequestStatus.HOLD:
                    logger.info(
                        "Request %s is no longer HOLD (%s), deleting stale hold",
                        holding.request_id,
                        request_row.status.value,
                    )
                    HoldingRequest.delete(db, {"id": holding.id})
                    db.commit()
                    processed_count += 1
                    continue

                # Get the latest track for this request.
                last_track = (
                    db.query(RequestTrackTable)
                    .filter(RequestTrackTable.request_id == holding.request_id)
                    .order_by(desc(RequestTrackTable.created_at))
                    .first()
                )

                if not last_track:
                    logger.error(
                        "No track found for held request: %s",
                        holding.request_id,
                    )
                    continue

                # The latest track should be the track that started the hold.
                if last_track.event_type != TrackEventType.HOLD:
                    logger.error(
                        "Latest track for held request %s is %s, expected HOLD_STARTED",
                        holding.request_id,
                        last_track.event_type,
                    )
                    continue

                # Restore request to IN_PROGRESS.
                Request.update(
                    db,
                    {"id": holding.request_id},
                    {"status": RequestStatus.IN_PROGRESS},
                )

                # Attribute expiration to the staff member who started the hold.
                RequestTrack.create(db, {
                    "request_id": holding.request_id,
                    "event_type": TrackEventType.HOLD_EXPIRED,
                    "performed_by": last_track.performed_by,
                    "performed_by_role": last_track.performed_by_role,
                    "comment": "Hold period expired",
                })

                # Delete processed holding record.
                HoldingRequest.delete(db, {"id": holding.id})

                db.commit()

                # Send notification to the staff member whose hold expired
                if last_track.performed_by:
                    send_to_uid(
                        last_track.performed_by,
                        "Hold Expired",
                        f"Your hold on request {holding.request_id[:8]} has expired and been restored to IN_PROGRESS",
                    )

                logger.info(
                    "Hold expired: request %s restored to IN_PROGRESS",
                    holding.request_id,
                )
                processed_count += 1

            except Exception as e:
                db.rollback()
                logger.exception(
                    "Error processing hold expiration for request %s: %s",
                    holding.request_id,
                    e,
                )
                continue
                
        return processed_count
        
    finally:
        db.close()


def run_worker() -> None:
    """Main worker loop — continuously scans and processes expired holds."""
    logger.info(
        "Hold expiration worker started (poll interval: %ds)",
        POLL_INTERVAL_SECONDS,
    )
    
    while True:
        try:
            processed = process_expired_holds()
            if processed > 0:
                logger.info("Processed %d expired hold(s)", processed)
        except Exception as e:
            logger.exception("Worker error: %s", e)

        time.sleep(POLL_INTERVAL_SECONDS)


if __name__ == "__main__":
    run_worker()
