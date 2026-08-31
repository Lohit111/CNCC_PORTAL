"""Staff Requests Controller"""
from sqlalchemy.orm import Session
from fastapi import HTTPException
from models.request import Request, RequestTable
from models.track import RequestTrack, RequestTrackTable
from models.assignment import Assignment, AssignmentTable
from models.store_request import StoreRequest
from models.store_chat import StoreChat
from models.user import User
from models.enums import RequestStatus, TrackEventType, StoreRequestStatus


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


def _get_requests_for_staff(db: Session, staff_id: str, statuses: list, page: int) -> dict:
    """Efficiently fetch requests assigned to a staff member with given statuses via JOIN"""
    query = (
        db.query(RequestTable)
        .join(AssignmentTable, AssignmentTable.request_id == RequestTable.id)
        .filter(
            AssignmentTable.staff_id == staff_id,
            AssignmentTable.is_active == True,
            RequestTable.status.in_(statuses)
        )
        .distinct()
        .order_by(RequestTable.created_at.desc())
    )

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


def get_assigned(db: Session, staff_id: str, page: int) -> dict:
    """Requests currently assigned to this staff member"""
    return _get_requests_for_staff(db, staff_id, [RequestStatus.ASSIGNED], page)


def get_inprogress(db: Session, staff_id: str, page: int) -> dict:
    """In-progress requests taken by this staff member"""
    return _get_requests_for_staff(db, staff_id, [RequestStatus.IN_PROGRESS], page)


def get_archive(db: Session, staff_id: str, page: int) -> dict:
    """
    Completed/rejected requests this staff was the final assigned person on.
    Checks that the staff's assignment track is the latest ASSIGNED track on the request
    (no newer ASSIGNED track exists), confirming they weren't reassigned away.
    """
    all_assignments = Assignment.find(db, {"staff_id": staff_id})

    confirmed_request_ids = set()
    for assignment in all_assignments:
        track = RequestTrack.get(db, {"id": assignment.track_id})
        if not track or track.event_type != TrackEventType.ASSIGNED:
            continue

        later_assigned = (
            db.query(RequestTrackTable)
            .filter(
                RequestTrackTable.request_id == assignment.request_id,
                RequestTrackTable.event_type == TrackEventType.ASSIGNED,
                RequestTrackTable.id > track.id
            )
            .first()
        )
        if later_assigned:
            continue

        request = Request.get(db, {"id": assignment.request_id})
        if request and request.status in [RequestStatus.COMPLETED, RequestStatus.REJECTED]:
            confirmed_request_ids.add(assignment.request_id)

    total = len(confirmed_request_ids)
    all_ids = list(confirmed_request_ids)
    skip = (page - 1) * PAGE_SIZE
    page_ids = all_ids[skip: skip + PAGE_SIZE]
    requests_page = [r for r in [Request.get(
        db, {"id": rid}) for rid in page_ids] if r]

    return {
        "requests": [_build_request_detail(db, r) for r in requests_page],
        "total": total,
        "page": page,
        "pages": -(-total // PAGE_SIZE)
    }


# --- PUT action endpoints ---

def _verify_staff_assigned(db: Session, staff_id: str, request_id: str):
    """Raise 403 if this staff is not actively assigned to the request"""
    assignment = Assignment.get(db, {
        "staff_id": staff_id,
        "request_id": request_id,
        "is_active": True
    })
    if not assignment:
        raise HTTPException(
            status_code=403,
            detail="You are not actively assigned to this request"
        )


def start_request(db: Session, staff: User, request_id: str) -> bool:
    """Set request status to IN_PROGRESS and create a track entry"""
    request = Request.get(db, {"id": request_id})
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")
    if request.status != RequestStatus.ASSIGNED:
        raise HTTPException(
            status_code=400, detail="Request is not in ASSIGNED status")

    _verify_staff_assigned(db, staff.id, request_id)

    Request.update(db, {"id": request_id}, {
                   "status": RequestStatus.IN_PROGRESS})
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.IN_PROGRESS,
        "performed_by": staff.id,
        "performed_by_role": staff.role,
        "comment": None
    })
    db.commit()
    return True


def request_reassignment(db: Session, staff: User, request_id: str, comment: str) -> bool:
    """
    Request a reassignment:
    - Sets status to REASSIGN_REQUESTED
    - Deactivates all active assignments for this request
    - Creates a track entry
    """
    request = Request.get(db, {"id": request_id})
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")
    if request.status not in [RequestStatus.ASSIGNED, RequestStatus.IN_PROGRESS]:
        raise HTTPException(
            status_code=400, detail="Request cannot be reassigned from its current status")

    _verify_staff_assigned(db, staff.id, request_id)

    # Deactivate all active assignments for this request
    Assignment.update(db, {"request_id": request_id,
                      "is_active": True}, {"is_active": False})

    Request.update(db, {"id": request_id}, {
                   "status": RequestStatus.REASSIGN_REQUESTED})
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.REASSIGN_REQUESTED,
        "performed_by": staff.id,
        "performed_by_role": staff.role,
        "comment": comment
    })
    db.commit()
    return True


def finish_request(db: Session, staff: User, request_id: str) -> bool:
    """
    Complete a request:
    - Sets status to COMPLETED
    - Deactivates all active assignments
    - Creates a track entry
    """
    request = Request.get(db, {"id": request_id})
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")
    if request.status != RequestStatus.IN_PROGRESS:
        raise HTTPException(
            status_code=400, detail="Request is not IN_PROGRESS")

    _verify_staff_assigned(db, staff.id, request_id)

    # Deactivate all active assignments
    Assignment.update(db, {"request_id": request_id,
                      "is_active": True}, {"is_active": False})

    Request.update(db, {"id": request_id}, {"status": RequestStatus.COMPLETED})
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.COMPLETED,
        "performed_by": staff.id,
        "performed_by_role": staff.role,
        "comment": None
    })
    db.commit()
    return True


def create_store_request(db: Session, staff: User, request_id: str, description: str) -> bool:
    """
    Create a store request under a parent request:
    - Creates the store request with PENDING status
    - Creates a track entry on the parent request
    """
    request = Request.get(db, {"id": request_id})
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")

    _verify_staff_assigned(db, staff.id, request_id)

    StoreRequest.create(db, {
        "parent_request_id": request_id,
        "requested_by": staff.id,
        "description": description,
        "status": StoreRequestStatus.PENDING
    })
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.STORE_REQUEST_CREATED,
        "performed_by": staff.id,
        "performed_by_role": staff.role,
        "comment": None
    })
    db.commit()
    return True


def get_store_chat(db: Session, staff_id: str, store_request_id: str) -> list:
    """Get all chat messages for a store request"""
    sr = StoreRequest.get(db, {"id": store_request_id})
    if not sr:
        raise HTTPException(status_code=404, detail="Store request not found")
    return StoreChat.find(db, {"store_request_id": store_request_id})


def send_staff_chat_message(db: Session, staff: User, store_request_id: str, message: str) -> bool:
    """Send a chat message on a store request — staff must own the parent request"""
    from models.enums import StoreRequestStatus
    sr = StoreRequest.get(db, {"id": store_request_id})
    if not sr:
        raise HTTPException(status_code=404, detail="Store request not found")

    # Verify the staff member is the one who created this store request
    if sr.requested_by != staff.id:
        raise HTTPException(
            status_code=403,
            detail="You are not the owner of this store request"
        )

    if sr.status not in [StoreRequestStatus.PENDING, StoreRequestStatus.APPROVED]:
        raise HTTPException(
            status_code=400,
            detail="Chat is only available on PENDING or APPROVED store requests"
        )

    StoreChat.create(db, {
        "store_request_id": store_request_id,
        "sender_id": staff.id,
        "message": message
    })
    db.commit()
    return True
