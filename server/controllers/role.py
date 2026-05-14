"""Role Controller - Handles all business logic for Role model"""
from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_
from models.role import Role
from models.user import User, UserTable
from models.assignment import AssignmentTable
from models.request import RequestTable
from models.store_request import StoreRequestTable
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
    def _check_user_pending_work(db: Session, email: str):
        """
        Raises HTTP 409 if the user still has pending/active work:
          1. Active assignment  (assignments.is_active == True)
          2. Open request       (status NOT IN ['REJECTED', 'COMPLETED'])
          3. Open store request (status NOT IN ['REJECTED', 'FULFILLED'])
                                 AND (requested_by == user OR responded_by == user)
        """
        # Resolve email -> user id
        user = db.query(UserTable).filter(UserTable.email == email).first()
        if not user:
            # No user account yet — nothing pending, allow the role update
            return

        user_id = user.id
        blocking_reasons = []

        # 1. Active assignments
        active_assignment = (
            db.query(AssignmentTable)
            .filter(
                AssignmentTable.staff_id == user_id,
                AssignmentTable.is_active == True,  # noqa: E712
            )
            .first()
        )
        if active_assignment:
            blocking_reasons.append("user has an active assignment")

        # 2. Open requests (raised by user, not in terminal states)
        terminal_request_statuses = ["REJECTED", "COMPLETED"]
        open_request = (
            db.query(RequestTable)
            .filter(
                RequestTable.raised_by == user_id,
                RequestTable.status.notin_(terminal_request_statuses),
            )
            .first()
        )
        if open_request:
            blocking_reasons.append("user has an open request")

        # 3. Open store requests where user is requester or responder
        terminal_store_statuses = ["REJECTED", "FULFILLED"]
        open_store_request = (
            db.query(StoreRequestTable)
            .filter(
                StoreRequestTable.status.notin_(terminal_store_statuses),
                or_(
                    StoreRequestTable.requested_by == user_id,
                    StoreRequestTable.responded_by == user_id,
                ),
            )
            .first()
        )
        if open_store_request:
            blocking_reasons.append("user has an open store request")

        if blocking_reasons:
            detail = (
                "Cannot change role while user has pending work: "
                + "; ".join(blocking_reasons)
                + "."
            )
            logger.warning(f"Role update blocked for {email}: {detail}")
            raise HTTPException(status_code=409, detail=detail)

    @staticmethod
    def update(db: Session, email: str, data: dict):
        """Update role"""
        try:
            logger.info(f"Updating role: {email}")

            exists = Role.get(db, {"email": email})
            if not exists:
                raise HTTPException(status_code=404, detail="Role not found")

            # Block the update if user has any pending/active work
            RoleController._check_user_pending_work(db, email)

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
