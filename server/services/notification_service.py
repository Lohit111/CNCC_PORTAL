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
from models.user_fcm import UserFcmTable

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
) -> List[messaging.Message]:
    messages = []
    notification = messaging.Notification(title=title, body=body)

    for token, platform in devices:
        if platform == DevicePlatform.ANDROID:
            msg = messaging.Message(
                token=token,
                notification=notification,
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
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(sound="default", badge=1),
                    ),
                ),
            )
        else:
            msg = messaging.Message(token=token, notification=notification)

        messages.append(msg)

    return messages


# ---------------------------------------------------------------------------
# Step 3 — batch send, no app logic
# ---------------------------------------------------------------------------

def _send_notifications(messages: List[messaging.Message]) -> None:
    if not messages:
        return

    for i in range(0, len(messages), _BATCH_SIZE):
        batch = messages[i: i + _BATCH_SIZE]
        response = messaging.send_each(batch)
        logger.info(
            "FCM batch %d-%d: %d success, %d failure",
            i, i + len(batch) - 1,
            response.success_count, response.failure_count,
        )
        for idx, resp in enumerate(response.responses):
            if not resp.success:
                logger.warning(
                    "FCM delivery failed for token index %d: %s",
                    i + idx, resp.exception,
                )


# ---------------------------------------------------------------------------
# Public API — each does its own JOIN to resolve devices
# ---------------------------------------------------------------------------

def send_to_uid(db: Session, user_id: str, title: str, body: str) -> None:
    """Send to all devices of a single user."""
    devices: List[Tuple[str, DevicePlatform]] = (
        db.query(UserFcmTable.fcm_token, UserFcmTable.platform)
        .filter(UserFcmTable.user_id == user_id)
        .all()
    )
    if _DEBUG:
        logger.info("DEBUG — skipping send_to_uid(%s): '%s'", user_id, title)
        return
    _send_notifications(_build_notifications(devices, title, body))


def send_to_uids(db: Session, user_ids: List[str], title: str, body: str) -> None:
    """Send to all devices of a set of users."""
    if not user_ids:
        return
    devices: List[Tuple[str, DevicePlatform]] = (
        db.query(UserFcmTable.fcm_token, UserFcmTable.platform)
        .filter(UserFcmTable.user_id.in_(user_ids))
        .all()
    )
    if _DEBUG:
        logger.info("DEBUG — skipping send_to_uids(%d users): '%s'", len(user_ids), title)
        return
    _send_notifications(_build_notifications(devices, title, body))


def send_to_role(db: Session, role: UserRole, title: str, body: str) -> None:
    """Send to all devices of every active user with the given role."""
    devices: List[Tuple[str, DevicePlatform]] = (
        db.query(UserFcmTable.fcm_token, UserFcmTable.platform)
        .join(UserTable, UserTable.id == UserFcmTable.user_id)
        .filter(UserTable.role == role, UserTable.is_active == True)  # noqa: E712
        .all()
    )
    if _DEBUG:
        logger.info("DEBUG — skipping send_to_role(%s): '%s'", role.value, title)
        return
    _send_notifications(_build_notifications(devices, title, body))


def broadcast(db: Session, title: str, body: str) -> None:
    """Send to all devices of every active user."""
    devices: List[Tuple[str, DevicePlatform]] = (
        db.query(UserFcmTable.fcm_token, UserFcmTable.platform)
        .join(UserTable, UserTable.id == UserFcmTable.user_id)
        .filter(UserTable.is_active == True)  # noqa: E712
        .all()
    )
    if _DEBUG:
        logger.info("DEBUG — skipping broadcast: '%s'", title)
        return
    _send_notifications(_build_notifications(devices, title, body))
