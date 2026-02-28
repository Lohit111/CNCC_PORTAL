"""Request Endpoints"""
from fastapi import APIRouter, Request, Depends, Query
from sqlalchemy.orm import Session
from typing import List
from config.database import get_db
from middleware.auth import require_role
from controllers.request import RequestController
from models.request import Request as RequestModel

router = APIRouter()


@router.get("/", response_model=dict)
async def get_all_requests(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    auth_data: dict = Depends(require_role("ADMIN", "STAFF")),
    db: Session = Depends(get_db)
):
    """Get all requests with pagination"""
    return RequestController.get_all(db, skip=skip, limit=limit)


@router.get("/{request_id}", response_model=RequestModel)
async def get_request_by_id(
    request_id: str,
    auth_data: dict = Depends(require_role("USER", "ADMIN", "STAFF", "STORE")),
    db: Session = Depends(get_db)
):
    """Get request by ID"""
    return RequestController.get_by_id(db, request_id)


@router.post("/", response_model=RequestModel)
async def create_request(
    request: Request,
    auth_data: dict = Depends(require_role("USER")),
    db: Session = Depends(get_db)
):
    """Create a new request"""
    data = await request.json()
    data["raised_by"] = auth_data["user"].id
    data["status"] = "RAISED"
    return RequestController.create(db, data)


@router.put("/{request_id}", response_model=RequestModel)
async def update_request(
    request_id: str,
    request: Request,
    auth_data: dict = Depends(require_role("ADMIN", "STAFF")),
    db: Session = Depends(get_db)
):
    """Update request"""
    data = await request.json()
    return RequestController.update(db, request_id, data)


@router.delete("/{request_id}")
async def delete_request(
    request_id: str,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Delete request"""
    return RequestController.delete(db, request_id)


@router.post("/{request_id}/comments")
async def add_comment(
    request_id: str,
    request: Request,
    auth_data: dict = Depends(require_role("USER", "ADMIN", "STAFF", "STORE")),
    db: Session = Depends(get_db)
):
    """Add a comment to a request"""
    data = await request.json()
    data["sender_id"] = auth_data["user"].id
    data["sender_role"] = auth_data["role"]
    return RequestController.add_comment(db, request_id, data)


@router.get("/{request_id}/comments")
async def get_request_comments(
    request_id: str,
    auth_data: dict = Depends(require_role("USER", "ADMIN", "STAFF", "STORE")),
    db: Session = Depends(get_db)
):
    """Get all comments for a request"""
    return RequestController.get_comments(db, request_id)
