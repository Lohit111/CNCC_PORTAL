"""Notification Service

Sends FCM push notifications to individual users or to all users
belonging to a given role. Relies on firebase-admin (already initialised
in main.py via initialize_app).
"""
import logging
from typing import List, Optional, Tuple

from firebase_admin import messaging
from sqlalchemy.orm import Session

from models.enums import UserRole, DevicePlatform
from models.user import UserTable
from models.user_fcm import UserFcm

logger = logging.getLogger(__name__)

# FCM allows up to 500 messages per send_each call
_FCM_BATCH_SIZE = 500


def _build_message(
    token: str,
    platform: DevicePlatform,
    title: str,
    body: str,
    data: Optional[dict],
) -> messaging.Message:
    """Build a platform-specific FCM Message."""
    notification = messaging.Notification(title=title, body=body)
    base = dict(token=token, notification=notification, data=data or {})

    if platform == DevicePlatform.ANDROID:
        return messaging.Message(
            **base,
            android=messaging.AndroidConfig(
                notification=messaging.AndroidNotification(
                    channel_id="cncc_high_importance",
                ),
            ),
        )

    if platform == DevicePlatform.IOS:
        return messaging.Message(
            **base,
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound="default",
                        badge=1,
                    ),
                ),
            ),
        )

    # DevicePlatform.UNKNOWN — send bare message, let FCM use defaults
    return messaging.Message(**base)


def _send_multicast(
    token_platforms: List[Tuple[str, DevicePlatform]],
    title: str,
    body: str,
    data: Optional[dict] = None,
) -> None:
    """Build per-platform messages and send them in batches of 500."""
    if not token_platforms:
        logger.info("_send_multicast: no tokens provided, skipping")
        return

    messages = [
        _build_message(token, platform, title, body, data)
        for token, platform in token_platforms
    ]

    for i in range(0, len(messages), _FCM_BATCH_SIZE):
        batch = messages[i: i + _FCM_BATCH_SIZE]
        response = messaging.send_each(batch)
        logger.info(
            "FCM batch %d-%d: %d success, %d failure",
            i,
            i + len(batch) - 1,
            response.success_count,
            response.failure_count,
        )

        for idx, resp in enumerate(response.responses):
            if not resp.success:
                logger.warning(
                    "FCM delivery failed for token index %d: %s",
                    i + idx,
                    resp.exception,
                )


def send_to_user(
    db: Session,
    user_id: str,
    title: str,
    body: str,
    data: Optional[dict] = None,
) -> None:
    """Send a push notification to all devices registered for a single user.

    Args:
        db:      SQLAlchemy session.
        user_id: The target user's ID.
        title:   Notification title.
        body:    Notification body text.
        data:    Optional key-value payload attached to the notification.
    """
    token_platforms = UserFcm.get_tokens_for_user(db, user_id=user_id)
    if not token_platforms:
        logger.info("send_to_user: no FCM tokens for user %s", user_id)
        return
    logger.info(
        "Sending notification to user %s (%d token(s))",
        user_id,
        len(token_platforms),
    )
    _send_multicast(token_platforms, title=title, body=body, data=data)


def send_to_role(
    db: Session,
    role: UserRole,
    title: str,
    body: str,
    data: Optional[dict] = None,
) -> None:
    """Send a push notification to every active user with the given role.

    Args:
        db:    SQLAlchemy session.
        role:  Target UserRole (e.g. UserRole.ADMIN, UserRole.STAFF).
        title: Notification title.
        body:  Notification body text.
        data:  Optional key-value payload attached to the notification.
    """
    user_ids: List[str] = [
        str(row.id)
        for row in db.query(UserTable.id)
        .filter(UserTable.role == role, UserTable.is_active == True)
        .all()
    ]

    if not user_ids:
        logger.info("send_to_role: no active users with role %s", role.value)
        return

    token_platforms = UserFcm.get_tokens_for_users(db, user_ids=user_ids)
    if not token_platforms:
        logger.info(
            "send_to_role: no FCM tokens registered for role %s", role.value
        )
        return

    logger.info(
        "Sending notification to role %s (%d user(s), %d token(s))",
        role.value,
        len(user_ids),
        len(token_platforms),
    )
    _send_multicast(token_platforms, title=title, body=body, data=data)
