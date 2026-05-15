"""Request Controller - Handles all business logic for Request model"""
from fastapi import HTTPException
from sqlalchemy.orm import Session
from models.request import Request, RequestTable
from models.track import RequestTrack
from models.assignment import Assignment
from models.store_request import StoreRequest
from models.request_type import MainType, SubType
from models.user import User
import logging
import math

logger = logging.getLogger(__name__)


class RequestController:
    @staticmethod
    def create(db: Session, data: dict):
        """Create a new request"""
        try:
            # Validate main_type and sub_type exist
            main_type = MainType.get(db, {"id": data.get("main_type_id")})
            if not main_type:
                raise HTTPException(
                    status_code=404, detail="Main type not found")

            sub_type = SubType.get(db, {"id": data.get("sub_type_id")})
            if not sub_type:
                raise HTTPException(
                    status_code=404, detail="Sub type not found")

            if sub_type.main_type_id != main_type.id:
                raise HTTPException(
                    status_code=400, detail="Sub type does not belong to main type")

            # Extract role before passing data to the model (not a table column)
            raised_by_role = data.pop("raised_by_role", "USER")

            request = Request.create(db, data)

            # Create initial track for request creation
            RequestTrack.create(db, {
                "request_id": request.id,
                "action_type": "RAISED",
                "performed_by": data.get("raised_by"),
                "performed_by_role": raised_by_role,
                "comment": None,
            })

            logger.info(f"Request created successfully: {request.id}")
            return request

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to create request: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_by_id(db: Session, request_id: str):
        """Get request by ID"""
        try:
            request = Request.get(db, {"id": request_id})
            if not request:
                raise HTTPException(
                    status_code=404, detail="Request not found")
            return request

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch request {request_id}: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_all(db: Session, skip: int = 0, limit: int = 20):
        """Get all requests with pagination"""
        try:
            total = Request.count(db)
            requests = Request.find(db, skip=skip, limit=limit)
            total_pages = math.ceil(total / limit) if total > 0 else 0

            logger.info(f"Retrieved {len(requests)} requests")
            return {
                "items": requests,
                "total": total,
                "page": (skip // limit) + 1,
                "page_size": limit,
                "total_pages": total_pages
            }

        except Exception as e:
            logger.error(f"Failed to fetch requests: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_by_user(db: Session, user_id: str, skip: int = 0, limit: int = 20):
        """Get requests raised by a specific user"""
        try:
            filter_dict = {"raised_by": user_id}
            total = Request.count(db, filter_dict)
            requests = Request.find(
                db, filter=filter_dict, skip=skip, limit=limit)
            total_pages = math.ceil(total / limit) if total > 0 else 0

            return {
                "items": requests,
                "total": total,
                "page": (skip // limit) + 1,
                "page_size": limit,
                "total_pages": total_pages
            }

        except Exception as e:
            logger.error(f"Failed to fetch user requests: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def update(db: Session, request_id: str, data: dict, user_id: str = None, user_role: str = None):
        """Update request and automatically create track for status changes"""
        try:
            logger.info(f"Updating request: {request_id}")

            new_status = data.get("status")

            # For status transitions that are vulnerable to race conditions,
            # acquire a row-level lock (SELECT FOR UPDATE) so only one
            # concurrent request can proceed through the check-then-act.
            if new_status in ("IN_PROGRESS", "REASSIGN_REQUESTED"):
                locked_row = (
                    db.query(RequestTable)
                    .filter(RequestTable.id == request_id)
                    .with_for_update()
                    .first()
                )
                if locked_row is None:
                    raise HTTPException(
                        status_code=404, detail="Request not found")
                existing_request = Request.from_orm(locked_row)
            else:
                existing_request = Request.get(db, {"id": request_id})
                if not existing_request:
                    raise HTTPException(
                        status_code=404, detail="Request not found")

            # Check if status is changing
            old_status = existing_request.status
            new_status = data.get("status", old_status)
            status_changed = old_status != new_status

            # Block completion if there are active store requests
            if new_status == "COMPLETED" and status_changed:
                from models.store_request import StoreRequestTable
                from models.user import UserTable
                active_rows = (
                    db.query(
                        StoreRequestTable.id,
                        StoreRequestTable.description,
                        StoreRequestTable.status,
                        UserTable.email.label("requested_by_email"),
                    )
                    .join(UserTable, UserTable.id == StoreRequestTable.requested_by)
                    .filter(
                        StoreRequestTable.parent_request_id == request_id,
                        StoreRequestTable.status.notin_(
                            ["REJECTED", "FULFILLED"]),
                    )
                    .all()
                )
                if active_rows:
                    pending = [
                        {
                            "id": row.id,
                            "description": row.description,
                            "status": row.status,
                            "requested_by": row.requested_by_email,
                        }
                        for row in active_rows
                    ]
                    raise HTTPException(
                        status_code=400,
                        detail={
                            "message": f"Cannot complete request: {len(pending)} store request(s) are still pending. Ensure all store requests are fulfilled or rejected first.",
                            "pending_store_requests": pending,
                        },
                    )

            # Guard against race conditions: IN_PROGRESS and REASSIGN_REQUESTED
            # are only valid transitions from ASSIGNED state
            if new_status in ("IN_PROGRESS", "REASSIGN_REQUESTED") and status_changed:
                if old_status != "ASSIGNED":
                    raise HTTPException(
                        status_code=409,
                        detail=f"Cannot set status to {new_status}: request is no longer in ASSIGNED state (current: {old_status}). Please refresh and try again."
                    )

            # Deactivate all assignments when reassignment is requested or ending a request
            if (new_status in ["REASSIGN_REQUESTED", "COMPLETED", "REJECTED"]) and status_changed:
                Assignment.update(
                    db,
                    {"request_id": request_id, "is_active": True},
                    {"is_active": False}
                )

            # Extract comment for track (not a request table column)
            comment = data.pop("comment", None)

            # Update the request
            updated = Request.update(db, {"id": request_id}, data)
            if not updated:
                raise HTTPException(
                    status_code=500, detail="Request update failed")

            # If status changed, create a track entry automatically
            if status_changed and user_id and user_role:
                # Determine action type based on new status
                action_type = new_status  # Default to status name

                RequestTrack.create(db, {
                    "request_id": request_id,
                    "action_type": action_type,
                    "performed_by": user_id,
                    "performed_by_role": user_role,
                    "comment": comment,
                })

                logger.info(
                    f"Track created for status change: {old_status} -> {new_status}")

            logger.info(f"Request updated successfully: {request_id}")
            return Request.get(db, {"id": request_id})

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to update request {request_id}: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def delete(db: Session, request_id: str):
        """Delete request and all related data"""
        try:
            logger.info(f"Deleting request: {request_id}")

            # Delete related tracks
            RequestTrack.delete_all(db, {"request_id": request_id})

            # Delete related assignments
            Assignment.delete_all(db, {"request_id": request_id})

            # Delete related store requests
            StoreRequest.delete_all(db, {"parent_request_id": request_id})

            # Delete the request itself
            deleted = Request.delete(db, {"id": request_id})
            if not deleted:
                raise HTTPException(
                    status_code=404, detail="Request not found")

            logger.info(f"Request deleted successfully: {request_id}")
            return {"detail": "Request deleted successfully"}

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to delete request {request_id}: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_timeline(db: Session, request_id: str):
        """Get all tracks for a request (timeline)"""
        try:
            # Verify request exists
            request = Request.get(db, {"id": request_id})
            if not request:
                raise HTTPException(
                    status_code=404, detail="Request not found")

            tracks = RequestTrack.find(db, {"request_id": request_id})
            return tracks

        except HTTPException:
            raise
        except Exception as e:
            logger.error(
                f"Failed to fetch tracks for request {request_id}: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")
