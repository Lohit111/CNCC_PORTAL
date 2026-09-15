from typing import Optional
from datetime import datetime
from calendar import monthrange
from sqlalchemy.orm import Session
from sqlalchemy import func, cast, Date
from models.request import Request, RequestTable
from controllers.common.helpers import build_request_detail

def search_requests(db: Session, prefix: str) -> dict:
    """Return full request details for all requests whose ID starts with prefix.

    The search is case-insensitive and matches across all statuses.
    No pagination — the result set is expected to be small.
    """
    if not prefix or not prefix.strip():
        return {"requests": []}

    rows = (
        db.query(RequestTable)
        .filter(RequestTable.id.ilike(f"{prefix.strip()}%"))
        .order_by(RequestTable.updated_at.desc())
        .all()
    )

    requests = [Request.from_orm(r) for r in rows]

    return {
        "requests": [build_request_detail(db, r) for r in requests],
    }

def get_dashboard_stats(
    db: Session,
    id_prefix: Optional[str] = None,
    status: Optional[str] = None,
    room_no: Optional[str] = None,
    main_type: Optional[str] = None,
    sub_type: Optional[str] = None,
    raised_by: Optional[str] = None,
) -> dict:
    """Return daily/monthly/yearly request counts using DB-level aggregation.

    All filters are optional and applied before aggregation.

    Returns:
        {
            "daily": [
                {"date": "YYYY-MM-DD", "count": n},
                ...
            ],
            "monthly": [
                {"month": "YYYY-MM", "count": n},
                ...
            ],
            "yearly": [
                {"year": "YYYY", "count": n},
                ...
            ],
        }
    """

    now = datetime.utcnow()
    current_year = now.year
    current_month = now.month

    # ---------------------------------------------------------
    # Base query with optional filters
    # ---------------------------------------------------------
    def _base(db: Session):
        q = db.query(RequestTable)

        if id_prefix and id_prefix.strip():
            # Match first 8 characters case-insensitively.
            q = q.filter(
                func.lower(func.substr(RequestTable.id, 1, 8))
                == id_prefix.strip()[:8].lower()
            )

        if status:
            q = q.filter(RequestTable.status == status)

        if room_no:
            q = q.filter(RequestTable.room_no == room_no)

        if main_type:
            q = q.filter(RequestTable.main_type == main_type)

        if sub_type:
            q = q.filter(RequestTable.sub_type == sub_type)

        if raised_by:
            q = q.filter(RequestTable.raised_by == raised_by)

        return q

    # ---------------------------------------------------------
    # Calculate next month boundary
    # ---------------------------------------------------------
    if current_month == 12:
        next_month = datetime(current_year + 1, 1, 1)
    else:
        next_month = datetime(
            current_year,
            current_month + 1,
            1,
        )

    # ---------------------------------------------------------
    # Daily: current month
    # ---------------------------------------------------------
    daily_q = (
        _base(db)
        .filter(
            RequestTable.created_at >= datetime(
                current_year,
                current_month,
                1,
            ),
            RequestTable.created_at < next_month,
        )
        .with_entities(
            cast(
                RequestTable.created_at,
                Date,
            ).label("day"),
            func.count(RequestTable.id).label("cnt"),
        )
        .group_by(
            cast(
                RequestTable.created_at,
                Date,
            )
        )
        .all()
    )

    # Convert PostgreSQL date objects to the same string format
    # used by the response.
    daily_map = {
        row.day.strftime("%Y-%m-%d"): row.cnt
        for row in daily_q
    }

    # Fill missing days with 0.
    days_in_month = monthrange(
        current_year,
        current_month,
    )[1]

    daily = [
        {
            "date": f"{current_year}-{current_month:02d}-{day:02d}",
            "count": daily_map.get(
                f"{current_year}-{current_month:02d}-{day:02d}",
                0,
            ),
        }
        for day in range(1, days_in_month + 1)
    ]

    # ---------------------------------------------------------
    # Monthly: current year
    # ---------------------------------------------------------
    monthly_q = (
        _base(db)
        .filter(
            RequestTable.created_at >= datetime(
                current_year,
                1,
                1,
            ),
            RequestTable.created_at < datetime(
                current_year + 1,
                1,
                1,
            ),
        )
        .with_entities(
            func.date_trunc(
                "month",
                RequestTable.created_at,
            ).label("month"),
            func.count(RequestTable.id).label("cnt"),
        )
        .group_by(
            func.date_trunc(
                "month",
                RequestTable.created_at,
            )
        )
        .all()
    )

    # Convert PostgreSQL datetime values to YYYY-MM strings.
    monthly_map = {
        row.month.strftime("%Y-%m"): row.cnt
        for row in monthly_q
    }

    # Fill missing months with 0.
    monthly = [
        {
            "month": f"{current_year}-{month:02d}",
            "count": monthly_map.get(
                f"{current_year}-{month:02d}",
                0,
            ),
        }
        for month in range(1, 13)
    ]

    # ---------------------------------------------------------
    # Yearly: all years present in DB
    # ---------------------------------------------------------
    yearly_q = (
        _base(db)
        .with_entities(
            func.extract(
                "year",
                RequestTable.created_at,
            ).label("year"),
            func.count(RequestTable.id).label("cnt"),
        )
        .group_by(
            func.extract(
                "year",
                RequestTable.created_at,
            )
        )
        .order_by(
            func.extract(
                "year",
                RequestTable.created_at,
            ).desc()
        )
        .all()
    )

    # Convert PostgreSQL numeric year to String for Flutter.
    yearly = [
        {
            "year": str(int(row.year)),
            "count": row.cnt,
        }
        for row in yearly_q
    ]

    # ---------------------------------------------------------
    # Final response
    # ---------------------------------------------------------
    return {
        "daily": daily,
        "monthly": monthly,
        "yearly": yearly,
    }