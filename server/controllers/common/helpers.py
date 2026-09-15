"""Shared controller helpers.

Centralises logic that was previously duplicated across admin_actions,
my_requests, and staff_actions:

    build_request_detail  — assembles the full detail document for one request
    paginate_requests     — runs a pre-built SQLAlchemy query with pagination
    truncate              — shortens a string for notification previews
"""

from typing import List

from sqlalchemy.orm import Query
from sqlalchemy.orm import Session

from models.assignment import Assignment
from models.request import Request
from models.store_request import StoreRequest
from models.track import RequestTrack
from models.user import User


PAGE_SIZE = 30


# ---------------------------------------------------------------------------
# Request detail builder
# ---------------------------------------------------------------------------

def build_request_detail(db: Session, request: Request) -> dict:
    """Assemble the full detail document for a single request.

    Fetches timeline, assignments, and store requests in three queries, then
    resolves every referenced user ID in one pass and embeds the users map.

    Returns a plain dict matching the shape every API endpoint serialises.
    """
    timeline = RequestTrack.find(db, {"request_id": request.id})
    assignments = Assignment.find(db, {"request_id": request.id})
    store_requests = StoreRequest.find(db, {"parent_request_id": request.id})

    uid_set: set[str] = {request.raised_by}
    for track in timeline:
        uid_set.add(track.performed_by)
    for assignment in assignments:
        uid_set.add(assignment.staff_id)
    for sr in store_requests:
        uid_set.add(sr.requested_by)
        if sr.responded_by:
            uid_set.add(sr.responded_by)

    users_map: dict[str, dict] = {}
    for uid in uid_set:
        user = User.get(db, {"id": uid})
        if user:
            users_map[uid] = user.model_dump()

    return {
        "request": request.model_dump(),
        "timeline": [t.model_dump() for t in timeline],
        "assignments": [a.model_dump() for a in assignments],
        "store_requests": [sr.model_dump() for sr in store_requests],
        "users": users_map,
    }


# ---------------------------------------------------------------------------
# Pagination helper
# ---------------------------------------------------------------------------

def paginate_requests(
    db: Session,
    query: Query,
    page: int,
) -> dict:
    """Apply pagination to a pre-filtered SQLAlchemy query and return the
    standard paginated response shape.

    The caller is responsible for building ``query`` with all necessary
    filters and ordering applied. This function only adds ``count``,
    ``offset``, and ``limit``.

    Args:
        db:    Database session (passed through to build_request_detail).
        query: A SQLAlchemy query that returns RequestTable rows.
        page:  1-based page number.

    Returns:
        {
            "requests": [...],  # list of full detail dicts
            "total":    int,
            "page":     int,
            "pages":    int,
        }
    """
    total = query.count()
    skip = (page - 1) * PAGE_SIZE
    rows = query.offset(skip).limit(PAGE_SIZE).all()
    requests = [Request.from_orm(r) for r in rows]

    return {
        "requests": [build_request_detail(db, r) for r in requests],
        "total": total,
        "page": page,
        "pages": -(-total // PAGE_SIZE),
    }


# ---------------------------------------------------------------------------
# String helper
# ---------------------------------------------------------------------------

def truncate(text: str, max_length: int = 80) -> str:
    """Shorten *text* to *max_length* characters for notification previews."""
    return text if len(text) <= max_length else text[: max_length - 3] + "..."
