"""Store Request Controller - Handles business logic for StoreRequest model"""
from fastapi import HTTPException
from sqlalchemy.orm import Session
from models.store_request import StoreRequest
from models.request import Request
from models.user import User
import logging

logger = logging.getLogger(__name__)


class StoreRequestController:
    @staticmethod
    def create(db: Session, data: dict):
        """Create a new store request"""
        try:
            # Verify parent request exists
            parent_request = Request.get(db, {"id": data.get("parent_request_id")})
            if not parent_request:
                raise HTTPException(status_code=404, detail="Parent request not found")
            
            store_request = StoreRequest.create(db, data)
            logger.info(f"Store request created successfully: {store_request.id}")
            return store_request
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to create store request: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_by_id(db: Session, store_request_id: str):
        """Get store request by ID"""
        try:
            store_request = StoreRequest.get(db, {"id": store_request_id})
            if not store_request:
                raise HTTPException(status_code=404, detail="Store request not found")
            return store_request
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch store request {store_request_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_all(db: Session, skip: int = 0, limit: int = 20):
        """Get all store requests"""
        try:
            store_requests = StoreRequest.find(db, skip=skip, limit=limit)
            total = StoreRequest.count(db)
            
            logger.info(f"Retrieved {len(store_requests)} store requests")
            return {
                "items": store_requests,
                "total": total
            }
        
        except Exception as e:
            logger.error(f"Failed to fetch store requests: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_by_status(db: Session, status: str, skip: int = 0, limit: int = 20):
        """Get store requests by status"""
        try:
            filter_dict = {"status": status}
            store_requests = StoreRequest.find(db, filter=filter_dict, skip=skip, limit=limit)
            total = StoreRequest.count(db, filter_dict)
            
            return {
                "items": store_requests,
                "total": total
            }
        
        except Exception as e:
            logger.error(f"Failed to fetch store requests by status: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_by_parent_request(db: Session, parent_request_id: str):
        """Get all store requests for a parent request"""
        try:
            store_requests = StoreRequest.find(db, {"parent_request_id": parent_request_id})
            return store_requests
        
        except Exception as e:
            logger.error(f"Failed to fetch store requests for parent {parent_request_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def update(db: Session, store_request_id: str, data: dict):
        """Update store request"""
        try:
            logger.info(f"Updating store request: {store_request_id}")
            
            exists = StoreRequest.get(db, {"id": store_request_id})
            if not exists:
                raise HTTPException(status_code=404, detail="Store request not found")
            
            updated = StoreRequest.update(db, {"id": store_request_id}, data)
            if not updated:
                raise HTTPException(status_code=500, detail="Store request update failed")
            
            logger.info(f"Store request updated successfully: {store_request_id}")
            return StoreRequest.get(db, {"id": store_request_id})
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to update store request {store_request_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def respond(db: Session, store_request_id: str, responded_by: str, status: str, response_comment: str = None):
        """Respond to a store request (approve/reject/fulfill)"""
        try:
            logger.info(f"Responding to store request: {store_request_id}")
            
            exists = StoreRequest.get(db, {"id": store_request_id})
            if not exists:
                raise HTTPException(status_code=404, detail="Store request not found")
            
            if status not in ["APPROVED", "REJECTED", "FULFILLED"]:
                raise HTTPException(status_code=400, detail="Invalid status")
            
            data = {
                "status": status,
                "responded_by": responded_by,
                "response_comment": response_comment
            }
            
            updated = StoreRequest.update(db, {"id": store_request_id}, data)
            if not updated:
                raise HTTPException(status_code=500, detail="Store request response failed")
            
            logger.info(f"Store request responded successfully: {store_request_id}")
            return StoreRequest.get(db, {"id": store_request_id})
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to respond to store request {store_request_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def delete(db: Session, store_request_id: str):
        """Delete store request"""
        try:
            logger.info(f"Deleting store request: {store_request_id}")
            
            deleted = StoreRequest.delete(db, {"id": store_request_id})
            if not deleted:
                raise HTTPException(status_code=404, detail="Store request not found")
            
            logger.info(f"Store request deleted successfully: {store_request_id}")
            return {"detail": "Store request deleted successfully"}
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to delete store request {store_request_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
