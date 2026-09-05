"""User Model"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
import uuid
from sqlalchemy import Column, String, Boolean, DateTime, Enum as SAEnum
from sqlalchemy.orm import relationship, Session
from models.base import Base
from models.enums import UserRole


class UserTable(Base):
    """SQLAlchemy User table"""
    __tablename__ = "users"

    id = Column(String, primary_key=True,
                default=lambda: str(uuid.uuid4()), index=True)
    email = Column(String, unique=True, nullable=False, index=True)
    name = Column(String, nullable=True)
    phone = Column(String(10), nullable=True)
    role = Column(SAEnum(UserRole), nullable=False, index=True)
    is_active = Column(Boolean, default=True, nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    raised_requests = relationship(
        "RequestTable", back_populates="raiser", foreign_keys="RequestTable.raised_by")
    tracks = relationship("RequestTrackTable", back_populates="performer")
    assignments = relationship(
        "AssignmentTable", back_populates="staff", foreign_keys="AssignmentTable.staff_id")
    store_requests = relationship(
        "StoreRequestTable", back_populates="requester", foreign_keys="StoreRequestTable.requested_by")
    responded_store_requests = relationship(
        "StoreRequestTable", back_populates="responder", foreign_keys="StoreRequestTable.responded_by")
    store_chats = relationship("StoreChatTable", back_populates="sender")


class User(BaseModel):
    id: str = Field()
    email: str = Field()
    name: Optional[str] = Field(default=None)
    phone: Optional[str] = Field(default=None)
    role: UserRole = Field()
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(user_table: UserTable) -> "User":
        """Convert SQLAlchemy model to Pydantic model"""
        return User(
            id=str(user_table.id),
            email=str(user_table.email),
            name=user_table.name,
            phone=user_table.phone,
            role=user_table.role,
            is_active=bool(user_table.is_active),
            created_at=user_table.created_at
        )

    @staticmethod
    def create(db: Session, data: dict) -> "User":
        """Stage a new user (caller must commit)"""
        user_table = UserTable(**data)
        db.add(user_table)
        db.flush()
        return User.from_orm(user_table)

    @staticmethod
    def get(db: Session, filter: dict) -> Optional["User"]:
        """Get a single user by filter"""
        query = db.query(UserTable)
        for key, value in filter.items():
            query = query.filter(getattr(UserTable, key) == value)
        user_table = query.first()
        return User.from_orm(user_table) if user_table else None

    @staticmethod
    def get_raw(db: Session, filter: dict) -> Optional[UserTable]:
        """Get raw SQLAlchemy object"""
        query = db.query(UserTable)
        for key, value in filter.items():
            query = query.filter(getattr(UserTable, key) == value)
        return query.first()

    @staticmethod
    def find(db: Session, filter: Optional[dict] = None, skip: int = 0, limit: Optional[int] = None) -> List["User"]:
        """Find multiple users"""
        query = db.query(UserTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(UserTable, key) == value)
        query = query.offset(skip)
        if limit:
            query = query.limit(limit)
        return [User.from_orm(u) for u in query.all()]

    @staticmethod
    def update(db: Session, filter: dict, data: dict) -> bool:
        """Stage an update (caller must commit)"""
        query = db.query(UserTable)
        for key, value in filter.items():
            query = query.filter(getattr(UserTable, key) == value)
        return query.update(data) > 0

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Stage a delete (caller must commit)"""
        query = db.query(UserTable)
        for key, value in filter.items():
            query = query.filter(getattr(UserTable, key) == value)
        return query.delete() > 0

    @staticmethod
    def count(db: Session, filter: Optional[dict] = None) -> int:
        """Count users"""
        query = db.query(UserTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(UserTable, key) == value)
        return query.count()
