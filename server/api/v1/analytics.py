"""Analytics API Endpoints"""
from typing import Optional
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from controllers.analytics import (
    get_dashboard_stats,
    search_requests,
)
from config.database import get_db

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/search-prefix")
async def search_by_prefix(id: str, db: Session = Depends(get_db)):
    """Search requests by ID prefix across all statuses — returns full detail, no pagination"""
    return search_requests(db, prefix=id)


@router.get("/dashboard")
async def dashboard(
    db: Session = Depends(get_db),
    id_prefix: Optional[str] = None,
    status: Optional[str] = None,
    room_no: Optional[str] = None,
    main_type: Optional[str] = None,
    sub_type: Optional[str] = None,
    raised_by: Optional[str] = None,
):
    """Ticket statistics dashboard.

    Returns daily counts for the current month, monthly counts for the current
    year, and yearly counts across all time — all filtered by the supplied
    query parameters.
    """
    return get_dashboard_stats(
        db,
        id_prefix=id_prefix,
        status=status,
        room_no=room_no,
        main_type=main_type,
        sub_type=sub_type,
        raised_by=raised_by,
    )
