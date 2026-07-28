"""Admin API Endpoints"""
from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from models.user import User
from models.enums import UserRole
from middleware.auth import require_role, get_current_user
from controllers.admin_requests import (
    get_raised, get_replied, get_assigned,
    get_reassign_requested, get_inprogress, get_archive,
    reply_to_request, assign_request, reject_request,
    delete_request, delete_store_request
)
from config.database import get_db

# ADMIN only — applied at router level
router = APIRouter(
    prefix="/admin",
    tags=["Admin"],
    dependencies=[Depends(require_role(UserRole.ADMIN))]
)


# --- Request Schemas ---

class CommentBody(BaseModel):
    comment: str


class AssignBody(BaseModel):
    staff_ids: List[str]


# --- GET Endpoints ---

@router.get("/raised")
async def list_raised(page: int = 1, db: Session = Depends(get_db)):
    """All requests in RAISED status (paginated, 30 per page)"""
    return get_raised(db, page=page)


@router.get("/replied")
async def list_replied(page: int = 1, db: Session = Depends(get_db)):
    """All requests in REPLIED status (paginated, 30 per page)"""
    return get_replied(db, page=page)


@router.get("/assigned")
async def list_assigned(page: int = 1, db: Session = Depends(get_db)):
    """All requests in ASSIGNED status (paginated, 30 per page)"""
    return get_assigned(db, page=page)


@router.get("/reassign-requested")
async def list_reassign_requested(page: int = 1, db: Session = Depends(get_db)):
    """All requests in REASSIGN_REQUESTED status (paginated, 30 per page)"""
    return get_reassign_requested(db, page=page)


@router.get("/inprogress")
async def list_inprogress(page: int = 1, db: Session = Depends(get_db)):
    """All requests in IN_PROGRESS status (paginated, 30 per page)"""
    return get_inprogress(db, page=page)


@router.get("/archive")
async def list_archive(page: int = 1, db: Session = Depends(get_db)):
    """All requests in COMPLETED or REJECTED status (paginated, 30 per page)"""
    return get_archive(db, page=page)


# --- PUT Action Endpoints ---

@router.put("/reply/{request_id}")
async def reply(
    request_id: str,
    body: CommentBody,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Set request status to REPLIED and create a track entry with a comment"""
    reply_to_request(db, admin=user, request_id=request_id,
                     comment=body.comment)
    return {"message": "Request marked as replied"}


@router.put("/assign/{request_id}")
async def assign(
    request_id: str,
    body: AssignBody,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Assign a request to one or more staff members"""
    assign_request(db, admin=user, request_id=request_id,
                   staff_ids=body.staff_ids)
    return {"message": "Request assigned successfully"}


@router.put("/reject/{request_id}")
async def reject(
    request_id: str,
    body: CommentBody,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Set request status to REJECTED and create a track entry with a comment"""
    reject_request(db, admin=user, request_id=request_id, comment=body.comment)
    return {"message": "Request rejected"}


# --- DELETE Endpoints ---

@router.delete("/request/{request_id}")
async def remove_request(
    request_id: str,
    db: Session = Depends(get_db)
):
    """Delete a request and all its related data (tracks, assignments, store_requests, chats)"""
    delete_request(db, request_id=request_id)
    return {"message": "Request deleted successfully"}


@router.delete("/store-request/{store_request_id}")
async def remove_store_request(
    store_request_id: str,
    db: Session = Depends(get_db)
):
    """Delete a store request and its chat messages"""
    delete_store_request(db, store_request_id=store_request_id)
    return {"message": "Store request deleted successfully"}
