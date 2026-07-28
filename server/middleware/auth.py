"""Authentication Middleware"""
from typing import Optional
from fastapi import HTTPException, Header, Depends
from sqlalchemy.orm import Session
from firebase_admin import auth
from models.user import User
from models.enums import UserRole
from config.database import get_db
import logging

logger = logging.getLogger(__name__)


def get_email_from_token(authorization: Optional[str]) -> str:
    """Verify Firebase token and return email"""
    if not authorization:
        raise HTTPException(
            status_code=401, detail="Missing Authorization header")
    if not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=401, detail="Invalid Authorization header")

    token = authorization.split(" ")[1]
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token.get("email")
    except Exception as e:
        logger.error(f"Firebase token verification failed: {str(e)}")
        raise HTTPException(status_code=401, detail="Invalid Firebase token")


def _resolve_default_role(email: str) -> bool:
    """Return True if email is under the vnrvjiet.in domain"""
    domain = email.split("@")[1] if "@" in email else ""
    return domain == "vnrvjiet.in"


async def get_current_user(authorization: str = Header(...), db: Session = Depends(get_db)) -> User:
    """Get current authenticated user"""
    try:
        email = get_email_from_token(authorization)

        user = User.get(db, {"email": email, "is_active": True})
        if user:
            return user

        if not _resolve_default_role(email):
            raise HTTPException(
                status_code=403,
                detail="Access denied: No Role Assigned: Please contact the Administator for Role Assignment"
            )

        # User exists but was deactivated — reactivate
        existing = User.get(db, {"email": email})
        if existing:
            User.update(db, {"email": email}, {"is_active": True})
            db.commit()
            return User.get(db, {"email": email}) # pyright: ignore[reportReturnType]

        # Brand new user
        user = User.create(
            db, {"email": email, "role": UserRole.USER, "is_active": True})
        db.commit()
        logger.info(f"Created new user: {email}")
        return user

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting current user: {str(e)}")
        raise HTTPException(
            status_code=500, detail="Failed to retrieve user information")


def require_role(*allowed_roles: UserRole):
    """Dependency to enforce role-based access control"""
    async def role_checker(user: User = Depends(get_current_user)) -> User:
        if user.role not in allowed_roles:
            raise HTTPException(
                status_code=403,
                detail=f"Access denied: Required role(s): {[r.value for r in allowed_roles]}"
            )
        return user

    return role_checker
