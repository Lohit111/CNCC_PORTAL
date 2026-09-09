"""User Controller"""
from sqlalchemy.orm import Session
from fastapi import HTTPException
from models.user import User
from models.assignment import AssignmentTable
from models.request import Request, RequestTable
from models.store_request import StoreRequest, StoreRequestTable
from models.enums import UserRole, RequestStatus, StoreRequestStatus
from services.notification_service import send_to_uid


# ---------------------------------------------------------------------------
# Participation helpers
# ---------------------------------------------------------------------------

def _get_user_participation(db: Session, user_id: str) -> dict:
    """
    Return all unfinished work the user is currently participating in across
    four dimensions:

      raised_requests            — requests raised by this user that are not
                                   yet COMPLETED or REJECTED
      assigned_requests          — requests where this user has an active
                                   assignment and the request is not terminal
      requested_store_requests   — store requests raised by this user that are
                                   not yet FULFILLED or REJECTED
      responded_store_requests   — store requests this user has responded to
                                   that are not yet FULFILLED or REJECTED
    """
    terminal_req = {RequestStatus.COMPLETED, RequestStatus.REJECTED}
    terminal_sr  = {StoreRequestStatus.FULFILLED, StoreRequestStatus.REJECTED}

    # 1. Requests raised by the user that are still open
    raised_rows = (
        db.query(RequestTable)
        .filter(
            RequestTable.raised_by == user_id,
            RequestTable.status.notin_([s.value for s in terminal_req]),
        )
        .all()
    )
    raised_requests = [Request.from_orm(r).model_dump(mode='json') for r in raised_rows]

    # 2. Requests where the user has an active assignment and are not terminal
    assigned_rows = (
        db.query(RequestTable)
        .join(AssignmentTable, AssignmentTable.request_id == RequestTable.id)
        .filter(
            AssignmentTable.staff_id == user_id,
            AssignmentTable.is_active == True,
            RequestTable.status.notin_([s.value for s in terminal_req]),
        )
        .all()
    )
    assigned_requests = [Request.from_orm(r).model_dump(mode='json') for r in assigned_rows]

    # 3. Store requests raised by this user that are still open
    requested_sr_rows = (
        db.query(StoreRequestTable)
        .filter(
            StoreRequestTable.requested_by == user_id,
            StoreRequestTable.status.notin_([s.value for s in terminal_sr]),
        )
        .all()
    )
    requested_store_requests = [
        StoreRequest.from_orm(r).model_dump(mode='json') for r in requested_sr_rows
    ]

    # 4. Store requests this user has responded to that are still open
    responded_sr_rows = (
        db.query(StoreRequestTable)
        .filter(
            StoreRequestTable.responded_by == user_id,
            StoreRequestTable.status.notin_([s.value for s in terminal_sr]),
        )
        .all()
    )
    responded_store_requests = [
        StoreRequest.from_orm(r).model_dump(mode='json') for r in responded_sr_rows
    ]

    return {
        "raised_requests": raised_requests,
        "assigned_requests": assigned_requests,
        "requested_store_requests": requested_store_requests,
        "responded_store_requests": responded_store_requests,
    }


def _assert_no_participation(db: Session, user_id: str, action: str) -> None:
    """
    Raise a 409 with the full participation map if the user still has
    unfinished work in any of the four dimensions.
    The response body is structured so the frontend can display each category
    and let the admin resolve them before retrying.
    """
    participation = _get_user_participation(db, user_id)
    has_any = any(len(v) > 0 for v in participation.values())

    if has_any:
        print(participation)
        raise HTTPException(
            status_code=409,
            detail={
                "message": (
                    f"Cannot {action} this user — they still have unfinished "
                    "requests or store requests. Resolve them first."
                ),
                "participation": participation,
            }
        )


# ---------------------------------------------------------------------------
# CRUD
# ---------------------------------------------------------------------------

def get_users(db: Session) -> dict:
    """Get all active users"""
    users = User.find(db, {})
    return users

def get_user(db: Session, user_id: str) -> User:
    """Get a user by ID"""
    user = User.get(db, {"id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

def create_user(db: Session, email: str, role: UserRole) -> User:
    """Create a new active user with given email and role"""
    existing = User.get(db, {"email": email})
    if existing:
        raise HTTPException(
            status_code=409, detail="User with this email already exists")
    user = User.create(db, {"email": email, "role": role, "is_active": True})
    db.commit()
    return user


def update_user_role(db: Session, user_id: str, role: UserRole, admin_name: str) -> User:
    """Update a user's role — blocked if the user has unfinished participation"""
    user = User.get(db, {"id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.role == role:
        raise HTTPException(status_code=400, detail="User already has this role")
    _assert_no_participation(db, user_id, action="change the role of")
    User.update(db, {"id": user_id}, {"role": role})
    db.commit()
    send_to_uid(
        user_id,
        "Role Updated",
        f"Your role has been updated to {role.value} by an administrator ({admin_name}).",
    )
    return User.get(db, {"id": user_id})  # pyright: ignore[reportReturnType]


def update_user_profile(db: Session, user_id: str, name: str, phone: str) -> User:
    """Update the current user's name and phone number"""
    User.update(db, {"id": user_id}, {"name": name, "phone": phone})
    db.commit()
    return User.get(db, {"id": user_id})  # pyright: ignore[reportReturnType]


def deactivate_user(db: Session, user_id: str, admin_name: str) -> bool:
    """Soft delete a user — blocked if the user has unfinished participation"""
    user = User.get(db, {"id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if not user.is_active:
        raise HTTPException(status_code=409, detail="User is already deactivated")
    _assert_no_participation(db, user_id, action="deactivate")
    User.update(db, {"id": user_id}, {"is_active": False})
    db.commit()
    send_to_uid(
        user_id,
        "Account Deactivated",
        f"Your account has been deactivated by an administrator ({admin_name}). Please contact support for more information.",
    )
    return True

def activate_user(db: Session, user_id: str, admin_name: str) -> bool:
    """Activate a user"""
    user = User.get(db, {"id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.is_active:
        raise HTTPException(status_code=409, detail="User is already activated")
    User.update(db, {"id": user_id}, {"is_active": True})
    db.commit()
    send_to_uid(
        user_id,
        "Account Activated",
        f"Your account has been activated by an administrator ({admin_name}). You can now access the system.",
    )
    return True