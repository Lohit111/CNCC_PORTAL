"""Request Controller - Handles all business logic for Request model"""
from fastapi import HTTPException
from sqlalchemy.orm import Session
from models.request import Request
from models.comment import RequestComment
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

            request = Request.create(db, data)
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
    def update(db: Session, request_id: str, data: dict):
        """Update request"""
        try:
            logger.info(f"Updating request: {request_id}")

            exists = Request.get(db, {"id": request_id})
            if not exists:
                raise HTTPException(
                    status_code=404, detail="Request not found")

            updated = Request.update(db, {"id": request_id}, data)
            if not updated:
                raise HTTPException(
                    status_code=500, detail="Request update failed")

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

            # Delete related comments
            RequestComment.delete_all(db, {"request_id": request_id})

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
    def add_comment(db: Session, request_id: str, comment_data: dict):
        """Add a comment to a request"""
        try:
            # Verify request exists
            request = Request.get(db, {"id": request_id})
            if not request:
                raise HTTPException(
                    status_code=404, detail="Request not found")

            comment_data["request_id"] = request_id
            comment = RequestComment.create(db, comment_data)

            logger.info(f"Comment added to request {request_id}")
            return comment

        except HTTPException:
            raise
        except Exception as e:
            logger.error(
                f"Failed to add comment to request {request_id}: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_comments(db: Session, request_id: str):
        """Get all comments for a request"""
        try:
            # Verify request exists
            request = Request.get(db, {"id": request_id})
            if not request:
                raise HTTPException(
                    status_code=404, detail="Request not found")

            comments = RequestComment.find(db, {"request_id": request_id})
            return comments

        except HTTPException:
            raise
        except Exception as e:
            logger.error(
                f"Failed to fetch comments for request {request_id}: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Database error: {str(e)}")
