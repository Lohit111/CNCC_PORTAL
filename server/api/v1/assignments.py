"""Assignment Endpoints"""
from fastapi import APIRouter, Request, Depends, Query
from sqlalchemy.orm import Session
from typing import List
from config.database import get_db
from middleware.auth import require_role
from controllers.assignment import AssignmentController
from models.assignment import Assignment

router = APIRouter()


@router.get("/request/{request_id}", response_model=List[Assignment])
async def get_assignments_by_request(
    request_id: str,
    auth_data: dict = Depends(require_role("ADMIN", "STAFF")),
    db: Session = Depends(get_db)
):
    """Get all assignments for a request"""
    return AssignmentController.get_by_request(db, request_id)


@router.get("/staff/{staff_id}", response_model=List[Assignment])
async def get_assignments_by_staff(
    staff_id: str,
    active_only: bool = Query(True),
    auth_data: dict = Depends(require_role("ADMIN", "STAFF")),
    db: Session = Depends(get_db)
):
    """Get all assignments for a staff member"""
    return AssignmentController.get_by_staff(db, staff_id, active_only)


@router.get("/{assignment_id}", response_model=Assignment)
async def get_assignment_by_id(
    assignment_id: int,
    auth_data: dict = Depends(require_role("ADMIN", "STAFF")),
    db: Session = Depends(get_db)
):
    """Get assignment by ID"""
    return AssignmentController.get_by_id(db, assignment_id)


@router.post("/", response_model=Assignment)
async def create_assignment(
    request: Request,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Create a new assignment"""
    data = await request.json()
    data["assigned_by"] = auth_data["user"].id
    return AssignmentController.create(db, data)


@router.put("/{assignment_id}", response_model=Assignment)
async def update_assignment(
    assignment_id: int,
    request: Request,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Update assignment"""
    data = await request.json()
    return AssignmentController.update(db, assignment_id, data)


@router.delete("/{assignment_id}")
async def delete_assignment(
    assignment_id: int,
    auth_data: dict = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """Delete assignment"""
    return AssignmentController.delete(db, assignment_id)
