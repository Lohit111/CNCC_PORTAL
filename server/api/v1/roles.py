"""Role Endpoints"""
from fastapi import APIRouter, Request, Depends, Query
from sqlalchemy.orm import Session
from typing import List
from config.database import get_db
from middleware.auth import require_role
from controllers.role import RoleController
from models.role import Role

router = APIRouter()


@router.get("/", response_model=dict)
async def get_all_roles(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Get all roles"""
    return RoleController.get_all(db, skip=skip, limit=limit)


@router.get("/{email}", response_model=Role)
async def get_role_by_email(
    email: str,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Get role by email"""
    return RoleController.get_by_email(db, email)


@router.post("/", response_model=Role)
async def create_role(
    request: Request,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Create a new role"""
    data = await request.json()
    return RoleController.create(db, data)


@router.put("/{email}", response_model=Role)
async def update_role(
    email: str,
    request: Request,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Update role"""
    data = await request.json()
    return RoleController.update(db, email, data)


@router.delete("/{email}")
async def delete_role(
    email: str,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Delete role"""
    return RoleController.delete(db, email)


@router.post("/bulk")
async def bulk_create_roles(
    request: Request,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Bulk create or update roles"""
    data = await request.json()
    roles_data = data.get("roles", [])
    return RoleController.bulk_create(db, roles_data)
