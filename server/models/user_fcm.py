"""User FCM Token Model"""
from pydantic import BaseModel, Field
from typing import List, Tuple
import uuid
from sqlalchemy import Column, String, UniqueConstraint, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Session
from models.base import Base
from models.enums import DevicePlatform


class UserFcmTable(Base):
    """SQLAlchemy table for storing user FCM tokens.

    Maintains a unique (user_id, fcm_token) pair so the same token is
    never duplicated for a given user while still allowing multiple
    devices per user.
    """

    __tablename__ = "user_fcm_tokens"

    id = Column(
        String,
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
        index=True,
    )
    user_id = Column(
        String,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    fcm_token = Column(String, nullable=False)
    platform = Column(
        SAEnum(DevicePlatform),
        nullable=False,
        default=DevicePlatform.UNKNOWN,
    )

    __table_args__ = (
        UniqueConstraint("user_id", "fcm_token", name="uq_user_fcm_token"),
    )


class UserFcm(BaseModel):
    id: str = Field()
    user_id: str = Field()
    fcm_token: str = Field()
    platform: DevicePlatform = Field(default=DevicePlatform.UNKNOWN)

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(row: UserFcmTable) -> "UserFcm":
        return UserFcm(
            id=str(row.id),
            user_id=str(row.user_id),
            fcm_token=str(row.fcm_token),
            platform=row.platform or DevicePlatform.UNKNOWN,
        )

    @staticmethod
    def upsert(
        db: Session,
        user_id: str,
        fcm_token: str,
        platform: DevicePlatform = DevicePlatform.UNKNOWN,
    ) -> "UserFcm":
        """Insert or update the (user_id, fcm_token) pair.

        If the token already exists for this user, updates its platform.
        Caller must commit.
        """
        existing = (
            db.query(UserFcmTable)
            .filter(
                UserFcmTable.user_id == user_id,
                UserFcmTable.fcm_token == fcm_token,
            )
            .first()
        )
        if existing:
            existing.platform = platform # pyright: ignore[reportAttributeAccessIssue]
            db.flush()
            return UserFcm.from_orm(existing)

        row = UserFcmTable(
            user_id=user_id, fcm_token=fcm_token, platform=platform)
        db.add(row)
        db.flush()
        return UserFcm.from_orm(row)

    @staticmethod
    def delete_token(db: Session, user_id: str, fcm_token: str) -> bool:
        """Remove a specific token for a user. Caller must commit."""
        deleted = (
            db.query(UserFcmTable)
            .filter(
                UserFcmTable.user_id == user_id,
                UserFcmTable.fcm_token == fcm_token,
            )
            .delete()
        )
        return deleted > 0

    @staticmethod
    def delete_tokens(db: Session, fcm_tokens: List[str]) -> int:
        """Remove all rows whose fcm_token is in the given list.

        Used to purge invalid/unregistered tokens discovered during a send.
        Caller must commit.
        """
        if not fcm_tokens:
            return 0
        deleted = (
            db.query(UserFcmTable)
            .filter(UserFcmTable.fcm_token.in_(fcm_tokens))
            .delete(synchronize_session=False)
        )
        return deleted
