"""Types API Endpoints"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from models.user import User
from models.enums import UserRole
from middleware.auth import get_current_user, require_role
from controllers.types import (
    get_main_types, create_main_type, update_main_type, delete_main_type,
    get_sub_types, create_sub_type, update_sub_type, delete_sub_type
)
from config.database import get_db

router = APIRouter(prefix="/types", tags=["Types"])


# --- Request Schemas ---

class NameRequest(BaseModel):
    name: str


# --- Public Endpoints ---

@router.get("/main")
async def list_main_types(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all main types"""
    return get_main_types(db)


@router.get("/{main_id}/sub")
async def list_sub_types(
    main_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all sub types for a main type"""
    return get_sub_types(db, main_id=main_id)


# --- Admin Endpoints ---

@router.post("/main")
async def create_main(
    body: NameRequest,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Create a new main type"""
    return create_main_type(db, name=body.name)


@router.post("/{main_id}/sub")
async def create_sub(
    main_id: int,
    body: NameRequest,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Create a new sub type under a main type"""
    return create_sub_type(db, main_id=main_id, name=body.name)


@router.put("/main/{main_id}")
async def update_main(
    main_id: int,
    body: NameRequest,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Update the name of a main type"""
    return update_main_type(db, main_id=main_id, name=body.name)


@router.put("/sub/{sub_id}")
async def update_sub(
    sub_id: int,
    body: NameRequest,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Update the name of a sub type"""
    return update_sub_type(db, sub_id=sub_id, name=body.name)


@router.delete("/main/{main_id}")
async def delete_main(
    main_id: int,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Delete a main type (cascades to its sub types)"""
    delete_main_type(db, main_id=main_id)
    return {"message": "Main type deleted successfully"}


@router.delete("/sub/{sub_id}")
async def delete_sub(
    sub_id: int,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Delete a sub type"""
    delete_sub_type(db, sub_id=sub_id)
    return {"message": "Sub type deleted successfully"}
