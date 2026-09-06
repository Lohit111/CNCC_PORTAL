"""Notification API Endpoints"""

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from models.user import User
from models.enums import UserRole
from middleware.auth import require_role
from services.notification_service import (
    broadcast,
    send_to_role,
    send_to_uid,
)


router = APIRouter(prefix="/notifications", tags=["Notifications"])


# --- Request Schemas ---

class NotificationRequest(BaseModel):
    title: str
    body: str
    data: dict[str, str] | None = None


class RoleNotificationRequest(BaseModel):
    role: UserRole
    title: str
    body: str
    data: dict[str, str] | None = None


# --- Endpoints ---

@router.post("/broadcast")
async def notify_broadcast(
    body: NotificationRequest,
    user: User = Depends(require_role(UserRole.ADMIN)),
):
    """Send a notification to all active users."""
    broadcast(body.title, body.body, body.data)
    return {"message": "Broadcast notification sent successfully"}


@router.post("/role")
async def notify_role(
    body: RoleNotificationRequest,
    user: User = Depends(require_role(UserRole.ADMIN)),
):
    """Send a notification to all active users with the specified role."""
    send_to_role(
        body.role,
        body.title,
        body.body,
        body.data,
    )
    return {"message": "Role notification sent successfully"}


@router.post("/{user_id}")
async def notify_user(
    user_id: str,
    body: NotificationRequest,
    user: User = Depends(require_role(UserRole.ADMIN)),
):
    """Send a notification to all devices registered to a user."""
    send_to_uid(
        user_id,
        body.title,
        body.body,
        body.data,
    )
    return {"message": "User notification sent successfully"}