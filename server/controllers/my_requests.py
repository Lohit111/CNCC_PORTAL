"""My Requests Controller"""
from sqlalchemy.orm import Session
from fastapi import HTTPException
from models.request import Request, RequestTable
from models.track import RequestTrack
from models.user import User
from models.enums import RequestStatus, TrackEventType, UserRole
from services.notification_service import send_to_role
from controllers.common.helpers import paginate_requests, truncate


def _query_requests(db: Session, user_id: str, statuses: list, page: int) -> dict:
    """Paginated query for requests belonging to a specific user."""
    query = (
        db.query(RequestTable)
        .filter(
            RequestTable.raised_by == user_id,
            RequestTable.status.in_(statuses),
        )
        .order_by(RequestTable.updated_at.desc())
    )
    return paginate_requests(db, query, page)


def get_raised(db: Session, user_id: str, page: int) -> dict:
    """Requests in RAISED status."""
    return _query_requests(db, user_id, [RequestStatus.RAISED], page)


def get_replied(db: Session, user_id: str, page: int) -> dict:
    """Requests in REPLIED status."""
    return _query_requests(db, user_id, [RequestStatus.REPLIED], page)


def get_inprogress(db: Session, user_id: str, page: int) -> dict:
    """Requests in ASSIGNED, IN_PROGRESS, or REASSIGN_REQUESTED status."""
    return _query_requests(db, user_id, [
        RequestStatus.ASSIGNED,
        RequestStatus.IN_PROGRESS,
        RequestStatus.REASSIGN_REQUESTED,
    ], page)


def get_archive(db: Session, user_id: str, page: int) -> dict:
    """Requests in COMPLETED or REJECTED status."""
    return _query_requests(db, user_id, [
        RequestStatus.COMPLETED,
        RequestStatus.REJECTED,
    ], page)


def reply_to_request(
    db: Session,
    user_id: str,
    request_id: str,
    comment: str,
    description: str,
) -> bool:
    """User replies to admin — updates description, resets status to RAISED."""
    row = Request.get_for_update(db, {"id": request_id, "raised_by": user_id})
    if not row:
        raise HTTPException(status_code=404, detail="Request not found")

    if row.status != RequestStatus.REPLIED:
        raise HTTPException(status_code=400, detail="This request is not in REPLIED status")

    user = User.get(db, {"id": user_id})

    Request.update(db, {"id": request_id}, {
        "description": description,
        "status": RequestStatus.RAISED,
    })
    RequestTrack.create(db, {
        "request_id": request_id,
        "event_type": TrackEventType.REPLIED,
        "performed_by": user_id,
        "performed_by_role": user.role,
        "comment": comment,
    })
    db.commit()
    send_to_role(
        UserRole.ADMIN,
        f"{user.name}({user.email}) Replied to a Request",
        f'"{truncate(comment)}" for "{truncate(row.description)}"',
        {"admin": "raised"},
    )
    return True


def create_request(
    db: Session,
    user_id: str,
    main_type: str,
    sub_type: str,
    description: str,
    room_no: str,
    department: str,
) -> dict:
    """Create a new request with RAISED status and an initial track entry."""
    request = Request.create(db, {
        "raised_by": user_id,
        "main_type": main_type,
        "sub_type": sub_type,
        "description": description,
        "room_no": room_no,
        "department": department,
        "status": RequestStatus.RAISED,
    })

    user = User.get(db, {"id": user_id})
    RequestTrack.create(db, {
        "request_id": request.id,
        "event_type": TrackEventType.RAISED,
        "performed_by": user_id,
        "performed_by_role": user.role,
        "comment": None,
    })
    db.commit()
    send_to_role(
        UserRole.ADMIN,
        f"{user.name}({user.email}) Raised a Request",
        f'"{truncate(request.description)}"',
        {"admin": "raised"},
    )
    return {"message": "Request created successfully", "request_id": request.id}
