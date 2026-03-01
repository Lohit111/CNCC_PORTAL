"""User Controller - Handles business logic for User model"""
from fastapi import HTTPException
from sqlalchemy.orm import Session
from models.user import User
from models.role import Role
import logging

logger = logging.getLogger(__name__)


class UserController:
    @staticmethod
    def get_current_user_profile(db: Session, user_id: str):
        """Get current user profile with role"""
        try:
            user = User.get(db, {"id": user_id})
            if not user:
                raise HTTPException(status_code=404, detail="User not found")

            # Get user's role
            role_record = Role.get(db, {"email": user.email})
            role = role_record.role if role_record else None

            return {
                "id": user.id,
                "email": user.email,
                "role": role,
                "is_active": user.is_active,
                "created_at": user.created_at.isoformat()
            }

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch user profile {user_id}: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_by_id(db: Session, user_id: str):
        """Get user by ID"""
        try:
            user = User.get(db, {"id": user_id})
            if not user:
                raise HTTPException(status_code=404, detail="User not found")
            return user

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch user {user_id}: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_all(db: Session, skip: int = 0, limit: int = 100):
        """Get all users"""
        try:
            users = User.find(db, skip=skip, limit=limit)
            total = User.count(db)

            logger.info(f"Retrieved {len(users)} users")
            return {
                "items": users,
                "total": total
            }

        except Exception as e:
            logger.error(f"Failed to fetch users: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def update(db: Session, user_id: str, data: dict):
        """Update user"""
        try:
            logger.info(f"Updating user: {user_id}")

            exists = User.get(db, {"id": user_id})
            if not exists:
                raise HTTPException(status_code=404, detail="User not found")

            updated = User.update(db, {"id": user_id}, data)
            if not updated:
                raise HTTPException(
                    status_code=500, detail="User update failed")

            logger.info(f"User updated successfully: {user_id}")
            return User.get(db, {"id": user_id})

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to update user {user_id}: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")
