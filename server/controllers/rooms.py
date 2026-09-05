"""Room Controller"""
from fastapi import HTTPException
from sqlalchemy.orm import Session
from models.room import Room


def get_rooms(db: Session):
    """Return all rooms ordered by room_no"""
    return Room.find(db)


def create_room(db: Session, room_no: str) -> Room:
    """Create a new room, enforcing uniqueness"""
    if Room.get(db, {"room_no": room_no.strip()}):
        raise HTTPException(
            status_code=409, detail=f"Room '{room_no}' already exists")
    room = Room.create(db, room_no=room_no.strip())
    db.commit()
    return room


def update_room(db: Session, room_id: int, room_no: str) -> Room:
    """Update a room's number, enforcing uniqueness"""
    existing = Room.get(db, {"id": room_id})
    if not existing:
        raise HTTPException(status_code=404, detail="Room not found")

    conflict = Room.get(db, {"room_no": room_no.strip()})
    if conflict and conflict.id != room_id:
        raise HTTPException(
            status_code=409, detail=f"Room '{room_no}' already exists")

    Room.update(db, room_id=room_id, room_no=room_no.strip())
    db.commit()
    return Room.get(db, {"id": room_id})  # pyright: ignore[reportReturnType]


def delete_room(db: Session, room_id: int) -> None:
    """Delete a room by ID"""
    if not Room.get(db, {"id": room_id}):
        raise HTTPException(status_code=404, detail="Room not found")
    Room.delete(db, room_id=room_id)
    db.commit()
