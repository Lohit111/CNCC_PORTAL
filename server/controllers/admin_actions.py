"""Admin Requests Controller"""
from typing import List
from sqlalchemy.orm import Session
from fastapi import HTTPException
from models.request import Request, RequestTable
from models.track import RequestTrack
from models.assignment import Assignment
from models.store_request import StoreRequest
from models.store_chat import StoreChat
from models.user import User
from models.enums import RequestStatus, TrackEventType, StoreRequestStatus
from services.notification_service import send_to_uid, send_to_uids
from controllers.common.helpers import paginate_requests, truncate


# --- GET endpoints ---

def _query_requests(db: Session, statuses: list, page: int) -> dict:
    """Paginated query for requests by status list."""
    query = (
        db.query(RequestTable)
        .filter(RequestTable.status.in_(statuses))
        .order_by(RequestTable.updated_at.desc())
    )
    return paginate_requests(db, query, page)


def get_raised(db: Session, page: int) -> dict:
    return _query_requests(db, [RequestStatus.RAISED], page)


def get_replied(db: Session, page: int) -> dict:
    return _query_requests(db, [RequestStatus.REPLIED], page)


def get_assigned(db: Session, page: int) -> dict:
    return _query_requests(db, [RequestStatus.ASSIGNED], page)


def get_reassign_requested(db: Session, page: int) -> dict:
    return _query_requests(db, [RequestStatus.REASSIGN_REQUESTED], page)


def get_inprogress(db: Session, page: int) -> dict:
    return _query_requests(db, [RequestStatus.IN_PROGRESS], page)


def get_hold(db: Session, page: int) -> dict:
    return _query_requests(db, [RequestStatus.HOLD], page)


# --- EDIT endpoint ---

def edit_request(
    db: Session,
    request_id: str,
    room_no: str,
    department: str,
    sub_type: str,
) -> dict:
    """Edit request room, department, and sub_type.
    
    Args:
        db: Database session
        request_id: Request ID to edit
        room_no: New room number
        department: New department
        sub_type: New sub_type (format: 'type1-num1,type2-num2,...')
    
    Returns:
        Updated request dict with message
        
    Raises:
        HTTPException 400 if validation fails
        HTTPException 404 if request not found
    """
    from models.request_type import SubTypeTable
    from models.department import DepartmentTable

    department_exists = db.query(DepartmentTable).filter(
        DepartmentTable.department == department
    ).first()
    if not department_exists:
        raise HTTPException(
            status_code=400,
            detail=f"Department '{department}' does not exist"
        )
    
    req = Request.get_raw(db, {"id": request_id})
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    
    # Update fields
    req.room_no = room_no.strip()
    req.department = department.strip()
    req.sub_type = sub_type.strip()
    db.commit()
    
    return {"message": "Request updated successfully", "request_id": request_id}


def get_archive(db: Session, page: int) -> dict:
    return _query_requests(db, [RequestStatus.COMPLETED, RequestStatus.REJECTED], page)


# --- PUT action endpoints ---

def reply_to_request(db: Session, admin: User, request_id: str, comment: str) -> bool:
    """Set request status to REPLIED and create a track entry."""
    row = Request.get_for_update(db, {"id": request_id})
    if not row:
        raise HTTPException(status_code=404, detail="Request not found")

    if row.status != RequestStatus.RAISED:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot reply to a request in '{row.status.value}' status — only RAISED requests can be replied to"
        )

    Request.update(db, {"id": request_id}, {"status": RequestStatus.REPLIED})
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.REPLIED,
        "performed_by": admin.id,
        "performed_by_role": admin.role,
        "comment": comment
    })
    db.commit()
    send_to_uid(
        row.raised_by,
        f"{admin.name}({admin.email}) Replied to Your Request",
        f'"{truncate(comment)}" for "{truncate(row.description)}"',
        {"my_requests": "replied"}
    )
    return True


def assign_request(db: Session, admin: User, request_id: str, staff_ids: List[str]) -> bool:
    """Assign a request to one or more staff members."""
    row = Request.get_for_update(db, {"id": request_id})
    if not row:
        raise HTTPException(status_code=404, detail="Request not found")

    if not staff_ids:
        raise HTTPException(status_code=400, detail="At least one staff_id is required")

    if row.status not in [RequestStatus.RAISED, RequestStatus.REASSIGN_REQUESTED]:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot assign a request in '{row.status.value}' status — request must be RAISED, REPLIED, or REASSIGN_REQUESTED"
        )

    from models.enums import UserRole
    for staff_id in staff_ids:
        staff = User.get(db, {"id": staff_id})
        if not staff:
            raise HTTPException(status_code=404, detail=f"Staff user {staff_id} not found")
        if staff.role != UserRole.STAFF:
            raise HTTPException(status_code=400, detail=f"User {staff_id} is not a STAFF member")

    track = RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.ASSIGNED,
        "performed_by": admin.id,
        "performed_by_role": admin.role,
        "comment": None
    })

    for staff_id in staff_ids:
        Assignment.create(db, {
            "request_id": request_id,
            "staff_id": staff_id,
            "track_id": track.id
        })

    Request.update(db, {"id": request_id}, {"status": RequestStatus.ASSIGNED})
    db.commit()
    send_to_uids(
        staff_ids,
        "You Were Assigned a Request",
        f'"{truncate(row.description)}" at {row.room_no}',
        {"staff": "assigned"}
    )
    return True


def reject_request(db: Session, admin: User, request_id: str, comment: str) -> bool:
    """Reject a request, closing all assignments and open store requests."""
    row = Request.get_for_update(db, {"id": request_id})
    if not row:
        raise HTTPException(status_code=404, detail="Request not found")

    if row.status in [RequestStatus.COMPLETED, RequestStatus.REJECTED]:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot reject a request that is already '{row.status.value}'"
        )

    full_comment = comment + (
        "\n\nAn admin has closed this request forcefully."
        if row.status != RequestStatus.RAISED else ""
    )

    Assignment.update(db, {"request_id": request_id, "is_active": True}, {"is_active": False})

    open_store_requests = StoreRequest.find(db, {"parent_request_id": request_id})
    for sr in open_store_requests:
        if sr.status in [StoreRequestStatus.PENDING, StoreRequestStatus.APPROVED]:
            StoreRequest.update(
                db,
                {"id": sr.id},
                {"status": StoreRequestStatus.REJECTED, "responded_by": admin.id}
            )
            RequestTrack.create(db, {
                "request_id": request_id,
                "store_request_id": sr.id,
                "event_type": TrackEventType.STORE_REQUEST_REJECTED,
                "performed_by": admin.id,
                "performed_by_role": admin.role,
                "comment": "Rejected due to parent request being forcefully closed."
            })

    Request.update(db, {"id": request_id}, {"status": RequestStatus.REJECTED})
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.REJECTED,
        "performed_by": admin.id,
        "performed_by_role": admin.role,
        "comment": full_comment
    })
    db.commit()
    send_to_uid(
        row.raised_by,
        f"Your Request Was Closed by an Admin - {admin.name}({admin.email})",
        f'Request: "{truncate(row.description)}"\n\nReason: "{truncate(full_comment)}"',
    )
    return True


# --- DELETE endpoints ---

def delete_request(db: Session, request_id: str) -> bool:
    """Delete a request and every related row explicitly."""
    row = Request.get_raw(db, {"id": request_id})
    if not row:
        raise HTTPException(status_code=404, detail="Request not found")

    store_requests = StoreRequest.find(db, {"parent_request_id": request_id})
    for sr in store_requests:
        StoreChat.delete_all(db, {"store_request_id": sr.id})
        RequestTrack.delete_all(db, {"store_request_id": sr.id})

    StoreRequest.delete_all(db, {"parent_request_id": request_id})
    Assignment.delete_all(db, {"request_id": request_id})
    RequestTrack.delete_all(db, {"request_id": request_id})
    db.delete(row)
    db.commit()
    return True


def delete_store_request(db: Session, store_request_id: str) -> bool:
    """Delete a store request and every related row explicitly."""
    row = StoreRequest.get_raw(db, {"id": store_request_id})
    if not row:
        raise HTTPException(status_code=404, detail="Store request not found")

    StoreChat.delete_all(db, {"store_request_id": store_request_id})
    RequestTrack.delete_all(db, {"store_request_id": store_request_id})
    db.delete(row)
    db.commit()
    return True
