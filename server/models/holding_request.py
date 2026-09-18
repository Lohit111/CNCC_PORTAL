"""Holding Request Model"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import uuid
from sqlalchemy import Column, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship, Session
from models.base import Base


class HoldingRequestTable(Base):
    """SQLAlchemy table for requests currently on hold"""
    __tablename__ = "holding_requests"

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
        unique=True,
        index=True,
    )

    hold_until = Column(
        DateTime,
        nullable=False,
        index=True,
    )

    request = relationship("RequestTable", back_populates="holding")


class HoldingRequest(BaseModel):
    id: Optional[str] = Field(default=None)
    request_id: str = Field()
    hold_until: datetime = Field()

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(holding_request_table: HoldingRequestTable) -> "HoldingRequest":
        """Convert SQLAlchemy model to Pydantic model"""
        return HoldingRequest(
            id=str(holding_request_table.id) if holding_request_table.id else None,
            request_id=str(holding_request_table.request_id),
            hold_until=holding_request_table.hold_until,
        )

    @staticmethod
    def create(db: Session, data: dict) -> "HoldingRequest":
        """Create a new holding request record (caller must commit)"""
        if "id" not in data:
            data["id"] = str(uuid.uuid4())
        holding_request_table = HoldingRequestTable(**data)
        db.add(holding_request_table)
        db.flush()
        return HoldingRequest.from_orm(holding_request_table)

    @staticmethod
    def get(db: Session, filter: dict) -> Optional["HoldingRequest"]:
        """Get a single holding request by filter"""
        query = db.query(HoldingRequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(HoldingRequestTable, key) == value)
        holding_request_table = query.first()
        return HoldingRequest.from_orm(holding_request_table) if holding_request_table else None

    @staticmethod
    def get_raw(db: Session, filter: dict) -> Optional[HoldingRequestTable]:
        """Get raw SQLAlchemy object"""
        query = db.query(HoldingRequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(HoldingRequestTable, key) == value)
        return query.first()

    @staticmethod
    def find_expired(db: Session) -> list:
        """Find all holding requests where hold_until <= NOW()"""
        query = (
            db.query(HoldingRequestTable)
            .filter(HoldingRequestTable.hold_until <= datetime.utcnow())
            .all()
        )
        return query

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Delete a holding request (caller must commit)"""
        query = db.query(HoldingRequestTable)
        for key, value in filter.items():
            query = query.filter(getattr(HoldingRequestTable, key) == value)
        return query.delete() > 0
