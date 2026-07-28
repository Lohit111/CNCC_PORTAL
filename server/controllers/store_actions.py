"""Store Action Controller"""
from sqlalchemy.orm import Session
from fastapi import HTTPException
from models.store_request import StoreRequest
from models.store_chat import StoreChat
from models.track import RequestTrack
from models.user import User
from models.enums import StoreRequestStatus, TrackEventType


def _get_store_request_or_404(db: Session, store_request_id: str) -> StoreRequest:
    sr = StoreRequest.get(db, {"id": store_request_id})
    if not sr:
        raise HTTPException(status_code=404, detail="Store request not found")
    return sr


def approve_store_request(db: Session, store_user: User, store_request_id: str) -> bool:
    """Set store request status to APPROVED and create a track on the parent request"""
    sr = _get_store_request_or_404(db, store_request_id)

    if sr.status != StoreRequestStatus.PENDING:
        raise HTTPException(
            status_code=400, detail="Store request is not in PENDING status")

    StoreRequest.update(db, {"id": store_request_id}, {
        "status": StoreRequestStatus.APPROVED,
        "responded_by": store_user.id
    })
    RequestTrack.create(db, {
        "request_id": sr.parent_request_id,
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
    sr = _get_store_request_or_404(db, store_request_id)

    if sr.status != StoreRequestStatus.PENDING:
        raise HTTPException(
            status_code=400, detail="Store request is not in PENDING status")

    StoreRequest.update(db, {"id": store_request_id}, {
        "status": StoreRequestStatus.REJECTED,
        "responded_by": store_user.id
    })
    RequestTrack.create(db, {
        "request_id": sr.parent_request_id,
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
    sr = _get_store_request_or_404(db, store_request_id)

    if sr.status != StoreRequestStatus.APPROVED:
        raise HTTPException(
            status_code=400, detail="Store request is not in APPROVED status")

    StoreRequest.update(db, {"id": store_request_id}, {
        "status": StoreRequestStatus.FULFILLED
    })
    RequestTrack.create(db, {
        "request_id": sr.parent_request_id,
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
    sr = _get_store_request_or_404(db, store_request_id)

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
