"""Request Type Models"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from sqlalchemy import Column, String, Integer, ForeignKey, DateTime
from sqlalchemy.orm import relationship, Session
from models.user import Base


class MainTypeTable(Base):
    """SQLAlchemy MainType table"""
    __tablename__ = "main_types"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    created_by = Column(String, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    sub_types = relationship("SubTypeTable", back_populates="main_type", cascade="all, delete-orphan")
    requests = relationship("RequestTable", back_populates="main_type")


class SubTypeTable(Base):
    """SQLAlchemy SubType table"""
    __tablename__ = "sub_types"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    main_type_id = Column(Integer, ForeignKey("main_types.id"), nullable=False, index=True)

    main_type = relationship("MainTypeTable", back_populates="sub_types")
    requests = relationship("RequestTable", back_populates="sub_type")


class MainType(BaseModel):
    id: Optional[int] = Field(default=None)
    name: str = Field()
    created_by: str = Field()
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(main_type_table: MainTypeTable) -> "MainType":
        """Convert SQLAlchemy model to Pydantic model"""
        return MainType(
            id=int(main_type_table.id) if main_type_table.id else None,
            name=str(main_type_table.name),
            created_by=str(main_type_table.created_by),
            created_at=main_type_table.created_at
        )

    @staticmethod
    def create(db: Session, data: dict) -> "MainType":
        """Create a new main type"""
        main_type_table = MainTypeTable(**data)
        db.add(main_type_table)
        db.commit()
        db.refresh(main_type_table)
        return MainType.from_orm(main_type_table)

    @staticmethod
    def get(db: Session, filter: dict) -> Optional["MainType"]:
        """Get a single main type by filter"""
        query = db.query(MainTypeTable)
        for key, value in filter.items():
            query = query.filter(getattr(MainTypeTable, key) == value)
        main_type_table = query.first()
        return MainType.from_orm(main_type_table) if main_type_table else None

    @staticmethod
    def get_raw(db: Session, filter: dict) -> Optional[MainTypeTable]:
        """Get raw SQLAlchemy object"""
        query = db.query(MainTypeTable)
        for key, value in filter.items():
            query = query.filter(getattr(MainTypeTable, key) == value)
        return query.first()

    @staticmethod
    def find(db: Session, filter: Optional[dict] = None, skip: int = 0, limit: Optional[int] = None) -> List["MainType"]:
        """Find multiple main types"""
        query = db.query(MainTypeTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(MainTypeTable, key) == value)
        query = query.offset(skip)
        if limit:
            query = query.limit(limit)
        return [MainType.from_orm(mt) for mt in query.all()]

    @staticmethod
    def update(db: Session, filter: dict, data: dict) -> bool:
        """Update main type"""
        query = db.query(MainTypeTable)
        for key, value in filter.items():
            query = query.filter(getattr(MainTypeTable, key) == value)
        result = query.update(data)
        db.commit()
        return result > 0

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Delete main type"""
        query = db.query(MainTypeTable)
        for key, value in filter.items():
            query = query.filter(getattr(MainTypeTable, key) == value)
        result = query.delete()
        db.commit()
        return result > 0

    @staticmethod
    def count(db: Session, filter: Optional[dict] = None) -> int:
        """Count main types"""
        query = db.query(MainTypeTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(MainTypeTable, key) == value)
        return query.count()


class SubType(BaseModel):
    id: Optional[int] = Field(default=None)
    name: str = Field()
    main_type_id: int = Field()

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(sub_type_table: SubTypeTable) -> "SubType":
        """Convert SQLAlchemy model to Pydantic model"""
        return SubType(
            id=int(sub_type_table.id) if sub_type_table.id else None,
            name=str(sub_type_table.name),
            main_type_id=int(sub_type_table.main_type_id)
        )

    @staticmethod
    def create(db: Session, data: dict) -> "SubType":
        """Create a new sub type"""
        sub_type_table = SubTypeTable(**data)
        db.add(sub_type_table)
        db.commit()
        db.refresh(sub_type_table)
        return SubType.from_orm(sub_type_table)

    @staticmethod
    def get(db: Session, filter: dict) -> Optional["SubType"]:
        """Get a single sub type by filter"""
        query = db.query(SubTypeTable)
        for key, value in filter.items():
            query = query.filter(getattr(SubTypeTable, key) == value)
        sub_type_table = query.first()
        return SubType.from_orm(sub_type_table) if sub_type_table else None

    @staticmethod
    def get_raw(db: Session, filter: dict) -> Optional[SubTypeTable]:
        """Get raw SQLAlchemy object"""
        query = db.query(SubTypeTable)
        for key, value in filter.items():
            query = query.filter(getattr(SubTypeTable, key) == value)
        return query.first()

    @staticmethod
    def find(db: Session, filter: Optional[dict] = None, skip: int = 0, limit: Optional[int] = None) -> List["SubType"]:
        """Find multiple sub types"""
        query = db.query(SubTypeTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(SubTypeTable, key) == value)
        query = query.offset(skip)
        if limit:
            query = query.limit(limit)
        return [SubType.from_orm(st) for st in query.all()]

    @staticmethod
    def update(db: Session, filter: dict, data: dict) -> bool:
        """Update sub type"""
        query = db.query(SubTypeTable)
        for key, value in filter.items():
            query = query.filter(getattr(SubTypeTable, key) == value)
        result = query.update(data)
        db.commit()
        return result > 0

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Delete sub type"""
        query = db.query(SubTypeTable)
        for key, value in filter.items():
            query = query.filter(getattr(SubTypeTable, key) == value)
        result = query.delete()
        db.commit()
        return result > 0

    @staticmethod
    def delete_all(db: Session, filter: dict) -> int:
        """Delete multiple sub types"""
        query = db.query(SubTypeTable)
        for key, value in filter.items():
            query = query.filter(getattr(SubTypeTable, key) == value)
        result = query.delete()
        db.commit()
        return result

    @staticmethod
    def count(db: Session, filter: Optional[dict] = None) -> int:
        """Count sub types"""
        query = db.query(SubTypeTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(SubTypeTable, key) == value)
        return query.count()
