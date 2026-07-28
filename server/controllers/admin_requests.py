"""Admin Requests Controller"""
from typing import List
from sqlalchemy.orm import Session
from sqlalchemy import or_
from fastapi import HTTPException
from models.request import Request, RequestTable
from models.track import RequestTrack, RequestTrackTable
from models.assignment import Assignment
from models.store_request import StoreRequest
from models.store_chat import StoreChat
from models.user import User
from models.enums import RequestStatus, TrackEventType


PAGE_SIZE = 30


def _build_request_detail(db: Session, request: Request) -> dict:
    """Build full request detail with timeline, assignments, store_requests, and users map"""
    timeline = RequestTrack.find(db, {"request_id": request.id})
    assignments = Assignment.find(db, {"request_id": request.id})
    store_requests = StoreRequest.find(db, {"parent_request_id": request.id})

    uid_set = set()
    uid_set.add(request.raised_by)
    for track in timeline:
        uid_set.add(track.performed_by)
    for assignment in assignments:
        uid_set.add(assignment.staff_id)
    for sr in store_requests:
        uid_set.add(sr.requested_by)
        if sr.responded_by:
            uid_set.add(sr.responded_by)

    users_map = {}
    for uid in uid_set:
        user = User.get(db, {"id": uid})
        if user:
            users_map[uid] = user.model_dump()

    return {
        "request": request.model_dump(),
        "timeline": [t.model_dump() for t in timeline],
        "assignments": [a.model_dump() for a in assignments],
        "store_requests": [sr.model_dump() for sr in store_requests],
        "users": users_map
    }


def _query_requests(db: Session, statuses: list, page: int) -> dict:
    """Filtered, paginated DB query for requests by status"""
    query = db.query(RequestTable).filter(
        RequestTable.status.in_(statuses)
    ).order_by(RequestTable.created_at.desc())

    total = query.count()
    skip = (page - 1) * PAGE_SIZE
    rows = query.offset(skip).limit(PAGE_SIZE).all()
    requests = [Request.from_orm(r) for r in rows]

    return {
        "requests": [_build_request_detail(db, r) for r in requests],
        "total": total,
        "page": page,
        "pages": -(-total // PAGE_SIZE)
    }


# --- GET endpoints ---

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


def get_archive(db: Session, page: int) -> dict:
    return _query_requests(db, [RequestStatus.COMPLETED, RequestStatus.REJECTED], page)


# --- PUT action endpoints ---

def reply_to_request(db: Session, admin: User, request_id: str, comment: str) -> bool:
    """Set request status to REPLIED and create a track entry"""
    request = Request.get(db, {"id": request_id})
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")

    Request.update(db, {"id": request_id}, {"status": RequestStatus.REPLIED})
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.REPLIED,
        "performed_by": admin.id,
        "performed_by_role": admin.role,
        "comment": comment
    })
    db.commit()
    return True


def assign_request(db: Session, admin: User, request_id: str, staff_ids: List[str]) -> bool:
    """
    Assign a request to one or more staff members.
    Creates one ASSIGNED track entry, one assignment per staff_id (all linked to that track),
    and updates request status — all in a single transaction.
    """
    request = Request.get(db, {"id": request_id})
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")

    if not staff_ids:
        raise HTTPException(
            status_code=400, detail="At least one staff_id is required")

    # Validate all staff users exist and have STAFF role
    from models.enums import UserRole
    for staff_id in staff_ids:
        staff = User.get(db, {"id": staff_id})
        if not staff:
            raise HTTPException(
                status_code=404, detail=f"Staff user {staff_id} not found")
        if staff.role != UserRole.STAFF:
            raise HTTPException(
                status_code=400, detail=f"User {staff_id} is not a STAFF member")

    # Create track entry first so we have its ID for assignments
    track = RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.ASSIGNED,
        "performed_by": admin.id,
        "performed_by_role": admin.role,
        "comment": None
    })

    # Create one assignment per staff member linked to this track
    for staff_id in staff_ids:
        Assignment.create(db, {
            "request_id": request_id,
            "staff_id": staff_id,
            "track_id": track.id
        })

    # Update request status
    Request.update(db, {"id": request_id}, {"status": RequestStatus.ASSIGNED})
    db.commit()
    return True


def reject_request(db: Session, admin: User, request_id: str, comment: str) -> bool:
    """Set request status to REJECTED and create a track entry"""
    request = Request.get(db, {"id": request_id})
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")

    Request.update(db, {"id": request_id}, {"status": RequestStatus.REJECTED})
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.REJECTED,
        "performed_by": admin.id,
        "performed_by_role": admin.role,
        "comment": comment
    })
    db.commit()
    return True


# --- DELETE endpoints ---

def delete_request(db: Session, request_id: str) -> bool:
    """
    Delete a request and all its related data:
    tracks, assignments, store_requests (and their chats)
    Cascade relationships handle most of this, but store chats need explicit deletion
    since they hang off store_requests not requests directly.
    """
    request = Request.get(db, {"id": request_id})
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")

    # Delete store chats first (not directly cascaded from request)
    store_requests = StoreRequest.find(db, {"parent_request_id": request_id})
    for sr in store_requests:
        StoreChat.delete_all(db, {"store_request_id": sr.id})

    # Delete the request — cascades to tracks, assignments, store_requests
    Request.delete(db, {"id": request_id})
    db.commit()
    return True


def delete_store_request(db: Session, store_request_id: str) -> bool:
    """Delete a store request and its chat messages"""
    sr = StoreRequest.get(db, {"id": store_request_id})
    if not sr:
        raise HTTPException(status_code=404, detail="Store request not found")

    StoreChat.delete_all(db, {"store_request_id": store_request_id})
    StoreRequest.delete(db, {"id": store_request_id})
    db.commit()
    return True
