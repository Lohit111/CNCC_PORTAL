"""Authentication Middleware"""
from typing import Optional
from fastapi import HTTPException, Header, Depends
from sqlalchemy.orm import Session
from firebase_admin import auth
from models.user import User
from models.role import Role
from config.database import get_db
import logging

logger = logging.getLogger(__name__)


def get_firebase_user_from_token(authorization: Optional[str]):
    """Verify Firebase token and return user info"""
    if not authorization:
        raise HTTPException(
            status_code=401, detail="Missing Authorization header")

    if not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=401, detail="Invalid Authorization header")

    token = authorization.split(" ")[1]

    try:
        decoded_token = auth.verify_id_token(token)
        return {
            "firebaseId": decoded_token.get("uid"),
            "email": decoded_token.get("email"),
            "name": decoded_token.get("name")
        }
    except Exception as e:
        logger.error(f"Firebase token verification failed: {str(e)}")
        raise HTTPException(status_code=401, detail="Invalid Firebase token")


def get_firebase_user_from_header(authorization: Optional[str] = Header(None)):
    """Get Firebase user from Authorization header"""
    return get_firebase_user_from_token(authorization)


async def get_current_user(authorization: str = Header(...), db: Session = Depends(get_db)):
    """Get current authenticated user with role"""
    try:
        firebase_user = get_firebase_user_from_header(authorization)
        firebase_id = firebase_user["firebaseId"]
        email = firebase_user["email"]

        # Check role assignment
        role_record = Role.get(db, {"email": email})
        if not role_record:
            # Auto-assign "user" role for vnrvjiet.in institutional emails
            # that do NOT start with two digits (student roll numbers start with digits)
            local_part = email.split("@")[0] if "@" in email else ""
            domain = email.split("@")[1] if "@" in email else ""
            is_vnr_domain = domain == "vnrvjiet.in"
            starts_with_two_digits = len(
                local_part) >= 2 and local_part[:2].isdigit()

            # if is_vnr_domain and not starts_with_two_digits:
            if is_vnr_domain:
                logger.info(
                    f"Auto-assigning 'user' role to institutional email: {email}")
                role_record = Role.create(db, {"email": email, "role": "USER"})
            else:
                logger.warning(
                    f"User {email} attempted access without role assignment")
                raise HTTPException(
                    status_code=403, detail="Access denied: No role assigned to this email")

        # Get or create user
        user = User.get(db, {"id": firebase_id})
        if not user:
            user = User.create(db, {"id": firebase_id, "email": email})
            logger.info(f"Created new user: {email}")

        return {"user": user, "role": role_record.role}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting current user: {str(e)}")
        raise HTTPException(500, "Failed to retrieve user information")


def require_role(*allowed_roles: str):
    """Dependency to enforce role-based access control"""
    async def role_checker(auth_data: dict = Depends(get_current_user)):
        user = auth_data["user"]
        role = auth_data["role"]

        if role not in allowed_roles:
            raise HTTPException(
                status_code=403,
                detail=f"Access denied: Required role(s): {list(allowed_roles)}"
            )

        return {"user": user, "role": role}

    return role_checker
