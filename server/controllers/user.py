"""User Controller"""
from sqlalchemy.orm import Session
from fastapi import HTTPException
from models.user import User
from models.enums import UserRole


def get_users(db: Session, page: int = 1) -> dict:
    """Get all active users paginated in chunks of 50"""
    page_size = 50
    skip = (page - 1) * page_size
    total = User.count(db, {"is_active": True})
    users = User.find(db, {"is_active": True}, skip=skip, limit=page_size)
    return {
        "users": users,
        "total": total,
        "page": page,
        "pages": -(-total // page_size)  # ceiling division
    }


def create_user(db: Session, email: str, role: UserRole) -> User:
    """Create a new active user with given email and role"""
    existing = User.get(db, {"email": email})
    if existing:
        raise HTTPException(
            status_code=409, detail="User with this email already exists")
    user = User.create(db, {"email": email, "role": role, "is_active": True})
    db.commit()
    return user


def update_user_role(db: Session, user_id: str, role: UserRole) -> User:
    """Update a user's role"""
    user = User.get(db, {"id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    User.update(db, {"id": user_id}, {"role": role})
    db.commit()
    return User.get(db, {"id": user_id})  # pyright: ignore[reportReturnType]


def update_user_name(db: Session, user_id: str, name: str) -> User:
    """Update the current user's name"""
    User.update(db, {"id": user_id}, {"name": name})
    db.commit()
    return User.get(db, {"id": user_id}) # pyright: ignore[reportReturnType]


def deactivate_user(db: Session, user_id: str) -> bool:
    """Soft delete a user by setting is_active to False"""
    user = User.get(db, {"id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if not user.is_active:
        raise HTTPException(
            status_code=409, detail="User is already deactivated")
    User.update(db, {"id": user_id}, {"is_active": False})
    db.commit()
    return True
