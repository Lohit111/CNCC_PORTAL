"""User Endpoints"""
from fastapi import APIRouter, Request, Depends, Query
from sqlalchemy.orm import Session
from typing import List
from config.database import get_db
from middleware.auth import require_role, get_current_user
from controllers.user import UserController
from models.user import User

router = APIRouter()


@router.get("/me")
async def get_current_user_profile(
    auth_data: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current authenticated user's profile"""
    user = auth_data["user"]
    role = auth_data["role"]
    
    return {
        "id": user.id,
        "email": user.email,
        "role": role,
        "is_active": user.is_active,
        "created_at": user.created_at.isoformat()
    }


@router.get("/", response_model=dict)
async def get_all_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Get all users (ADMIN only)"""
    return UserController.get_all(db, skip=skip, limit=limit)


@router.get("/{user_id}", response_model=User)
async def get_user_by_id(
    user_id: str,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Get user by ID (ADMIN only)"""
    return UserController.get_by_id(db, user_id)


@router.put("/{user_id}", response_model=User)
async def update_user(
    user_id: str,
    request: Request,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Update user (ADMIN only)"""
    data = await request.json()
    return UserController.update(db, user_id, data)
