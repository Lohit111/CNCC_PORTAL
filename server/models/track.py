"""Track Model - Replaces Comment Model for Request Timeline"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, Text, JSON
from sqlalchemy.orm import relationship, Session
from models.base import Base


class RequestTrackTable(Base):
    """SQLAlchemy RequestTrack table"""
    __tablename__ = "request_tracks"

    id = Column(Integer, primary_key=True, index=True)
    request_id = Column(String, ForeignKey("requests.id"),
                        nullable=True, index=True)
    store_request_id = Column(String, ForeignKey("store_requests.id"),
                              nullable=True, index=True)
    action_type = Column(String, nullable=False, index=True)
    performed_by = Column(String, ForeignKey("users.id"), nullable=False)
    performed_by_role = Column(String, nullable=False)
    comment = Column(Text, nullable=True)
    track_metadata = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)

    request = relationship("RequestTable", back_populates="tracks")
    store_request = relationship("StoreRequestTable", back_populates="tracks")
    performer = relationship("UserTable", back_populates="tracks")


class RequestTrack(BaseModel):
    id: Optional[int] = Field(default=None)
    request_id: Optional[str] = Field(default=None)
    store_request_id: Optional[str] = Field(default=None)
    action_type: str = Field()
    performed_by: str = Field()
    performed_by_role: str = Field()
    comment: Optional[str] = Field(default=None)
    track_metadata: Optional[dict] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(track_table: RequestTrackTable) -> "RequestTrack":
        """Convert SQLAlchemy model to Pydantic model"""
        return RequestTrack(
            id=int(track_table.id) if track_table.id else None,
            request_id=str(track_table.request_id) if track_table.request_id else None,
            store_request_id=str(track_table.store_request_id) if track_table.store_request_id else None,
            action_type=str(track_table.action_type),
            performed_by=str(track_table.performed_by),
            performed_by_role=str(track_table.performed_by_role),
            comment=str(track_table.comment) if track_table.comment else None,
            track_metadata=track_table.track_metadata,
            created_at=track_table.created_at
        )

    @staticmethod
    def create(db: Session, data: dict) -> "RequestTrack":
        """Create a new track"""
        track_table = RequestTrackTable(**data)
        db.add(track_table)
        db.commit()
        db.refresh(track_table)
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
        
        # Order by created_at ascending (chronological timeline)
        query = query.order_by(getattr(RequestTrackTable, order_by).asc())
        query = query.offset(skip)
        if limit:
            query = query.limit(limit)
        return [RequestTrack.from_orm(t) for t in query.all()]

    @staticmethod
    def update(db: Session, filter: dict, data: dict) -> bool:
        """Update track"""
        query = db.query(RequestTrackTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTrackTable, key) == value)
        result = query.update(data)
        db.commit()
        return result > 0

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Delete track"""
        query = db.query(RequestTrackTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTrackTable, key) == value)
        result = query.delete()
        db.commit()
        return result > 0

    @staticmethod
    def delete_all(db: Session, filter: dict) -> int:
        """Delete multiple tracks"""
        query = db.query(RequestTrackTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTrackTable, key) == value)
        result = query.delete()
        db.commit()
        return result

    @staticmethod
    def count(db: Session, filter: Optional[dict] = None) -> int:
        """Count tracks"""
        query = db.query(RequestTrackTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(RequestTrackTable, key) == value)
        return query.count()
