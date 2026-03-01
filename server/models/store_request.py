"""Store Request Model"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
import uuid
from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship, Session
from models.base import Base


class StoreRequestTable(Base):
    """SQLAlchemy StoreRequest table"""
    __tablename__ = "store_requests"

    id = Column(String, primary_key=True,
                default=lambda: str(uuid.uuid4()), index=True)
    parent_request_id = Column(String, ForeignKey(
        "requests.id"), nullable=False, index=True)
    requested_by = Column(String, ForeignKey("users.id"), nullable=False)
    description = Column(Text, nullable=False)
    status = Column(String, default="PENDING", nullable=False, index=True)
    responded_by = Column(String, ForeignKey("users.id"), nullable=True)
    response_comment = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow,
                        onupdate=datetime.utcnow, nullable=False)

    parent_request = relationship(
        "RequestTable", back_populates="store_requests")
    requester = relationship(
        "UserTable", back_populates="store_requests", foreign_keys=[requested_by])


class StoreRequest(BaseModel):
    id: Optional[str] = Field(default=None)
    parent_request_id: str = Field()
    requested_by: str = Field()
    description: str = Field()
    status: str = Field(default="PENDING")
    responded_by: Optional[str] = Field(default=None)
    response_comment: Optional[str] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(store_request_table: StoreRequestTable) -> "StoreRequest":
        """Convert SQLAlchemy model to Pydantic model"""
        return StoreRequest(
            id=str(store_request_table.id) if store_request_table.id else None,
            parent_request_id=str(store_request_table.parent_request_id),
            requested_by=str(store_request_table.requested_by),
            description=str(store_request_table.description),
            status=str(store_request_table.status),
            responded_by=str(
                store_request_table.responded_by) if store_request_table.responded_by else None,
            response_comment=str(
                store_request_table.response_comment) if store_request_table.response_comment else None,
            created_at=store_request_table.created_at,
            updated_at=store_request_table.updated_at
        )

    @staticmethod
    def create(db: Session, data: dict) -> "StoreRequest":
        """Create a new store request"""
        if "id" not in data:
            data["id"] = str(uuid.uuid4())
        store_request_table = StoreRequestTable(**data)
        db.add(store_request_table)
        db.commit()
        db.refresh(store_request_table)
        return StoreRequest.from_orm(store_request_table)

    @staticmethod
    def get(db: Session, filter: dict) -> Optional["StoreRequest"]:
        """Get a single store request by filter"""
        query = db.query(StoreRequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(StoreRequestTable, key) == value)
        store_request_table = query.first()
        return StoreRequest.from_orm(store_request_table) if store_request_table else None

    @staticmethod
    def get_raw(db: Session, filter: dict) -> Optional[StoreRequestTable]:
        """Get raw SQLAlchemy object"""
        query = db.query(StoreRequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(StoreRequestTable, key) == value)
        return query.first()

    @staticmethod
    def find(db: Session, filter: Optional[dict] = None, skip: int = 0, limit: Optional[int] = None) -> List["StoreRequest"]:
        """Find multiple store requests"""
        query = db.query(StoreRequestTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(StoreRequestTable, key) == value)
        query = query.offset(skip)
        if limit:
            query = query.limit(limit)
        return [StoreRequest.from_orm(sr) for sr in query.all()]

    @staticmethod
    def update(db: Session, filter: dict, data: dict) -> bool:
        """Update store request"""
        query = db.query(StoreRequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(StoreRequestTable, key) == value)
        data["updated_at"] = datetime.utcnow()
        result = query.update(data)
        db.commit()
        return result > 0

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Delete store request"""
        query = db.query(StoreRequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(StoreRequestTable, key) == value)
        result = query.delete()
        db.commit()
        return result > 0

    @staticmethod
    def delete_all(db: Session, filter: dict) -> int:
        """Delete multiple store requests"""
        query = db.query(StoreRequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(StoreRequestTable, key) == value)
        result = query.delete()
        db.commit()
        return result

    @staticmethod
    def count(db: Session, filter: Optional[dict] = None) -> int:
        """Count store requests"""
        query = db.query(StoreRequestTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(StoreRequestTable, key) == value)
        return query.count()
