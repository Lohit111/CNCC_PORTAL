"""Store Request Endpoints"""
from fastapi import APIRouter, Request, Depends, Query
from sqlalchemy.orm import Session
from typing import List
from config.database import get_db
from middleware.auth import require_role
from controllers.store_request import StoreRequestController
from models.store_request import StoreRequest

router = APIRouter()


@router.get("/", response_model=dict)
async def get_all_store_requests(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    auth_data: dict = Depends(require_role("STORE", "ADMIN", "STAFF")),
    db: Session = Depends(get_db)
):
    """Get all store requests"""
    return StoreRequestController.get_all(db, skip=skip, limit=limit)


@router.get("/status/{status}", response_model=dict)
async def get_store_requests_by_status(
    status: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    auth_data: dict = Depends(require_role("STORE", "ADMIN")),
    db: Session = Depends(get_db)
):
    """Get store requests by status"""
    return StoreRequestController.get_by_status(db, status, skip=skip, limit=limit)


@router.get("/parent/{parent_request_id}", response_model=List[StoreRequest])
async def get_store_requests_by_parent(
    parent_request_id: str,
    auth_data: dict = Depends(require_role("STAFF", "STORE", "ADMIN")),
    db: Session = Depends(get_db)
):
    """Get all store requests for a parent request"""
    return StoreRequestController.get_by_parent_request(db, parent_request_id)


@router.get("/{store_request_id}", response_model=StoreRequest)
async def get_store_request_by_id(
    store_request_id: str,
    auth_data: dict = Depends(require_role("STAFF", "STORE", "ADMIN")),
    db: Session = Depends(get_db)
):
    """Get store request by ID"""
    return StoreRequestController.get_by_id(db, store_request_id)


@router.post("/", response_model=StoreRequest)
async def create_store_request(
    request: Request,
    auth_data: dict = Depends(require_role("STAFF")),
    db: Session = Depends(get_db)
):
    """Create a new store request"""
    data = await request.json()
    data["requested_by"] = auth_data["user"].id
    data["status"] = "PENDING"
    return StoreRequestController.create(db, data)


@router.put("/{store_request_id}", response_model=StoreRequest)
async def update_store_request(
    store_request_id: str,
    request: Request,
    auth_data: dict = Depends(require_role("STORE", "ADMIN")),
    db: Session = Depends(get_db)
):
    """Update store request"""
    data = await request.json()
    return StoreRequestController.update(db, store_request_id, data)


@router.post("/{store_request_id}/respond", response_model=StoreRequest)
async def respond_to_store_request(
    store_request_id: str,
    request: Request,
    auth_data: dict = Depends(require_role("STORE")),
    db: Session = Depends(get_db)
):
    """Respond to a store request (approve/reject/fulfill)"""
    data = await request.json()
    status = data.get("status")
    response_comment = data.get("response_comment")

    return StoreRequestController.respond(
        db,
        store_request_id,
        auth_data["user"].id,
        status,
        response_comment
    )


@router.delete("/{store_request_id}")
async def delete_store_request(
    store_request_id: str,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Delete store request"""
    return StoreRequestController.delete(db, store_request_id)


@router.post("/{store_request_id}/chat")
async def add_chat_message(
    store_request_id: str,
    request: Request,
    auth_data: dict = Depends(require_role("STAFF", "STORE")),
    db: Session = Depends(get_db)
):
    """Add a chat message to an APPROVED store request"""
    data = await request.json()
    message = data.get("message")

    return StoreRequestController.add_chat_message(
        db,
        store_request_id,
        auth_data["user"].id,
        auth_data["role"],
        message
    )


@router.get("/{store_request_id}/chat")
async def get_chat_messages(
    store_request_id: str,
    auth_data: dict = Depends(require_role("STAFF", "STORE", "ADMIN")),
    db: Session = Depends(get_db)
):
    """Get all chat messages for a store request"""
    return StoreRequestController.get_chat_messages(db, store_request_id)
