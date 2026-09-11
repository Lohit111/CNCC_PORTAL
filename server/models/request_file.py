"""Request File Model"""

from datetime import datetime
from typing import List

import uuid

from pydantic import BaseModel, Field
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Session

from models.base import Base


class RequestFileTable(Base):
    """SQLAlchemy table for files attached to a request.

    The actual file bytes are stored in MinIO.

    file_ref stores the MinIO object key, for example:
        requests/<request_id>/<uuid>_<filename>
    """

    __tablename__ = "request_files"

    id = Column(
        String,
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
        index=True,
    )

    request_id = Column(
        String,
        ForeignKey("requests.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    file_ref = Column(
        String,
        nullable=False,
    )

    file_name = Column(
        String,
        nullable=False,
    )

    content_type = Column(
        String,
        nullable=False,
        default="application/octet-stream",
    )

    file_size = Column(
        Integer,
        nullable=False,
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )


class RequestFile(BaseModel):
    """API representation of a request attachment."""

    id: str
    request_id: str
    file_ref: str
    file_name: str
    content_type: str
    file_size: int
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(row: RequestFileTable) -> "RequestFile":
        return RequestFile(
            id=str(row.id),
            request_id=str(row.request_id),
            file_ref=str(row.file_ref),
            file_name=row.file_name,
            content_type=row.content_type,
            file_size=row.file_size,
            created_at=row.created_at,
        )

    @staticmethod
    def create(
        db: Session,
        request_id: str,
        file_ref: str,
        file_name: str,
        content_type: str,
        file_size: int,
    ) -> "RequestFile":
        """Stage a new file record. Caller must commit."""

        row = RequestFileTable(
            request_id=request_id,
            file_ref=file_ref,
            file_name=file_name,
            content_type=content_type,
            file_size=file_size,
        )

        db.add(row)
        db.flush()

        return RequestFile.from_orm(row)

    @staticmethod
    def find_by_request(
        db: Session,
        request_id: str,
    ) -> List["RequestFile"]:
        """Return all files attached to a request."""

        rows = (
            db.query(RequestFileTable)
            .filter(RequestFileTable.request_id == request_id)
            .order_by(RequestFileTable.created_at.asc())
            .all()
        )

        return [
            RequestFile.from_orm(row)
            for row in rows
        ]

    @staticmethod
    def get_by_id(
        db: Session,
        file_id: str,
        request_id: str,
    ) -> "RequestFile | None":
        """Return a single file record belonging to the given request, or None."""

        row = (
            db.query(RequestFileTable)
            .filter(
                RequestFileTable.id == file_id,
                RequestFileTable.request_id == request_id,
            )
            .first()
        )

        return RequestFile.from_orm(row) if row else None

    @staticmethod
    def delete_by_request(
        db: Session,
        request_id: str,
    ) -> int:
        """Remove all file records for a request."""

        return (
            db.query(RequestFileTable)
            .filter(RequestFileTable.request_id == request_id)
            .delete(synchronize_session=False)
        )