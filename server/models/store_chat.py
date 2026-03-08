"""Store Chat Model - For communication between STAFF and STORE on APPROVED store requests"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship, Session
from models.base import Base


class StoreChatTable(Base):
    """SQLAlchemy StoreChat table"""
    __tablename__ = "store_chats"

    id = Column(Integer, primary_key=True, index=True)
    store_request_id = Column(String, ForeignKey("store_requests.id"),
                              nullable=False, index=True)
    sender_id = Column(String, ForeignKey("users.id"), nullable=False)
    sender_role = Column(String, nullable=False)
    message = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)

    store_request = relationship("StoreRequestTable", back_populates="chats")
    sender = relationship("UserTable", back_populates="store_chats")


class StoreChat(BaseModel):
    id: Optional[int] = Field(default=None)
    store_request_id: str = Field()
    sender_id: str = Field()
    sender_role: str = Field()
    message: str = Field()
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(chat_table: StoreChatTable) -> "StoreChat":
        """Convert SQLAlchemy model to Pydantic model"""
        return StoreChat(
            id=int(chat_table.id) if chat_table.id else None,
            store_request_id=str(chat_table.store_request_id),
            sender_id=str(chat_table.sender_id),
            sender_role=str(chat_table.sender_role),
            message=str(chat_table.message),
            created_at=chat_table.created_at
        )

    @staticmethod
    def create(db: Session, data: dict) -> "StoreChat":
        """Create a new chat message"""
        chat_table = StoreChatTable(**data)
        db.add(chat_table)
        db.commit()
        db.refresh(chat_table)
        return StoreChat.from_orm(chat_table)

    @staticmethod
    def get(db: Session, filter: dict) -> Optional["StoreChat"]:
        """Get a single chat message by filter"""
        query = db.query(StoreChatTable)
        for key, value in filter.items():
            query = query.filter(getattr(StoreChatTable, key) == value)
        chat_table = query.first()
        return StoreChat.from_orm(chat_table) if chat_table else None

    @staticmethod
    def find(db: Session, filter: Optional[dict] = None, skip: int = 0, limit: Optional[int] = None) -> List["StoreChat"]:
        """Find multiple chat messages ordered by created_at"""
        query = db.query(StoreChatTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(StoreChatTable, key) == value)
        
        # Order by created_at ascending (chronological)
        query = query.order_by(StoreChatTable.created_at.asc())
        query = query.offset(skip)
        if limit:
            query = query.limit(limit)
        return [StoreChat.from_orm(c) for c in query.all()]

    @staticmethod
    def delete_all(db: Session, filter: dict) -> int:
        """Delete multiple chat messages"""
        query = db.query(StoreChatTable)
        for key, value in filter.items():
            query = query.filter(getattr(StoreChatTable, key) == value)
        result = query.delete()
        db.commit()
        return result

    @staticmethod
    def count(db: Session, filter: Optional[dict] = None) -> int:
        """Count chat messages"""
        query = db.query(StoreChatTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(StoreChatTable, key) == value)
        return query.count()
