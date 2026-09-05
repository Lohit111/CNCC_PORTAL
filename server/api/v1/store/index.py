"""Store API Endpoints"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from models.user import User
from models.enums import UserRole
from middleware.auth import require_role, get_current_user
from controllers.store_actions import (
    approve_store_request, reject_store_request,
    fulfil_store_request, send_chat_message,
    get_pending, get_approved, get_archive
)
from config.database import get_db

# STORE only — applied at router level
router = APIRouter(
    prefix="/store",
    tags=["Store"],
    dependencies=[Depends(require_role(UserRole.STORE))]
)


# --- Request Schemas ---

class CommentBody(BaseModel):
    comment: str


class MessageBody(BaseModel):
    message: str


# --- GET Endpoints ---

@router.get("/pending")
async def list_pending(
    page: int = 1,
    db: Session = Depends(get_db)
):
    """All store requests with PENDING status (paginated, 30 per page)"""
    return get_pending(db, page=page)


@router.get("/approved")
async def list_approved(
    page: int = 1,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Store requests approved by this store user (paginated, 30 per page)"""
    return get_approved(db, store_user_id=user.id, page=page)


@router.get("/archive")
async def list_archive(
    page: int = 1,
    db: Session = Depends(get_db)
):
    """All store requests with REJECTED or FULFILLED status (paginated, 30 per page)"""
    return get_archive(db, page=page)


# --- PUT Action Endpoints ---

@router.put("/approve/{store_request_id}")
async def approve(
    store_request_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Approve a store request"""
    approve_store_request(db, store_user=user,
                          store_request_id=store_request_id)
    return {"message": "Store request approved"}


@router.put("/reject/{store_request_id}")
async def reject(
    store_request_id: str,
    body: CommentBody,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Reject a store request with a comment"""
    reject_store_request(
        db, store_user=user, store_request_id=store_request_id, comment=body.comment)
    return {"message": "Store request rejected"}


@router.put("/fulfil/{store_request_id}")
async def fulfil(
    store_request_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark a store request as fulfilled"""
    fulfil_store_request(db, store_user=user,
                         store_request_id=store_request_id)
    return {"message": "Store request fulfilled"}


# --- POST Endpoints ---

@router.post("/chat/{store_request_id}")
async def chat(
    store_request_id: str,
    body: MessageBody,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a chat message on a store request"""
    send_chat_message(db, store_user=user,
                      store_request_id=store_request_id, message=body.message)
    return {"message": "Message sent"}
