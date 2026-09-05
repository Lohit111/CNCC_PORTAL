"""My Requests Controller"""
from sqlalchemy.orm import Session
from fastapi import HTTPException
from models.request import Request
from models.track import RequestTrack
from models.assignment import Assignment
from models.store_request import StoreRequest
from models.user import User
from models.enums import RequestStatus, TrackEventType


PAGE_SIZE = 30


def _build_request_detail(db: Session, request: Request) -> dict:
    """Build a full request detail document with timeline, assignments, store_requests, and users map"""
    timeline = RequestTrack.find(db, {"request_id": request.id})
    assignments = Assignment.find(db, {"request_id": request.id})
    store_requests = StoreRequest.find(db, {"parent_request_id": request.id})

    # Collect all unique user IDs referenced in this request's data
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

    # Build users map: uid -> user document
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


def _paginate(db: Session, user_id: str, statuses: list, page: int) -> dict:
    """Fetch paginated requests by user and status list"""
    skip = (page - 1) * PAGE_SIZE

    # Count and fetch matching requests
    all_requests = Request.find(db, {"raised_by": user_id})
    filtered = [r for r in all_requests if r.status in statuses]
    total = len(filtered)
    page_items = filtered[skip: skip + PAGE_SIZE]

    return {
        "requests": [_build_request_detail(db, r) for r in page_items],
        "total": total,
        "page": page,
        "pages": -(-total // PAGE_SIZE)
    }


def get_raised(db: Session, user_id: str, page: int) -> dict:
    """Requests in RAISED status"""
    return _paginate(db, user_id, [RequestStatus.RAISED], page)


def get_replied(db: Session, user_id: str, page: int) -> dict:
    """Requests in REPLIED status"""
    return _paginate(db, user_id, [RequestStatus.REPLIED], page)


def get_inprogress(db: Session, user_id: str, page: int) -> dict:
    """Requests in ASSIGNED, IN_PROGRESS, or REASSIGN_REQUESTED status"""
    return _paginate(db, user_id, [
        RequestStatus.ASSIGNED,
        RequestStatus.IN_PROGRESS,
        RequestStatus.REASSIGN_REQUESTED
    ], page)


def get_archive(db: Session, user_id: str, page: int) -> dict:
    """Requests in COMPLETED or REJECTED status"""
    return _paginate(db, user_id, [
        RequestStatus.COMPLETED,
        RequestStatus.REJECTED
    ], page)


def reply_to_request(db: Session, user_id: str, request_id: str, comment: str, description: str) -> bool:
    """User replies to admin — updates description, sets status back to RAISED, adds track entry"""
    # Lock the row — prevents the user from submitting two replies simultaneously
    row = Request.get_for_update(db, {"id": request_id, "raised_by": user_id})
    if not row:
        raise HTTPException(status_code=404, detail="Request not found")

    if row.status != RequestStatus.REPLIED:
        raise HTTPException(
            status_code=400,
            detail="This request is not in REPLIED status"
        )

    user = User.get(db, {"id": user_id})

    # Update description and set status back to RAISED
    Request.update(db, {"id": request_id}, {
        "description": description,
        "status": RequestStatus.RAISED
    })

    # Add track entry for the user's reply
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.REPLIED,
        "performed_by": user_id,
        "performed_by_role": user.role,
        "comment": comment
    })
    db.commit()
    return True


def create_request(db: Session, user_id: str, main_type: str, sub_type: str, description: str, room_no: str) -> dict:
    """Create a new request with RAISED status and an initial track entry"""
    request = Request.create(db, {
        "raised_by": user_id,
        "main_type": main_type,
        "sub_type": sub_type,
        "description": description,
        "room_no": room_no,
        "status": RequestStatus.RAISED
    })

    user = User.get(db, {"id": user_id})
    RequestTrack.create(db, {
        "request_id": request.id,
        "event_type": TrackEventType.RAISED,
        "performed_by": user_id,
        "performed_by_role": user.role,
        "comment": None
    })
    db.commit()
    return {"message": "Request created successfully", "request_id": request.id}
