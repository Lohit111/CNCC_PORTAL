"""Role Controller - Handles all business logic for Role model"""
from fastapi import HTTPException
from sqlalchemy.orm import Session
from models.role import Role
import logging

logger = logging.getLogger(__name__)


class RoleController:
    @staticmethod
    def create(db: Session, data: dict):
        """Create a new role"""
        try:
            # Check if role already exists
            existing = Role.get(db, {"email": data.get("email")})
            if existing:
                raise HTTPException(
                    status_code=409, detail="Role already exists for this email")

            role = Role.create(db, data)
            logger.info(f"Role created successfully: {role.email}")
            return role

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to create role: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_by_email(db: Session, email: str):
        """Get role by email"""
        try:
            role = Role.get(db, {"email": email})
            if not role:
                raise HTTPException(status_code=404, detail="Role not found")
            return role

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch role {email}: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_all(db: Session, skip: int = 0, limit: int = 100):
        """Get all roles"""
        try:
            roles = Role.find(db, skip=skip, limit=limit)
            total = Role.count(db)

            logger.info(f"Retrieved {len(roles)} roles")
            return {
                "items": roles,
                "total": total
            }

        except Exception as e:
            logger.error(f"Failed to fetch roles: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def update(db: Session, email: str, data: dict):
        """Update role"""
        try:
            logger.info(f"Updating role: {email}")

            exists = Role.get(db, {"email": email})
            if not exists:
                raise HTTPException(status_code=404, detail="Role not found")

            updated = Role.update(db, {"email": email}, data)
            if not updated:
                raise HTTPException(
                    status_code=500, detail="Role update failed")

            logger.info(f"Role updated successfully: {email}")
            return Role.get(db, {"email": email})

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to update role {email}: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def delete(db: Session, email: str):
        """Delete role"""
        try:
            logger.info(f"Deleting role: {email}")

            deleted = Role.delete(db, {"email": email})
            if not deleted:
                raise HTTPException(status_code=404, detail="Role not found")

            logger.info(f"Role deleted successfully: {email}")
            return {"detail": "Role deleted successfully"}

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to delete role {email}: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def bulk_create(db: Session, roles_data: list):
        """Bulk create or update roles from CSV"""
        try:
            created = 0
            updated = 0

            for role_data in roles_data:
                email = role_data.get("email")
                existing = Role.get(db, {"email": email})

                if existing:
                    Role.update(db, {"email": email}, role_data)
                    updated += 1
                else:
                    Role.create(db, role_data)
                    created += 1

            logger.info(
                f"Bulk role operation: {created} created, {updated} updated")
            return {
                "detail": f"Successfully processed {len(roles_data)} roles",
                "created": created,
                "updated": updated
            }

        except Exception as e:
            logger.error(f"Failed to bulk create roles: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")
