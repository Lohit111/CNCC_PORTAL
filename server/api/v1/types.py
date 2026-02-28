"""Request Type Endpoints"""
from fastapi import APIRouter, Request, Depends
from sqlalchemy.orm import Session
from typing import List
from config.database import get_db
from middleware.auth import require_role
from controllers.request_type import MainTypeController, SubTypeController
from models.request_type import MainType, SubType

router = APIRouter()


# Main Type Endpoints
@router.get("/main", response_model=List[MainType])
async def get_all_main_types(
    auth_data: dict = Depends(require_role("USER", "ADMIN", "STAFF", "STORE")),
    db: Session = Depends(get_db)
):
    """Get all main types"""
    return MainTypeController.get_all(db)


@router.get("/main/{main_type_id}", response_model=MainType)
async def get_main_type_by_id(
    main_type_id: int,
    auth_data: dict = Depends(require_role("USER", "ADMIN", "STAFF", "STORE")),
    db: Session = Depends(get_db)
):
    """Get main type by ID"""
    return MainTypeController.get_by_id(db, main_type_id)


@router.post("/main", response_model=MainType)
async def create_main_type(
    request: Request,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Create a new main type"""
    data = await request.json()
    data["created_by"] = auth_data["user"].id
    return MainTypeController.create(db, data)


@router.put("/main/{main_type_id}", response_model=MainType)
async def update_main_type(
    main_type_id: int,
    request: Request,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Update main type"""
    data = await request.json()
    return MainTypeController.update(db, main_type_id, data)


@router.delete("/main/{main_type_id}")
async def delete_main_type(
    main_type_id: int,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Delete main type"""
    return MainTypeController.delete(db, main_type_id)


# Sub Type Endpoints
@router.get("/main/{main_type_id}/sub", response_model=List[SubType])
async def get_sub_types_by_main_type(
    main_type_id: int,
    auth_data: dict = Depends(require_role("USER", "ADMIN", "STAFF", "STORE")),
    db: Session = Depends(get_db)
):
    """Get all sub types for a main type"""
    return SubTypeController.get_by_main_type(db, main_type_id)


@router.get("/sub/{sub_type_id}", response_model=SubType)
async def get_sub_type_by_id(
    sub_type_id: int,
    auth_data: dict = Depends(require_role("USER", "ADMIN", "STAFF", "STORE")),
    db: Session = Depends(get_db)
):
    """Get sub type by ID"""
    return SubTypeController.get_by_id(db, sub_type_id)


@router.post("/sub", response_model=SubType)
async def create_sub_type(
    request: Request,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Create a new sub type"""
    data = await request.json()
    return SubTypeController.create(db, data)


@router.put("/sub/{sub_type_id}", response_model=SubType)
async def update_sub_type(
    sub_type_id: int,
    request: Request,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Update sub type"""
    data = await request.json()
    return SubTypeController.update(db, sub_type_id, data)


@router.delete("/sub/{sub_type_id}")
async def delete_sub_type(
    sub_type_id: int,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Delete sub type"""
    return SubTypeController.delete(db, sub_type_id)
