"""Notification Service

Public API (all accept db, title, body only):
    send_to_uid(db, user_id, title, body)
    send_to_uids(db, user_ids, title, body)
    send_to_role(db, role, title, body)
    broadcast(db, title, body)

Each function resolves devices via a single JOIN query, then calls
_build_notifications → _send_notifications.

Set DEBUG=true in .env to skip FCM sends (logs instead).
"""
import os
import logging
from typing import List, Tuple

from firebase_admin import messaging
from sqlalchemy.orm import Session

from models.enums import UserRole, DevicePlatform
from models.user import UserTable
from models.user_fcm import UserFcmTable, UserFcm
from config.database import SessionLocal

logger = logging.getLogger(__name__)

_DEBUG = os.getenv("DEBUG", "false").lower() == "true"
_BATCH_SIZE = 500


# ---------------------------------------------------------------------------
# Step 2 — build platform-specific messages from a device list
# ---------------------------------------------------------------------------

def _build_notifications(
    devices: List[Tuple[str, DevicePlatform]],
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> List[messaging.Message]:
    messages = []
    notification = messaging.Notification(title=title, body=body)

    for token, platform in devices:
        if platform == DevicePlatform.ANDROID:
            msg = messaging.Message(
                token=token,
                notification=notification,
                data=data or {},
                android=messaging.AndroidConfig(
                    notification=messaging.AndroidNotification(
                        channel_id="cncc_high_importance",
                    ),
                ),
            )
        elif platform == DevicePlatform.IOS:
            msg = messaging.Message(
                token=token,
                notification=notification,
                data=data or {},
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(sound="default", badge=1),
                    ),
                ),
            )
        else:
            msg = messaging.Message(
                token=token,
                notification=notification,
                data=data or {}
            )

        messages.append(msg)

    return messages


# ---------------------------------------------------------------------------
# Step 3 — batch send, purge invalid tokens
# ---------------------------------------------------------------------------

def _send_notifications(
    db: Session,
    messages: List[messaging.Message],
) -> None:
    """Send messages in batches of 500 and purge invalid tokens."""

    if not messages:
        logger.info("No notification messages to send")
        return

    total_messages = len(messages)
    total_batches = (
        (total_messages + _BATCH_SIZE - 1) // _BATCH_SIZE
    )

    logger.info(
        "Starting FCM send: messages=%d, batch_size=%d, batches=%d",
        total_messages,
        _BATCH_SIZE,
        total_batches,
    )

    for batch_number, i in enumerate(
        range(0, total_messages, _BATCH_SIZE),
        start=1,
    ):
        batch = messages[i:i + _BATCH_SIZE]

        logger.info(
            "Sending FCM batch %d/%d: messages=%d, indexes=%d-%d",
            batch_number,
            total_batches,
            len(batch),
            i,
            i + len(batch) - 1,
        )

        try:
            response = messaging.send_each(batch)

            logger.info(
                "FCM batch %d/%d completed: success=%d, failure=%d",
                batch_number,
                total_batches,
                response.success_count,
                response.failure_count,
            )

        except Exception:
            logger.exception(
                "FCM batch %d/%d failed completely",
                batch_number,
                total_batches,
            )
            continue

        invalid_tokens: List[str] = []

        for idx, resp in enumerate(response.responses):
            if resp.success:
                logger.debug(
                    "FCM message succeeded: global_index=%d",
                    i + idx,
                )
                continue

            exc = resp.exception

            if isinstance(exc, messaging.UnregisteredError):
                token = batch[idx].token

                logger.warning(
                    "FCM token is unregistered: global_index=%d",
                    i + idx,
                )

                if token:
                    invalid_tokens.append(token)

            else:
                logger.warning(
                    "FCM delivery failed: global_index=%d, error=%s",
                    i + idx,
                    exc,
                )

        # -------------------------------------------------------------------
        # Remove invalid tokens
        # -------------------------------------------------------------------

        if invalid_tokens:
            logger.info(
                "Purging %d invalid FCM token(s)",
                len(invalid_tokens),
            )

            try:
                deleted = UserFcm.delete_tokens(
                    db,
                    fcm_tokens=invalid_tokens,
                )

                db.commit()

                logger.info(
                    "Successfully purged %d invalid FCM token(s)",
                    deleted,
                )

            except Exception:
                db.rollback()

                logger.exception(
                    "Failed to purge invalid FCM token(s)",
                )

        else:
            logger.debug(
                "No invalid tokens found in batch %d/%d",
                batch_number,
                total_batches,
            )

    logger.info(
        "FCM send process completed: total_messages=%d",
        total_messages,
    )


# ---------------------------------------------------------------------------
# Public API — each does its own JOIN to resolve devices
# ---------------------------------------------------------------------------
def send_to_uid(user_id: str, title: str, body: str, data: dict[str, str] | None = None) -> None:
    """Send to all devices of a single user."""
    try:
        db = SessionLocal()
        devices: List[Tuple[str, DevicePlatform]] = (
            db.query(UserFcmTable.fcm_token, UserFcmTable.platform)
            .filter(UserFcmTable.user_id == user_id)
            .all()
        ) # pyright: ignore[reportAssignmentType]
        if _DEBUG:
            logger.info("DEBUG — skipping send_to_uid(%s): '%s'", user_id, title)
            return
        _send_notifications(db, _build_notifications(devices, title, body, data))
    except Exception:
        logger.exception(
            "Notification failed for user %s",
            user_id,
        )


def send_to_uids(user_ids: List[str], title: str, body: str, data: dict[str, str] | None = None) -> None:
    """Send to all devices of a set of users."""
    try:
        db = SessionLocal()
        if not user_ids:
            return
        devices: List[Tuple[str, DevicePlatform]] = (
            db.query(UserFcmTable.fcm_token, UserFcmTable.platform)
            .filter(UserFcmTable.user_id.in_(user_ids))
            .all()
        ) # pyright: ignore[reportAssignmentType]
        if _DEBUG:
            logger.info("DEBUG — skipping send_to_uids(%d users): '%s'", len(user_ids), title)
            return
        _send_notifications(db, _build_notifications(devices, title, body, data))
    except Exception:
        logger.exception(
            "Notification failed for users %s",
            user_ids,
        )


def send_to_role(role: UserRole, title: str, body: str, data: dict[str, str] | None = None) -> None:
    """Send to all devices of every active user with the given role."""
    try:
        db = SessionLocal()
        devices = (
            db.query(UserFcmTable.fcm_token, UserFcmTable.platform)
            .join(UserTable, UserTable.id == UserFcmTable.user_id)
            .filter(
                UserTable.role == role,
                UserTable.is_active == True,
            )
            .all()
        ) # pyright: ignore[reportAssignmentType]
        if _DEBUG:
            logger.info("DEBUG — skipping send_to_role(%s): '%s'", role.value, title)
            return
        print("sending to role", devices)
        _send_notifications(db, _build_notifications(devices, title, body, data))
    except Exception:
        logger.exception(
            "Notification failed for users with role %s",
            role.value,
        )

def broadcast(title: str, body: str, data: dict[str, str] | None = None) -> None:
    """Send to all devices of every active user."""
    try:
        db = SessionLocal()
        devices: List[Tuple[str, DevicePlatform]] = (
            db.query(UserFcmTable.fcm_token, UserFcmTable.platform)
            .join(UserTable, UserTable.id == UserFcmTable.user_id)
            .filter(UserTable.is_active == True)  # noqa: E712
            .all()
        ) # pyright: ignore[reportAssignmentType]
        if _DEBUG:
            logger.info("DEBUG — skipping broadcast: '%s'", title)
            return
        _send_notifications(db, _build_notifications(devices, title, body, data))
    except Exception:
        logger.exception(
            "Notification failed to broadcast to all users",
        )
