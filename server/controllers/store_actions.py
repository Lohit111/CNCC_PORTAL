"""Store Action Controller"""
from sqlalchemy.orm import Session
from sqlalchemy import or_
from fastapi import HTTPException
from models.assignment import Assignment
from models.store_request import StoreRequest, StoreRequestTable
from models.store_chat import StoreChat
from models.track import RequestTrack
from models.user import User
from models.enums import StoreRequestStatus, TrackEventType
from models.request import Request

PAGE_SIZE = 30

# ==========================================
#  HELPERS
# ==========================================
def _get_store_request_for_update(db: Session, store_request_id: str) -> StoreRequestTable:
    """Fetch the store request row with a row-level lock (SELECT FOR UPDATE).
    Raises 404 if not found. Use before any status mutation to prevent race conditions."""
    row = StoreRequest.get_for_update(db, {"id": store_request_id})
    if not row:
        raise HTTPException(status_code=404, detail="Store request not found")
    return row

def _build_parent_request_detail(db: Session, request: Request) -> dict:
    """
    Build parent request detail — includes request, timeline, assignments, and users map.
    Excludes store_requests since that is already provided at the top level.
    """
    timeline = RequestTrack.find(db, {"request_id": request.id})
    assignments = Assignment.find(db, {"request_id": request.id})

    uid_set = set()
    uid_set.add(request.raised_by)
    for track in timeline:
        uid_set.add(track.performed_by)
    for assignment in assignments:
        uid_set.add(assignment.staff_id)

    users_map = {}
    for uid in uid_set:
        user = User.get(db, {"id": uid})
        if user:
            users_map[uid] = user.model_dump()

    return {
        "request": request.model_dump(),
        "timeline": [t.model_dump() for t in timeline],
        "assignments": [a.model_dump() for a in assignments],
        "users": users_map
    }


def _build_store_detail(db: Session, sr: StoreRequest) -> dict:
    """Build a store request detail with its parent request context"""
    parent = Request.get(db, {"id": sr.parent_request_id})
    return {
        "store_request": sr.model_dump(),
        "parent_request": _build_parent_request_detail(db, parent) if parent else None
    }


def _query_store(db: Session, filters, page: int) -> dict:
    """Run a filtered, paginated DB query and build store details"""
    query = db.query(StoreRequestTable).filter(*filters)
    total = query.count()
    skip = (page - 1) * PAGE_SIZE
    rows = query.offset(skip).limit(PAGE_SIZE).all()
    items = [StoreRequest.from_orm(r) for r in rows]
    return {
        "store_requests": [_build_store_detail(db, sr) for sr in items],
        "total": total,
        "page": page,
        "pages": -(-total // PAGE_SIZE)
    }


# ==========================================
#  ACTIONS
# ==========================================
def approve_store_request(db: Session, store_user: User, store_request_id: str) -> bool:
    """Set store request status to APPROVED and create a track on the parent request"""
    # Lock the row — prevents two store users from approving the same request simultaneously
    row = _get_store_request_for_update(db, store_request_id)

    if row.status != StoreRequestStatus.PENDING:
        raise HTTPException(
            status_code=400, detail="Store request is not in PENDING status")

    StoreRequest.update(db, {"id": store_request_id}, {
        "status": StoreRequestStatus.APPROVED,
        "responded_by": store_user.id
    })
    RequestTrack.create(db, {
        "request_id": row.parent_request_id,
        "store_request_id": store_request_id,
        "event_type": TrackEventType.STORE_REQUEST_APPROVED,
        "performed_by": store_user.id,
        "performed_by_role": store_user.role,
        "comment": None
    })
    db.commit()
    return True


def reject_store_request(db: Session, store_user: User, store_request_id: str, comment: str) -> bool:
    """Set store request status to REJECTED and create a track on the parent request"""
    # Lock the row — prevents approve/reject collision on the same PENDING store request
    row = _get_store_request_for_update(db, store_request_id)

    if row.status != StoreRequestStatus.PENDING:
        raise HTTPException(
            status_code=400, detail="Store request is not in PENDING status")

    StoreRequest.update(db, {"id": store_request_id}, {
        "status": StoreRequestStatus.REJECTED,
        "responded_by": store_user.id
    })
    RequestTrack.create(db, {
        "request_id": row.parent_request_id,
        "store_request_id": store_request_id,
        "event_type": TrackEventType.STORE_REQUEST_REJECTED,
        "performed_by": store_user.id,
        "performed_by_role": store_user.role,
        "comment": comment
    })
    db.commit()
    return True


def fulfil_store_request(db: Session, store_user: User, store_request_id: str) -> bool:
    """Set store request status to FULFILLED and create a track on the parent request"""
    # Lock the row — prevents double-fulfilment of the same APPROVED store request
    row = _get_store_request_for_update(db, store_request_id)

    if row.status != StoreRequestStatus.APPROVED:
        raise HTTPException(
            status_code=400, detail="Store request is not in APPROVED status")

    StoreRequest.update(db, {"id": store_request_id}, {
        "status": StoreRequestStatus.FULFILLED
    })
    RequestTrack.create(db, {
        "request_id": row.parent_request_id,
        "store_request_id": store_request_id,
        "event_type": TrackEventType.STORE_REQUEST_FULFILLED,
        "performed_by": store_user.id,
        "performed_by_role": store_user.role,
        "comment": None
    })
    db.commit()
    return True


def send_chat_message(db: Session, store_user: User, store_request_id: str, message: str) -> bool:
    """Add a chat message to a store request"""
    sr = StoreRequest.get(db, {"id": store_request_id})
    if not sr:
        raise HTTPException(status_code=404, detail="Store request not found")

    if sr.status not in [StoreRequestStatus.PENDING, StoreRequestStatus.APPROVED]:
        raise HTTPException(
            status_code=400,
            detail="Chat is only available on PENDING or APPROVED store requests"
        )

    StoreChat.create(db, {
        "store_request_id": store_request_id,
        "sender_id": store_user.id,
        "message": message
    })
    db.commit()
    return True


# ==========================================
#  QUERIES
# ==========================================
def get_pending(db: Session, page: int) -> dict:
    """All store requests with PENDING status"""
    return _query_store(db, [
        StoreRequestTable.status == StoreRequestStatus.PENDING
    ], page)


def get_approved(db: Session, store_user_id: str, page: int) -> dict:
    """Store requests approved by this store user with APPROVED status"""
    return _query_store(db, [
        StoreRequestTable.responded_by == store_user_id,
        StoreRequestTable.status == StoreRequestStatus.APPROVED
    ], page)


def get_archive(db: Session, page: int) -> dict:
    """All store requests with REJECTED or FULFILLED status"""
    return _query_store(db, [
        or_(
            StoreRequestTable.status == StoreRequestStatus.REJECTED,
            StoreRequestTable.status == StoreRequestStatus.FULFILLED
        )
    ], page)
