"""Request Model"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
import uuid
from sqlalchemy import Column, String, ForeignKey, DateTime, Text, Enum as SAEnum
from sqlalchemy.orm import relationship, Session
from models.base import Base
from models.enums import RequestStatus


class RequestTable(Base):
    """SQLAlchemy Request table"""
    __tablename__ = "requests"

    id = Column(String, primary_key=True,
                default=lambda: str(uuid.uuid4()), index=True)
    raised_by = Column(String, ForeignKey("users.id"),
                       nullable=False, index=True)
    main_type = Column(String, nullable=False)
    sub_type = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    room_no = Column(String, nullable=False)
    phone_no = Column(String(10), nullable=False)
    status = Column(SAEnum(RequestStatus), nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow,
                        onupdate=datetime.utcnow, nullable=False)

    raiser = relationship(
        "UserTable", back_populates="raised_requests", foreign_keys=[raised_by])
    tracks = relationship(
        "RequestTrackTable", back_populates="request", cascade="all, delete-orphan")
    assignments = relationship(
        "AssignmentTable", back_populates="request", cascade="all, delete-orphan")
    store_requests = relationship(
        "StoreRequestTable", back_populates="parent_request", cascade="all, delete-orphan")


class Request(BaseModel):
    id: Optional[str] = Field(default=None)
    raised_by: str = Field()
    main_type: str = Field()
    sub_type: str = Field()
    description: str = Field()
    room_no: str = Field()
    phone_no: str = Field()
    status: RequestStatus = Field()
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
            main_type=str(request_table.main_type),
            sub_type=str(request_table.sub_type),
            description=str(request_table.description),
            room_no=str(request_table.room_no),
            phone_no=str(request_table.phone_no),
            status=request_table.status,
            created_at=request_table.created_at,
            updated_at=request_table.updated_at
        )

    @staticmethod
    def create(db: Session, data: dict) -> "Request":
        """Stage a new request (caller must commit)"""
        if "id" not in data:
            data["id"] = str(uuid.uuid4())
        request_table = RequestTable(**data)
        db.add(request_table)
        db.flush()
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
        """Stage an update (caller must commit)"""
        query = db.query(RequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTable, key) == value)
        data["updated_at"] = datetime.utcnow()
        return query.update(data) > 0

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Stage a delete (caller must commit)"""
        query = db.query(RequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTable, key) == value)
        return query.delete() > 0

    @staticmethod
    def delete_all(db: Session, filter: dict) -> int:
        """Stage bulk delete (caller must commit)"""
        query = db.query(RequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestTable, key) == value)
        return query.delete()

    @staticmethod
    def count(db: Session, filter: Optional[dict] = None) -> int:
        """Count requests"""
        query = db.query(RequestTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(RequestTable, key) == value)
        return query.count()
