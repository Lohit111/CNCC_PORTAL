"""User API Endpoints"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from models.user import User
from models.enums import UserRole
from middleware.auth import get_current_user, require_role
from controllers.user import get_users, create_user, update_user_role, update_user_name, deactivate_user
from config.database import get_db

router = APIRouter(prefix="/users", tags=["Users"])


# --- Request Schemas ---

class CreateUserRequest(BaseModel):
    email: str
    role: UserRole


class UpdateRoleRequest(BaseModel):
    role: UserRole


class UpdateNameRequest(BaseModel):
    name: str


# --- Endpoints ---

@router.get("/me")
async def me(user: User = Depends(get_current_user)):
    """Get the currently authenticated user"""
    return user


@router.put("/me/name")
async def update_name(
    body: UpdateNameRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update the current user's name"""
    return update_user_name(db, user_id=user.id, name=body.name)


@router.get("/")
async def list_users(
    page: int = 1,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Get all active users paginated (50 per page)"""
    return get_users(db, page=page)


@router.post("/")
async def create(
    body: CreateUserRequest,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Create a new user with email and role"""
    return create_user(db, email=body.email, role=body.role)


@router.put("/{user_id}/update-role")
async def update_role(
    user_id: str,
    body: UpdateRoleRequest,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Update a user's role"""
    return update_user_role(db, user_id=user_id, role=body.role)


@router.delete("/{user_id}")
async def delete_user(
    user_id: str,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Deactivate a user (soft delete)"""
    deactivate_user(db, user_id=user_id)
    return {"message": "User deactivated successfully"}
