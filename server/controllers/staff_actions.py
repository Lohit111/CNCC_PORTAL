"""Staff Requests Controller"""
from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException
from datetime import datetime, timedelta, timezone
from models.request import Request, RequestTable
from models.track import RequestTrack, RequestTrackTable
from models.assignment import Assignment, AssignmentTable
from models.holding_request import HoldingRequest
from models.store_request import StoreRequest, StoreRequestTable
from models.store_chat import StoreChat
from models.user import User
from models.enums import RequestStatus, TrackEventType, StoreRequestStatus, UserRole
from services.notification_service import send_to_uid, send_to_role
from controllers.common.helpers import paginate_requests, truncate


# --- GET endpoints ---

def _query_requests(
    db: Session, staff_id: str, statuses: list, page: int
) -> dict:
    """Paginated query for requests actively assigned to a staff member."""
    query = (
        db.query(RequestTable)
        .join(AssignmentTable, AssignmentTable.request_id == RequestTable.id)
        .filter(
            AssignmentTable.staff_id == staff_id,
            AssignmentTable.is_active == True,
            RequestTable.status.in_(statuses),
        )
        .distinct()
        .order_by(RequestTable.updated_at.desc())
    )
    return paginate_requests(db, query, page)


def get_assigned(db: Session, staff_id: str, page: int) -> dict:
    """Requests currently assigned to this staff member."""
    return _query_requests(db, staff_id, [RequestStatus.ASSIGNED], page)


def get_inprogress(db: Session, staff_id: str, page: int) -> dict:
    """In-progress requests taken by this staff member."""
    return _query_requests(db, staff_id, [RequestStatus.IN_PROGRESS], page)


def get_in_hold(db: Session, staff_id: str, page: int) -> dict:
    """In-hold requests (currently on hold) assigned to this staff member."""
    return _query_requests(db, staff_id, [RequestStatus.HOLD], page)


def get_archive(db: Session, staff_id: str, page: int) -> dict:
    """
    Completed/rejected requests this staff was the final assigned person on.
    Checks that no later ASSIGNED track exists for the same request.
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
                RequestTrackTable.id > track.id,
            )
            .first()
        )
        if later_assigned:
            continue

        request = Request.get(db, {"id": assignment.request_id})
        if request and request.status in [RequestStatus.COMPLETED, RequestStatus.REJECTED]:
            confirmed_request_ids.add(assignment.request_id)

    query = (
        db.query(RequestTable)
        .filter(RequestTable.id.in_(confirmed_request_ids))
        .order_by(RequestTable.updated_at.desc())
    )
    return paginate_requests(db, query, page)

def get_store_chat(db: Session, staff_id: str, store_request_id: str) -> list:
    """Get all chat messages for a store request."""
    sr = StoreRequest.get(db, {"id": store_request_id})
    if not sr:
        raise HTTPException(status_code=404, detail="Store request not found")
    return StoreChat.find(db, {"store_request_id": store_request_id})

# --- Authorisation helper ---

def _verify_staff_assigned(db: Session, staff_id: str, request_id: str) -> None:
    """Raise 403 if this staff is not actively assigned to the request."""
    assignment = Assignment.get(db, {
        "staff_id": staff_id,
        "request_id": request_id,
        "is_active": True,
    })
    if not assignment:
        raise HTTPException(
            status_code=403,
            detail="You are not actively assigned to this request",
        )


# --- PUT action endpoints ---

def start_request(db: Session, staff: User, request_id: str) -> bool:
    """Set request status to IN_PROGRESS and create a track entry."""
    row = Request.get_for_update(db, {"id": request_id})
    if not row:
        raise HTTPException(status_code=404, detail="Request not found")
    if row.status != RequestStatus.ASSIGNED:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot start request from '{row.status.value}' status",
        )

    _verify_staff_assigned(db, staff.id, request_id)

    Request.update(db, {"id": request_id}, {"status": RequestStatus.IN_PROGRESS})
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.IN_PROGRESS,
        "performed_by": staff.id,
        "performed_by_role": staff.role,
        "comment": None,
    })
    db.commit()
    send_to_role(
        UserRole.ADMIN,
        f"{staff.name}({staff.email}) Started a Request",
        f'Request Details: "{truncate(row.description)}"',
    )
    return True


def request_reassignment(
    db: Session, staff: User, request_id: str, comment: str
) -> bool:
    """Request a reassignment — sets status to REASSIGN_REQUESTED."""
    row = Request.get_for_update(db, {"id": request_id})
    if not row:
        raise HTTPException(status_code=404, detail="Request not found")
    if row.status != RequestStatus.ASSIGNED:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot request reassignment from '{row.status.value}' status",
        )

    _verify_staff_assigned(db, staff.id, request_id)

    Assignment.update(db, {"request_id": request_id, "is_active": True}, {"is_active": False})
    Request.update(db, {"id": request_id}, {"status": RequestStatus.REASSIGN_REQUESTED})
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.REASSIGN_REQUESTED,
        "performed_by": staff.id,
        "performed_by_role": staff.role,
        "comment": comment,
    })
    db.commit()
    send_to_role(
        UserRole.ADMIN,
        f"{staff.name}({staff.email}) Requested Reassignment",
        f'Reason: "{truncate(comment)}"\n\non Request: "{truncate(row.description)}"',
        {"admin": "reassign-requested"},
    )
    return True


def finish_request(db: Session, staff: User, request_id: str) -> bool:
    """Complete a request — sets status to COMPLETED."""
    row = Request.get_for_update(db, {"id": request_id})
    if not row:
        raise HTTPException(status_code=404, detail="Request not found")
    if row.status != RequestStatus.IN_PROGRESS:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot finish request from '{row.status.value}' status",
        )

    _verify_staff_assigned(db, staff.id, request_id)

    pending_store_requests = (
        db.query(StoreRequestTable)
        .filter(
            StoreRequestTable.parent_request_id == request_id,
            StoreRequestTable.status.in_([
                StoreRequestStatus.PENDING,
                StoreRequestStatus.APPROVED,
            ]),
        )
        .count()
    )
    if pending_store_requests > 0:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot complete request: {pending_store_requests} store request(s) are still pending or approved",
        )

    Assignment.update(db, {"request_id": request_id, "is_active": True}, {"is_active": False})
    Request.update(db, {"id": request_id}, {"status": RequestStatus.COMPLETED})
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.COMPLETED,
        "performed_by": staff.id,
        "performed_by_role": staff.role,
        "comment": None,
    })
    db.commit()
    send_to_uid(
        row.raised_by,
        f"{staff.name}({staff.email}) Completed Your Request",
        f'Request Details: "{truncate(row.description)}"',
    )
    return True


def create_store_request(
    db: Session, staff: User, request_id: str, description: str
) -> bool:
    """Create a store request under a parent IN_PROGRESS request."""
    row = Request.get_for_update(db, {"id": request_id})
    if not row:
        raise HTTPException(status_code=404, detail="Request not found")

    if row.status != RequestStatus.IN_PROGRESS:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot raise a store request on a request in '{row.status.value}' status — request must be IN_PROGRESS",
        )

    _verify_staff_assigned(db, staff.id, request_id)

    StoreRequest.create(db, {
        "parent_request_id": request_id,
        "requested_by": staff.id,
        "description": description,
        "status": StoreRequestStatus.PENDING,
    })
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.STORE_REQUEST_CREATED,
        "performed_by": staff.id,
        "performed_by_role": staff.role,
        "comment": None,
    })
    db.commit()
    send_to_role(
        UserRole.STORE,
        f"New Store Request by {staff.name}({staff.email})",
        f'"{truncate(description)}"\n\non Request: "{truncate(row.description)}"',
        {"store": "pending"},
    )
    return True


def hold_request(db: Session, staff: User, request_id: str, duration_minutes: int) -> bool:
    """Place a request on HOLD from IN_PROGRESS status.
    
    Staff must have an active assignment. Duration is in minutes from now.
    """
    if duration_minutes <= 0:
        raise HTTPException(
            status_code=400,
            detail="Duration must be greater than 0",
        )

    row = Request.get_for_update(db, {"id": request_id})
    if not row:
        raise HTTPException(status_code=404, detail="Request not found")
    if row.status != RequestStatus.IN_PROGRESS:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot hold request from '{row.status.value}' status — request must be IN_PROGRESS",
        )

    _verify_staff_assigned(db, staff.id, request_id)

    # Calculate hold_until
    hold_until = datetime.now(timezone.utc) + timedelta(minutes=duration_minutes)

    # Atomically update request status and create holding record
    Request.update(db, {"id": request_id}, {"status": RequestStatus.HOLD})
    HoldingRequest.create(db, {
        "request_id": request_id,
        "hold_until": hold_until,
    })
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.HOLD,
        "performed_by": staff.id,
        "performed_by_role": staff.role,
        "comment": f"Held for {duration_minutes} minutes\nUntil: {hold_until.isoformat()}",
    })
    db.execute(
        text("SELECT pg_notify('hold_created', :request_id)"),
        {"request_id": request_id},
    )
    db.commit()
    send_to_uid(
        row.raised_by,
        f"{staff.name}({staff.email}) Placed Request on Hold",
        f'Duration: {duration_minutes} minutes\n\nRequest: "{truncate(row.description)}"',
    )
    return True


def send_staff_chat_message(
    db: Session, staff: User, store_request_id: str, message: str
) -> bool:
    """Send a chat message on a store request — staff must own the store request."""
    sr = StoreRequest.get(db, {"id": store_request_id})
    if not sr:
        raise HTTPException(status_code=404, detail="Store request not found")

    if sr.requested_by != staff.id:
        raise HTTPException(
            status_code=403,
            detail="You are not the owner of this store request",
        )

    if sr.status not in [StoreRequestStatus.PENDING, StoreRequestStatus.APPROVED]:
        raise HTTPException(
            status_code=400,
            detail="Chat is only available on PENDING or APPROVED store requests",
        )

    StoreChat.create(db, {
        "store_request_id": store_request_id,
        "sender_id": staff.id,
        "message": message,
    })
    db.commit()
    send_to_uid(
        sr.responded_by,
        f"{staff.name}({staff.email}) Sent a Message",
        f'"{truncate(message)}"\n\non Store Request: "{truncate(sr.description)}"',
    )
    return True
