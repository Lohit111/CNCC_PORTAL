"""Track Model"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, Text, Enum as SAEnum
from sqlalchemy.orm import relationship, Session
from models.base import Base
from models.enums import TrackEventType, UserRole


class RequestTrackTable(Base):
    """SQLAlchemy RequestTrack table"""
    __tablename__ = "request_tracks"

    id = Column(Integer, primary_key=True, index=True)
    request_id = Column(String, ForeignKey("requests.id"),
                        nullable=False, index=True)
    store_request_id = Column(String, ForeignKey("store_requests.id"),
                              nullable=True, index=True)
    event_type = Column(SAEnum(TrackEventType), nullable=False, index=True)
    performed_by = Column(String, ForeignKey("users.id"), nullable=False)
    performed_by_role = Column(SAEnum(UserRole), nullable=False)
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow,
                        nullable=False, index=True)

    request = relationship("RequestTable", back_populates="tracks")
    store_request = relationship("StoreRequestTable", back_populates="tracks")
    performer = relationship("UserTable", back_populates="tracks")
    assignments = relationship("AssignmentTable", back_populates="track")


class RequestTrack(BaseModel):
    id: Optional[int] = Field(default=None)
    request_id: str = Field()
    store_request_id: Optional[str] = Field(default=None)
    event_type: TrackEventType = Field()
    performed_by: str = Field()
    performed_by_role: UserRole = Field()
    comment: Optional[str] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(track_table: RequestTrackTable) -> "RequestTrack":
        """Convert SQLAlchemy model to Pydantic model"""
        return RequestTrack(
            id=int(track_table.id) if track_table.id else None,
            request_id=str(track_table.request_id),
            store_request_id=str(
                track_table.store_request_id) if track_table.store_request_id else None,
            event_type=track_table.event_type,
            performed_by=str(track_table.performed_by),
            performed_by_role=track_table.performed_by_role,
            comment=str(track_table.comment) if track_table.comment else None,
            created_at=track_table.created_at
        )

    @staticmethod
    def create(db: Session, data: dict) -> "RequestTrack":
        """Stage a new track (caller must commit)"""
        track_table = RequestTrackTable(**data)
        db.add(track_table)
        db.flush()
        return RequestTrack.from_orm(track_table)

    @staticmethod
    def get(db: Session, filter: dict) -> Optional["RequestTrack"]:
        """Get a single track by filter"""
        query = db.query(RequestTrackTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTrackTable, key) == value)
        track_table = query.first()
        return RequestTrack.from_orm(track_table) if track_table else None

    @staticmethod
    def get_raw(db: Session, filter: dict) -> Optional[RequestTrackTable]:
        """Get raw SQLAlchemy object"""
        query = db.query(RequestTrackTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTrackTable, key) == value)
        return query.first()

    @staticmethod
    def find(db: Session, filter: Optional[dict] = None, skip: int = 0, limit: Optional[int] = None, order_by: str = "created_at") -> List["RequestTrack"]:
        """Find multiple tracks ordered by created_at"""
        query = db.query(RequestTrackTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(RequestTrackTable, key) == value)
        query = query.order_by(getattr(RequestTrackTable, order_by).asc())
        query = query.offset(skip)
        if limit:
            query = query.limit(limit)
        return [RequestTrack.from_orm(t) for t in query.all()]

    @staticmethod
    def update(db: Session, filter: dict, data: dict) -> bool:
        """Stage an update (caller must commit)"""
        query = db.query(RequestTrackTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTrackTable, key) == value)
        return query.update(data) > 0

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Stage a delete (caller must commit)"""
        query = db.query(RequestTrackTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTrackTable, key) == value)
        return query.delete() > 0

    @staticmethod
    def delete_all(db: Session, filter: dict) -> int:
        """Stage bulk delete (caller must commit)"""
        query = db.query(RequestTrackTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTrackTable, key) == value)
        return query.delete()

    @staticmethod
    def count(db: Session, filter: Optional[dict] = None) -> int:
        """Count tracks"""
        query = db.query(RequestTrackTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(RequestTrackTable, key) == value)
        return query.count()
