"""Staff API Endpoints"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from models.user import User
from models.enums import UserRole
from middleware.auth import require_role, get_current_user
from controllers.staff_actions import (
    get_assigned, get_inprogress, get_archive,
    start_request, request_reassignment, finish_request,
    create_store_request, get_store_chat, send_staff_chat_message
)
from config.database import get_db

# STAFF only — applied at router level
router = APIRouter(
    prefix="/staff",
    tags=["Staff"],
    dependencies=[Depends(require_role(UserRole.STAFF))]
)


# --- Request Schemas ---

class CommentBody(BaseModel):
    comment: str


class StoreRequestBody(BaseModel):
    description: str


class MessageBody(BaseModel):
    message: str


# --- GET Endpoints ---

@router.get("/assigned")
async def list_assigned(
    page: int = 1,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """All requests currently assigned to this staff member (paginated, 30 per page)"""
    return get_assigned(db, staff_id=user.id, page=page)


@router.get("/inprogress")
async def list_inprogress(
    page: int = 1,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """All in-progress requests taken by this staff member (paginated, 30 per page)"""
    return get_inprogress(db, staff_id=user.id, page=page)


@router.get("/archive")
async def list_archive(
    page: int = 1,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """All completed/rejected requests this staff member was the final assignee on"""
    return get_archive(db, staff_id=user.id, page=page)


@router.get("/chat/{store_request_id}")
async def list_chat(
    store_request_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all chat messages for a store request"""
    messages = get_store_chat(db, staff_id=user.id,
                              store_request_id=store_request_id)
    return [m.model_dump() for m in messages]


@router.post("/chat/{store_request_id}")
async def post_chat(
    store_request_id: str,
    body: MessageBody,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a chat message on a store request (staff must own the store request)"""
    send_staff_chat_message(db, staff=user,
                            store_request_id=store_request_id, message=body.message)
    return {"message": "Message sent"}


# --- PUT Action Endpoints ---

@router.put("/start-request/{request_id}")
async def start(
    request_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Set request status to IN_PROGRESS and create a track entry"""
    start_request(db, staff=user, request_id=request_id)
    return {"message": "Request started"}


@router.put("/request-reassignment/{request_id}")
async def reassign(
    request_id: str,
    body: CommentBody,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Request reassignment — sets status to REASSIGN_REQUESTED and deactivates assignments"""
    request_reassignment(
        db, staff=user, request_id=request_id, comment=body.comment)
    return {"message": "Reassignment requested"}


@router.put("/finish-request/{request_id}")
async def finish(
    request_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Complete a request — sets status to COMPLETED and deactivates all assignments"""
    finish_request(db, staff=user, request_id=request_id)
    return {"message": "Request completed"}


@router.put("/create-store-request/{request_id}")
async def create_store(
    request_id: str,
    body: StoreRequestBody,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a store request under a parent request with PENDING status"""
    create_store_request(db, staff=user, request_id=request_id,
                         description=body.description)
    return {"message": "Store request created"}
