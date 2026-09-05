"""Room Model"""
from pydantic import BaseModel, Field
from typing import Optional, List
from sqlalchemy import Column, String, Integer
from sqlalchemy.orm import Session
from models.base import Base


class RoomTable(Base):
    """SQLAlchemy Room table"""
    __tablename__ = "rooms"

    id = Column(Integer, primary_key=True, index=True)
    room_no = Column(String, nullable=False, unique=True, index=True)


class Room(BaseModel):
    id: Optional[int] = Field(default=None)
    room_no: str = Field()

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(row: RoomTable) -> "Room":
        return Room(id=int(row.id) if row.id else None, room_no=str(row.room_no))

    @staticmethod
    def create(db: Session, room_no: str) -> "Room":
        """Stage a new room (caller must commit)"""
        row = RoomTable(room_no=room_no)
        db.add(row)
        db.flush()
        return Room.from_orm(row)

    @staticmethod
    def get(db: Session, filter: dict) -> Optional["Room"]:
        query = db.query(RoomTable)
        for key, value in filter.items():
            query = query.filter(getattr(RoomTable, key) == value)
        row = query.first()
        return Room.from_orm(row) if row else None

    @staticmethod
    def find(db: Session) -> List["Room"]:
        rows = db.query(RoomTable).order_by(RoomTable.room_no).all()
        return [Room.from_orm(r) for r in rows]

    @staticmethod
    def update(db: Session, room_id: int, room_no: str) -> bool:
        """Stage an update (caller must commit)"""
        return db.query(RoomTable).filter(RoomTable.id == room_id).update({"room_no": room_no}) > 0

    @staticmethod
    def delete(db: Session, room_id: int) -> bool:
        """Stage a delete (caller must commit)"""
        return db.query(RoomTable).filter(RoomTable.id == room_id).delete() > 0
