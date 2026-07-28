"""Store Requests Controller"""
from sqlalchemy.orm import Session
from sqlalchemy import or_
from models.request import Request
from models.track import RequestTrack
from models.assignment import Assignment
from models.store_request import StoreRequest, StoreRequestTable
from models.user import User
from models.enums import StoreRequestStatus


PAGE_SIZE = 30


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
