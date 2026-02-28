"""Assignment Model"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, Boolean
from sqlalchemy.orm import relationship, Session
from models.user import Base


class AssignmentTable(Base):
    """SQLAlchemy Assignment table"""
    __tablename__ = "assignments"

    id = Column(Integer, primary_key=True, index=True)
    request_id = Column(String, ForeignKey("requests.id"), nullable=False, index=True)
    staff_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    assigned_by = Column(String, ForeignKey("users.id"), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    request = relationship("RequestTable", back_populates="assignments")
    staff = relationship("UserTable", back_populates="assignments", foreign_keys=[staff_id])


class Assignment(BaseModel):
    id: Optional[int] = Field(default=None)
    request_id: str = Field()
    staff_id: str = Field()
    assigned_by: str = Field()
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(assignment_table: AssignmentTable) -> "Assignment":
        """Convert SQLAlchemy model to Pydantic model"""
        return Assignment(
            id=int(assignment_table.id) if assignment_table.id else None,
            request_id=str(assignment_table.request_id),
            staff_id=str(assignment_table.staff_id),
            assigned_by=str(assignment_table.assigned_by),
            is_active=bool(assignment_table.is_active),
            created_at=assignment_table.created_at
        )

    @staticmethod
    def create(db: Session, data: dict) -> "Assignment":
        """Create a new assignment"""
        assignment_table = AssignmentTable(**data)
        db.add(assignment_table)
        db.commit()
        db.refresh(assignment_table)
        return Assignment.from_orm(assignment_table)

    @staticmethod
    def get(db: Session, filter: dict) -> Optional["Assignment"]:
        """Get a single assignment by filter"""
        query = db.query(AssignmentTable)
        for key, value in filter.items():
            query = query.filter(getattr(AssignmentTable, key) == value)
        assignment_table = query.first()
        return Assignment.from_orm(assignment_table) if assignment_table else None

    @staticmethod
    def get_raw(db: Session, filter: dict) -> Optional[AssignmentTable]:
        """Get raw SQLAlchemy object"""
        query = db.query(AssignmentTable)
        for key, value in filter.items():
            query = query.filter(getattr(AssignmentTable, key) == value)
        return query.first()

    @staticmethod
    def find(db: Session, filter: Optional[dict] = None, skip: int = 0, limit: Optional[int] = None) -> List["Assignment"]:
        """Find multiple assignments"""
        query = db.query(AssignmentTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(AssignmentTable, key) == value)
        query = query.offset(skip)
        if limit:
            query = query.limit(limit)
        return [Assignment.from_orm(a) for a in query.all()]

    @staticmethod
    def update(db: Session, filter: dict, data: dict) -> bool:
        """Update assignment"""
        query = db.query(AssignmentTable)
        for key, value in filter.items():
            query = query.filter(getattr(AssignmentTable, key) == value)
        result = query.update(data)
        db.commit()
        return result > 0

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Delete assignment"""
        query = db.query(AssignmentTable)
        for key, value in filter.items():
            query = query.filter(getattr(AssignmentTable, key) == value)
        result = query.delete()
        db.commit()
        return result > 0

    @staticmethod
    def delete_all(db: Session, filter: dict) -> int:
        """Delete multiple assignments"""
        query = db.query(AssignmentTable)
        for key, value in filter.items():
            query = query.filter(getattr(AssignmentTable, key) == value)
        result = query.delete()
        db.commit()
        return result

    @staticmethod
    def count(db: Session, filter: Optional[dict] = None) -> int:
        """Count assignments"""
        query = db.query(AssignmentTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(AssignmentTable, key) == value)
        return query.count()
