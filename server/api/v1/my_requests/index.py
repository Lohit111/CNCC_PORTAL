"""My Requests API Endpoints"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from models.user import User
from models.enums import UserRole
from middleware.auth import require_role, get_current_user
from controllers.my_requests import get_raised, get_replied, get_inprogress, get_archive, reply_to_request, create_request
from config.database import get_db

# Role restriction applied at router level — all routes inherit it
router = APIRouter(
    prefix="/my-requests",
    tags=["My Requests"],
    dependencies=[Depends(require_role(
        UserRole.USER, UserRole.ADMIN, UserRole.STAFF))]
)


# --- Request Schemas ---

class ReplyRequest(BaseModel):
    comment: str
    description: str


class CreateRequestBody(BaseModel):
    main_type: str
    sub_type: str
    description: str
    room_no: str


# --- Endpoints ---

@router.post("/")
async def create(
    body: CreateRequestBody,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Raise a new request"""
    return create_request(
        db,
        user_id=user.id,
        main_type=body.main_type,
        sub_type=body.sub_type,
        description=body.description,
        room_no=body.room_no,
    )


@router.get("/raised")
async def list_raised(
    page: int = 1,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get my requests in RAISED status (paginated, 30 per page)"""
    return get_raised(db, user_id=user.id, page=page)


@router.get("/replied")
async def list_replied(
    page: int = 1,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get my requests where admin has replied (paginated, 30 per page)"""
    return get_replied(db, user_id=user.id, page=page)


@router.get("/inprogress")
async def list_inprogress(
    page: int = 1,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get my requests in ASSIGNED, IN_PROGRESS, or REASSIGN_REQUESTED status (paginated, 30 per page)"""
    return get_inprogress(db, user_id=user.id, page=page)


@router.get("/archive")
async def list_archive(
    page: int = 1,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get my requests in COMPLETED or REJECTED status (paginated, 30 per page)"""
    return get_archive(db, user_id=user.id, page=page)


@router.put("/reply/{request_id}")
async def reply(
    request_id: str,
    body: ReplyRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Reply to admin on a request that has a pending admin reply"""
    reply_to_request(db, user_id=user.id, request_id=request_id,
                     comment=body.comment, description=body.description)
    return {"message": "Reply submitted successfully"}
