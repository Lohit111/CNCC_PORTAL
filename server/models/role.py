"""Role Model"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from sqlalchemy import Column, String, DateTime
from sqlalchemy.orm import Session
from models.base import Base


class RoleTable(Base):
    """SQLAlchemy Role table"""
    __tablename__ = "roles"

    email = Column(String, primary_key=True, unique=True,
                   nullable=False, index=True)
    role = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow,
                        onupdate=datetime.utcnow, nullable=False)


class Role(BaseModel):
    email: str = Field()
    role: str = Field()
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(role_table: RoleTable) -> "Role":
        """Convert SQLAlchemy model to Pydantic model"""
        return Role(
            email=str(role_table.email),
            role=str(role_table.role),
            created_at=role_table.created_at,
            updated_at=role_table.updated_at
        )

    @staticmethod
    def create(db: Session, data: dict) -> "Role":
        """Create a new role"""
        role_table = RoleTable(**data)
        db.add(role_table)
        db.commit()
        db.refresh(role_table)
        return Role.from_orm(role_table)

    @staticmethod
    def get(db: Session, filter: dict) -> Optional["Role"]:
        """Get a single role by filter"""
        query = db.query(RoleTable)
        for key, value in filter.items():
            query = query.filter(getattr(RoleTable, key) == value)
        role_table = query.first()
        return Role.from_orm(role_table) if role_table else None

    @staticmethod
    def get_raw(db: Session, filter: dict) -> Optional[RoleTable]:
        """Get raw SQLAlchemy object"""
        query = db.query(RoleTable)
        for key, value in filter.items():
            query = query.filter(getattr(RoleTable, key) == value)
        return query.first()

    @staticmethod
    def find(db: Session, filter: Optional[dict] = None, skip: int = 0, limit: Optional[int] = None) -> List["Role"]:
        """Find multiple roles"""
        query = db.query(RoleTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(RoleTable, key) == value)
        query = query.offset(skip)
        if limit:
            query = query.limit(limit)
        return [Role.from_orm(r) for r in query.all()]

    @staticmethod
    def update(db: Session, filter: dict, data: dict) -> bool:
        """Update role"""
        query = db.query(RoleTable)
        for key, value in filter.items():
            query = query.filter(getattr(RoleTable, key) == value)
        result = query.update(data)
        db.commit()
        return result > 0

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Delete role"""
        query = db.query(RoleTable)
        for key, value in filter.items():
            query = query.filter(getattr(RoleTable, key) == value)
        result = query.delete()
        db.commit()
        return result > 0

    @staticmethod
    def delete_all(db: Session, filter: dict) -> int:
        """Delete multiple roles"""
        query = db.query(RoleTable)
        for key, value in filter.items():
            query = query.filter(getattr(RoleTable, key) == value)
        result = query.delete()
        db.commit()
        return result

    @staticmethod
    def count(db: Session, filter: Optional[dict] = None) -> int:
        """Count roles"""
        query = db.query(RoleTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(RoleTable, key) == value)
        return query.count()
