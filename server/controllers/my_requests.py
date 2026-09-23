"""My Requests Controller"""
from sqlalchemy.orm import Session
from fastapi import HTTPException
from models.request import Request, RequestTable
from models.track import RequestTrack
from models.user import User
from models.enums import RequestStatus, TrackEventType, UserRole
from services.notification_service import send_to_role
from controllers.common.helpers import paginate_requests, truncate
import re


def _validate_combined_sub_types(db: Session, sub_type: str) -> bool:
    """Validate combined sub_type format: 'type1-num1,type2-num2,...'
    
    Each part must be: {sub_type_name}-{quantity}
    Verifies that each sub_type_name is a valid SubType in the database.
    Returns True if valid, False otherwise.
    """
    from models.request_type import SubTypeTable
    
    if not sub_type or not sub_type.strip():
        return False
    
    parts = sub_type.split(',')
    for part in parts:
        if '-' not in part:
            return False
        components = part.rsplit('-', 1)  # Split from right to handle names with hyphens
        if len(components) != 2:
            return False
        name, quantity = components
        name = name.strip()
        quantity = quantity.strip()
        
        # Validate name and quantity format
        if not name or not quantity or not quantity.isdigit():
            return False
        
        # Verify that the subtype name exists in database
        subtype_exists = db.query(SubTypeTable).filter(
            SubTypeTable.name == name
        ).first()
        if not subtype_exists:
            return False
    
    return True


def _validate_and_format_room(room_no: str) -> str:
    """Validate room number format and return formatted version.
    
    Format: {1-3 letters}{1-3 digits} or {1-3 letters}{1-3 digits}/{digit}
    Examples: A1, ABC123, AB12/5
    
    Raises HTTPException if invalid.
    """
    if not room_no or not room_no.strip():
        raise HTTPException(status_code=400, detail="Room is required")
    
    cleaned = re.sub(r'[^a-zA-Z0-9/]', '', room_no).upper()
    if not cleaned:
        raise HTTPException(status_code=400, detail="Room must contain letters and numbers")
    
    # Split by /
    parts = cleaned.split('/')
    if len(parts) > 2:
        raise HTTPException(status_code=400, detail="Room can contain at most one '/'")
    
    main_part = parts[0]
    suffix_part = parts[1] if len(parts) > 1 else None
    
    # Validate suffix if present - must be single digit
    if suffix_part:
        if len(suffix_part) != 1 or not suffix_part.isdigit():
            raise HTTPException(status_code=400, detail="After '/' must be a single digit")
    
    # Main part must start with letter
    if not main_part or not main_part[0].isalpha():
        raise HTTPException(status_code=400, detail="Room must start with a letter")
    
    # Extract and validate letters and digits
    letter_count = 0
    digit_count = 0
    seen_digit = False
    
    for char in main_part:
        if char.isalpha():
            if seen_digit:
                raise HTTPException(status_code=400, detail="Letters must come before digits")
            if letter_count >= 3:
                raise HTTPException(status_code=400, detail="Maximum 3 letters allowed")
            letter_count += 1
        elif char.isdigit():
            if digit_count >= 3:
                raise HTTPException(status_code=400, detail="Maximum 3 digits allowed")
            digit_count += 1
            seen_digit = True
        else:
            raise HTTPException(status_code=400, detail="Invalid character in room number")
    
    # Must have at least 1 digit
    if digit_count == 0:
        raise HTTPException(status_code=400, detail="Room must contain at least 1 digit")
    
    return f"{main_part}/{suffix_part}" if suffix_part else main_part


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
        RequestStatus.HOLD,
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
    # Validate combined sub_type format and verify subtypes exist
    if not _validate_combined_sub_types(db, sub_type):
        raise HTTPException(
            status_code=400,
            detail="Invalid sub_type format or one or more sub_types don't exist. Expected: 'type1-num1,type2-num2,...'"
        )
    
    formatted_room = _validate_and_format_room(room_no)
    request = Request.create(db, {
        "raised_by": user_id,
        "main_type": main_type,
        "sub_type": sub_type,
        "description": description,
        "room_no": formatted_room,
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
