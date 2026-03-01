"""Request Model"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
import uuid
from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship, Session
from models.user import Base


class RequestTable(Base):
    """SQLAlchemy Request table"""
    __tablename__ = "requests"

    id = Column(String, primary_key=True,
                default=lambda: str(uuid.uuid4()), index=True)
    raised_by = Column(String, ForeignKey("users.id"),
                       nullable=False, index=True)
    main_type_id = Column(Integer, ForeignKey("main_types.id"), nullable=False)
    sub_type_id = Column(Integer, ForeignKey("sub_types.id"), nullable=False)
    description = Column(Text, nullable=False)
    status = Column(String, default="RAISED", nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow,
                        onupdate=datetime.utcnow, nullable=False)

    raiser = relationship(
        "UserTable", back_populates="raised_requests", foreign_keys=[raised_by])
    main_type = relationship("MainTypeTable", back_populates="requests")
    sub_type = relationship("SubTypeTable", back_populates="requests")
    comments = relationship(
        "RequestCommentTable", back_populates="request", cascade="all, delete-orphan")
    assignments = relationship(
        "AssignmentTable", back_populates="request", cascade="all, delete-orphan")
    store_requests = relationship(
        "StoreRequestTable", back_populates="parent_request", cascade="all, delete-orphan")


class Request(BaseModel):
    id: Optional[str] = Field(default=None)
    raised_by: str = Field()
    main_type_id: int = Field()
    sub_type_id: int = Field()
    description: str = Field()
    status: str = Field(default="RAISED")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(request_table: RequestTable) -> "Request":
        """Convert SQLAlchemy model to Pydantic model"""
        return Request(
            id=str(request_table.id) if request_table.id else None,
            raised_by=str(request_table.raised_by),
            main_type_id=int(request_table.main_type_id),
            sub_type_id=int(request_table.sub_type_id),
            description=str(request_table.description),
            status=str(request_table.status),
            created_at=request_table.created_at,
            updated_at=request_table.updated_at
        )

    @staticmethod
    def create(db: Session, data: dict) -> "Request":
        """Create a new request"""
        if "id" not in data:
            data["id"] = str(uuid.uuid4())
        request_table = RequestTable(**data)
        db.add(request_table)
        db.commit()
        db.refresh(request_table)
        return Request.from_orm(request_table)

    @staticmethod
    def get(db: Session, filter: dict) -> Optional["Request"]:
        """Get a single request by filter"""
        query = db.query(RequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTable, key) == value)
        request_table = query.first()
        return Request.from_orm(request_table) if request_table else None

    @staticmethod
    def get_raw(db: Session, filter: dict) -> Optional[RequestTable]:
        """Get raw SQLAlchemy object"""
        query = db.query(RequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTable, key) == value)
        return query.first()

    @staticmethod
    def find(db: Session, filter: Optional[dict] = None, skip: int = 0, limit: Optional[int] = None) -> List["Request"]:
        """Find multiple requests"""
        query = db.query(RequestTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(RequestTable, key) == value)
        query = query.offset(skip)
        if limit:
            query = query.limit(limit)
        return [Request.from_orm(r) for r in query.all()]

    @staticmethod
    def update(db: Session, filter: dict, data: dict) -> bool:
        """Update request"""
        query = db.query(RequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTable, key) == value)
        data["updated_at"] = datetime.utcnow()
        result = query.update(data)
        db.commit()
        return result > 0

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Delete request"""
        query = db.query(RequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTable, key) == value)
        result = query.delete()
        db.commit()
        return result > 0

    @staticmethod
    def delete_all(db: Session, filter: dict) -> int:
        """Delete multiple requests"""
        query = db.query(RequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTable, key) == value)
        result = query.delete()
        db.commit()
        return result

    @staticmethod
    def count(db: Session, filter: Optional[dict] = None) -> int:
        """Count requests"""
        query = db.query(RequestTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(RequestTable, key) == value)
        return query.count()
