"""Departments API Endpoints"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from models.user import User
from models.enums import UserRole
from middleware.auth import require_role
from controllers.departments import (
    get_departments,
    create_department,
    update_department,
    delete_department,
)
from config.database import get_db

router = APIRouter(prefix="/departments", tags=["Departments"])


# --- Request Schemas ---

class DepartmentRequest(BaseModel):
    department: str


# --- Endpoints ---

@router.get("/")
async def list_departments(
    user: User = Depends(
        require_role(UserRole.ADMIN, UserRole.STAFF, UserRole.USER)
    ),
    db: Session = Depends(get_db),
):
    """Get all departments — accessible by all authenticated users"""
    return get_departments(db)


@router.post("/")
async def create(
    body: DepartmentRequest,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db),
):
    """Create a new department — admin only"""
    return create_department(db, department=body.department)


@router.put("/{dept_id}")
async def update(
    dept_id: int,
    body: DepartmentRequest,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db),
):
    """Update a department's name — admin only"""
    return update_department(db, dept_id=dept_id, department=body.department)


@router.delete("/{dept_id}")
async def delete(
    dept_id: int,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db),
):
    """Delete a department — admin only"""
    delete_department(db, dept_id=dept_id)
    return {"message": "Department deleted successfully"}
