"""Department Model"""
from pydantic import BaseModel, Field
from typing import Optional, List
from sqlalchemy import Column, String, Integer
from sqlalchemy.orm import Session
from models.base import Base


class DepartmentTable(Base):
    """SQLAlchemy Department table"""
    __tablename__ = "departments"

    id = Column(Integer, primary_key=True, index=True)
    department = Column(String, nullable=False, unique=True, index=True)


class Department(BaseModel):
    id: Optional[int] = Field(default=None)
    department: str = Field()

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(row: DepartmentTable) -> "Department":
        return Department(
            id=int(row.id) if row.id else None,
            department=str(row.department),
        )

    @staticmethod
    def create(db: Session, department: str) -> "Department":
        """Stage a new department (caller must commit)"""
        row = DepartmentTable(department=department)
        db.add(row)
        db.flush()
        return Department.from_orm(row)

    @staticmethod
    def get(db: Session, filter: dict) -> Optional["Department"]:
        query = db.query(DepartmentTable)
        for key, value in filter.items():
            query = query.filter(getattr(DepartmentTable, key) == value)
        row = query.first()
        return Department.from_orm(row) if row else None

    @staticmethod
    def find(db: Session) -> List["Department"]:
        rows = db.query(DepartmentTable).order_by(DepartmentTable.department).all()
        return [Department.from_orm(r) for r in rows]

    @staticmethod
    def update(db: Session, dept_id: int, department: str) -> bool:
        """Stage an update (caller must commit)"""
        return (
            db.query(DepartmentTable)
            .filter(DepartmentTable.id == dept_id)
            .update({"department": department})
        ) > 0

    @staticmethod
    def delete(db: Session, dept_id: int) -> bool:
        """Stage a delete (caller must commit)"""
        return (
            db.query(DepartmentTable)
            .filter(DepartmentTable.id == dept_id)
            .delete()
        ) > 0
