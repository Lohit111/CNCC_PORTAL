"""Request Type Controller - Handles business logic for MainType and SubType"""
from fastapi import HTTPException
from sqlalchemy.orm import Session
from models.request_type import MainType, SubType
import logging

logger = logging.getLogger(__name__)


class MainTypeController:
    @staticmethod
    def create(db: Session, data: dict):
        """Create a new main type"""
        try:
            # Check for duplicate name
            existing = MainType.get(db, {"name": data.get("name")})
            if existing:
                raise HTTPException(status_code=409, detail="Main type with this name already exists")
            
            main_type = MainType.create(db, data)
            logger.info(f"Main type created successfully: {main_type.id}")
            return main_type
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to create main type: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_by_id(db: Session, main_type_id: int):
        """Get main type by ID"""
        try:
            main_type = MainType.get(db, {"id": main_type_id})
            if not main_type:
                raise HTTPException(status_code=404, detail="Main type not found")
            return main_type
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch main type {main_type_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_all(db: Session):
        """Get all main types"""
        try:
            main_types = MainType.find(db)
            logger.info(f"Retrieved {len(main_types)} main types")
            return main_types
        
        except Exception as e:
            logger.error(f"Failed to fetch main types: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def update(db: Session, main_type_id: int, data: dict):
        """Update main type"""
        try:
            logger.info(f"Updating main type: {main_type_id}")
            
            exists = MainType.get(db, {"id": main_type_id})
            if not exists:
                raise HTTPException(status_code=404, detail="Main type not found")
            
            updated = MainType.update(db, {"id": main_type_id}, data)
            if not updated:
                raise HTTPException(status_code=500, detail="Main type update failed")
            
            logger.info(f"Main type updated successfully: {main_type_id}")
            return MainType.get(db, {"id": main_type_id})
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to update main type {main_type_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def delete(db: Session, main_type_id: int):
        """Delete main type"""
        try:
            logger.info(f"Deleting main type: {main_type_id}")
            
            # Delete all sub types first
            SubType.delete_all(db, {"main_type_id": main_type_id})
            
            deleted = MainType.delete(db, {"id": main_type_id})
            if not deleted:
                raise HTTPException(status_code=404, detail="Main type not found")
            
            logger.info(f"Main type deleted successfully: {main_type_id}")
            return {"detail": "Main type deleted successfully"}
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to delete main type {main_type_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


class SubTypeController:
    @staticmethod
    def create(db: Session, data: dict):
        """Create a new sub type"""
        try:
            # Verify main type exists
            main_type = MainType.get(db, {"id": data.get("main_type_id")})
            if not main_type:
                raise HTTPException(status_code=404, detail="Main type not found")
            
            sub_type = SubType.create(db, data)
            logger.info(f"Sub type created successfully: {sub_type.id}")
            return sub_type
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to create sub type: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_by_id(db: Session, sub_type_id: int):
        """Get sub type by ID"""
        try:
            sub_type = SubType.get(db, {"id": sub_type_id})
            if not sub_type:
                raise HTTPException(status_code=404, detail="Sub type not found")
            return sub_type
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch sub type {sub_type_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def get_by_main_type(db: Session, main_type_id: int):
        """Get all sub types for a main type"""
        try:
            # Verify main type exists
            main_type = MainType.get(db, {"id": main_type_id})
            if not main_type:
                raise HTTPException(status_code=404, detail="Main type not found")
            
            sub_types = SubType.find(db, {"main_type_id": main_type_id})
            logger.info(f"Retrieved {len(sub_types)} sub types for main type {main_type_id}")
            return sub_types
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch sub types: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def update(db: Session, sub_type_id: int, data: dict):
        """Update sub type"""
        try:
            logger.info(f"Updating sub type: {sub_type_id}")
            
            exists = SubType.get(db, {"id": sub_type_id})
            if not exists:
                raise HTTPException(status_code=404, detail="Sub type not found")
            
            updated = SubType.update(db, {"id": sub_type_id}, data)
            if not updated:
                raise HTTPException(status_code=500, detail="Sub type update failed")
            
            logger.info(f"Sub type updated successfully: {sub_type_id}")
            return SubType.get(db, {"id": sub_type_id})
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to update sub type {sub_type_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    @staticmethod
    def delete(db: Session, sub_type_id: int):
        """Delete sub type"""
        try:
            logger.info(f"Deleting sub type: {sub_type_id}")
            
            deleted = SubType.delete(db, {"id": sub_type_id})
            if not deleted:
                raise HTTPException(status_code=404, detail="Sub type not found")
            
            logger.info(f"Sub type deleted successfully: {sub_type_id}")
            return {"detail": "Sub type deleted successfully"}
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to delete sub type {sub_type_id}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
