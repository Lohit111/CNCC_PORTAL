"""Rooms API Endpoints"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from models.user import User
from models.enums import UserRole
from middleware.auth import get_current_user, require_role
from controllers.rooms import get_rooms, create_room, update_room, delete_room
from config.database import get_db

router = APIRouter(prefix="/rooms", tags=["Rooms"])


# --- Request Schemas ---

class RoomRequest(BaseModel):
    room_no: str


# --- Endpoints ---

@router.get("/")
async def list_rooms(
    user: User = Depends(require_role(
        UserRole.ADMIN, UserRole.STAFF, UserRole.STORE)),
    db: Session = Depends(get_db)
):
    """Get all rooms — accessible by all authenticated users"""
    return get_rooms(db)


@router.post("/")
async def create(
    body: RoomRequest,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Create a new room — admin only"""
    return create_room(db, room_no=body.room_no)


@router.put("/{room_id}")
async def update(
    room_id: int,
    body: RoomRequest,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Update a room's number — admin only"""
    return update_room(db, room_id=room_id, room_no=body.room_no)


@router.delete("/{room_id}")
async def delete(
    room_id: int,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Delete a room — admin only"""
    delete_room(db, room_id=room_id)
    return {"message": "Room deleted successfully"}
