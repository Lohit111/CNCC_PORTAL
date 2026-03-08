"""User Model"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime
from sqlalchemy.orm import relationship, Session
from models.base import Base


class UserTable(Base):
    """SQLAlchemy User table"""
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True)
    email = Column(String, unique=True, nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    raised_requests = relationship(
        "RequestTable", back_populates="raiser", foreign_keys="RequestTable.raised_by")
    tracks = relationship("RequestTrackTable", back_populates="performer")
    assignments = relationship(
        "AssignmentTable", back_populates="staff", foreign_keys="AssignmentTable.staff_id")
    store_requests = relationship(
        "StoreRequestTable", back_populates="requester", foreign_keys="StoreRequestTable.requested_by")
    store_chats = relationship("StoreChatTable", back_populates="sender")


class User(BaseModel):
    id: str = Field()
    email: str = Field()
    created_at: datetime = Field(default_factory=datetime.utcnow)
    is_active: bool = Field(default=True)

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(user_table: UserTable) -> "User":
        """Convert SQLAlchemy model to Pydantic model"""
        return User(
            id=str(user_table.id),
            email=str(user_table.email),
            created_at=user_table.created_at,
            is_active=bool(user_table.is_active)
        )

    @staticmethod
    def create(db: Session, data: dict) -> "User":
        """Create a new user"""
        user_table = UserTable(**data)
        db.add(user_table)
        db.commit()
        db.refresh(user_table)
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
        """Update user"""
        query = db.query(UserTable)
        for key, value in filter.items():
            query = query.filter(getattr(UserTable, key) == value)
        result = query.update(data)
        db.commit()
        return result > 0

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Delete user"""
        query = db.query(UserTable)
        for key, value in filter.items():
            query = query.filter(getattr(UserTable, key) == value)
        result = query.delete()
        db.commit()
        return result > 0

    @staticmethod
    def count(db: Session, filter: Optional[dict] = None) -> int:
        """Count users"""
        query = db.query(UserTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(UserTable, key) == value)
        return query.count()
