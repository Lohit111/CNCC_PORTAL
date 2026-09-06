"""User API Endpoints"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from models.user import User
from models.user_fcm import UserFcm
from models.enums import UserRole, DevicePlatform
from middleware.auth import get_current_user, require_role
from controllers.users import get_users, create_user, update_user_role, update_user_profile, deactivate_user, activate_user
from config.database import get_db

router = APIRouter(prefix="/users", tags=["Users"])


# --- Request Schemas ---

class CreateUserRequest(BaseModel):
    email: str
    role: UserRole


class UpdateRoleRequest(BaseModel):
    role: UserRole


class UpdateProfileRequest(BaseModel):
    name: str
    phone: str


class UpsertFcmTokenRequest(BaseModel):
    fcm_token: str
    platform: DevicePlatform = DevicePlatform.UNKNOWN


# --- Endpoints ---

@router.get("/me")
async def me(user: User = Depends(get_current_user)):
    """Get the currently authenticated user"""
    return user


@router.put("/me/profile")
async def update_profile(
    body: UpdateProfileRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update the current user's name and phone number"""
    return update_user_profile(db, user_id=user.id, name=body.name, phone=body.phone)


@router.get("/")
async def list_users(
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Get all active users"""
    return get_users(db)


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
    if user.id == user_id:
        raise HTTPException(
            status_code=400, detail="You cannot change your own role")
    return update_user_role(db, user_id=user_id, role=body.role, admin_name=user.name)


@router.put("/{user_id}/deactivate")
async def deactivate_user_endpoint(
    user_id: str,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Deactivate a user (soft delete)"""
    if user.id == user_id:
        raise HTTPException(
            status_code=400, detail="You cannot deactivate your own account")
    deactivate_user(db, user_id=user_id, admin_name=user.name)
    return {"message": "User deactivated successfully"}

@router.put("/{user_id}/activate")
async def activate_user_endpoint(
    user_id: str,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Activate a user (soft delete)"""
    if user.id == user_id:
        raise HTTPException(
            status_code=400, detail="You cannot activate your own account")
    activate_user(db, user_id=user_id, admin_name=user.name)
    return {"message": "User activated successfully"}

@router.post("/upsert_fcm_token")
async def upsert_fcm_token(
    body: UpsertFcmTokenRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Register or update the FCM token for the currently authenticated user"""
    result = UserFcm.upsert(db, user_id=user.id,
                            fcm_token=body.fcm_token, platform=body.platform)
    db.commit()
    return result
