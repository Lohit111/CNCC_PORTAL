"""Comment Model"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship, Session
from models.base import Base


class RequestCommentTable(Base):
    """SQLAlchemy RequestComment table"""
    __tablename__ = "request_comments"

    id = Column(Integer, primary_key=True, index=True)
    request_id = Column(String, ForeignKey("requests.id"),
                        nullable=False, index=True)
    sender_id = Column(String, ForeignKey("users.id"), nullable=False)
    sender_role = Column(String, nullable=False)
    message = Column(Text, nullable=False)
    type = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    request = relationship("RequestTable", back_populates="comments")
    sender = relationship("UserTable", back_populates="comments")


class RequestComment(BaseModel):
    id: Optional[int] = Field(default=None)
    request_id: str = Field()
    sender_id: str = Field()
    sender_role: str = Field()
    message: str = Field()
    type: str = Field()
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(comment_table: RequestCommentTable) -> "RequestComment":
        """Convert SQLAlchemy model to Pydantic model"""
        return RequestComment(
            id=int(comment_table.id) if comment_table.id else None,
            request_id=str(comment_table.request_id),
            sender_id=str(comment_table.sender_id),
            sender_role=str(comment_table.sender_role),
            message=str(comment_table.message),
            type=str(comment_table.type),
            created_at=comment_table.created_at
        )

    @staticmethod
    def create(db: Session, data: dict) -> "RequestComment":
        """Create a new comment"""
        comment_table = RequestCommentTable(**data)
        db.add(comment_table)
        db.commit()
        db.refresh(comment_table)
        return RequestComment.from_orm(comment_table)

    @staticmethod
    def get(db: Session, filter: dict) -> Optional["RequestComment"]:
        """Get a single comment by filter"""
        query = db.query(RequestCommentTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestCommentTable, key) == value)
        comment_table = query.first()
        return RequestComment.from_orm(comment_table) if comment_table else None

    @staticmethod
    def get_raw(db: Session, filter: dict) -> Optional[RequestCommentTable]:
        """Get raw SQLAlchemy object"""
        query = db.query(RequestCommentTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestCommentTable, key) == value)
        return query.first()

    @staticmethod
    def find(db: Session, filter: Optional[dict] = None, skip: int = 0, limit: Optional[int] = None) -> List["RequestComment"]:
        """Find multiple comments"""
        query = db.query(RequestCommentTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(
                    getattr(RequestCommentTable, key) == value)
        query = query.offset(skip)
        if limit:
            query = query.limit(limit)
        return [RequestComment.from_orm(c) for c in query.all()]

    @staticmethod
    def update(db: Session, filter: dict, data: dict) -> bool:
        """Update comment"""
        query = db.query(RequestCommentTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestCommentTable, key) == value)
        result = query.update(data)
        db.commit()
        return result > 0

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Delete comment"""
        query = db.query(RequestCommentTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestCommentTable, key) == value)
        result = query.delete()
        db.commit()
        return result > 0

    @staticmethod
    def delete_all(db: Session, filter: dict) -> int:
        """Delete multiple comments"""
        query = db.query(RequestCommentTable)
        for key, value in filter.items():
            query = query.filter(getattr(RequestCommentTable, key) == value)
        result = query.delete()
        db.commit()
        return result

    @staticmethod
    def count(db: Session, filter: Optional[dict] = None) -> int:
        """Count comments"""
        query = db.query(RequestCommentTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(
                    getattr(RequestCommentTable, key) == value)
        return query.count()
