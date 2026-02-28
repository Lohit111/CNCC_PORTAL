"""Assignment Controller - Handles business logic for Assignment model"""
from fastapi import HTTPException
from sqlalchemy.orm import Session
from models.assignment import Assignment
from models.request import Request
from models.user import User
import logging

logger = logging.getLogger(__name__)


class AssignmentController:
    @staticmethod
    def create(db: Session, data: dict):
        """Create a new assignment"""
        try:
            # Verify request exists
            request = Request.get(db, {"id": data.get("request_id")})
            if not request:
                raise HTTPException(status_code=404, detail="Request not found")
            
            # Verify staff user exists
            staff = User.get(db, {"id": data.get("staff_id")})
            if not staff:
                raise HTTPException(status_code=404, detail="Staff user not found")
            
            # Deactivate previous assignments for this request
            Assignment.update(db, {"request_id": data.get("request_id"), "is_active": True}, {"is_active": False})
            
            assignment = Assignment.create(db, data)
            logger.info(f"Assignment created successfully: {assignment.id}")
            return assignment
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to create assignment: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_by_id(db: Session, assignment_id: int):
        """Get assignment by ID"""
        try:
            assignment = Assignment.get(db, {"id": assignment_id})
            if not assignment:
                raise HTTPException(status_code=404, detail="Assignment not found")
            return assignment
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch assignment {assignment_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_by_request(db: Session, request_id: str):
        """Get all assignments for a request"""
        try:
            assignments = Assignment.find(db, {"request_id": request_id})
            return assignments
        
        except Exception as e:
            logger.error(f"Failed to fetch assignments for request {request_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_by_staff(db: Session, staff_id: str, active_only: bool = True):
        """Get all assignments for a staff member"""
        try:
            filter_dict = {"staff_id": staff_id}
            if active_only:
                filter_dict["is_active"] = True
            
            assignments = Assignment.find(db, filter_dict)
            return assignments
        
        except Exception as e:
            logger.error(f"Failed to fetch assignments for staff {staff_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def update(db: Session, assignment_id: int, data: dict):
        """Update assignment"""
        try:
            logger.info(f"Updating assignment: {assignment_id}")
            
            exists = Assignment.get(db, {"id": assignment_id})
            if not exists:
                raise HTTPException(status_code=404, detail="Assignment not found")
            
            updated = Assignment.update(db, {"id": assignment_id}, data)
            if not updated:
                raise HTTPException(status_code=500, detail="Assignment update failed")
            
            logger.info(f"Assignment updated successfully: {assignment_id}")
            return Assignment.get(db, {"id": assignment_id})
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to update assignment {assignment_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def delete(db: Session, assignment_id: int):
        """Delete assignment"""
        try:
            logger.info(f"Deleting assignment: {assignment_id}")
            
            deleted = Assignment.delete(db, {"id": assignment_id})
            if not deleted:
                raise HTTPException(status_code=404, detail="Assignment not found")
            
            logger.info(f"Assignment deleted successfully: {assignment_id}")
            return {"detail": "Assignment deleted successfully"}
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to delete assignment {assignment_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
