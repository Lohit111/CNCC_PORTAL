"""Request Type Models"""
from pydantic import BaseModel, Field
from typing import Optional, List
from sqlalchemy import Column, String, Integer, ForeignKey
from sqlalchemy.orm import relationship, Session
from models.base import Base


class MainTypeTable(Base):
    """SQLAlchemy MainType table"""
    __tablename__ = "main_types"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)

    sub_types = relationship(
        "SubTypeTable", back_populates="main_type", cascade="all, delete-orphan")


class SubTypeTable(Base):
    """SQLAlchemy SubType table"""
    __tablename__ = "sub_types"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    main_type_id = Column(Integer, ForeignKey(
        "main_types.id"), nullable=False, index=True)

    main_type = relationship("MainTypeTable", back_populates="sub_types")


class MainType(BaseModel):
    id: Optional[int] = Field(default=None)
    name: str = Field()

    class Config:
        from_attributes = True

    @staticmethod
    def from_orm(main_type_table: MainTypeTable) -> "MainType":
        """Convert SQLAlchemy model to Pydantic model"""
        return MainType(
            id=int(main_type_table.id) if main_type_table.id else None,
            name=str(main_type_table.name)
        )

    @staticmethod
    def create(db: Session, data: dict) -> "MainType":
        """Stage a new main type (caller must commit)"""
        main_type_table = MainTypeTable(**data)
        db.add(main_type_table)
        db.flush()
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
        """Stage an update (caller must commit)"""
        query = db.query(MainTypeTable)
        for key, value in filter.items():
            query = query.filter(getattr(MainTypeTable, key) == value)
        return query.update(data) > 0

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Stage a delete (caller must commit)"""
        query = db.query(MainTypeTable)
        for key, value in filter.items():
            query = query.filter(getattr(MainTypeTable, key) == value)
        return query.delete() > 0

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
        """Stage a new sub type (caller must commit)"""
        sub_type_table = SubTypeTable(**data)
        db.add(sub_type_table)
        db.flush()
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
        """Stage an update (caller must commit)"""
        query = db.query(SubTypeTable)
        for key, value in filter.items():
            query = query.filter(getattr(SubTypeTable, key) == value)
        return query.update(data) > 0

    @staticmethod
    def delete(db: Session, filter: dict) -> bool:
        """Stage a delete (caller must commit)"""
        query = db.query(SubTypeTable)
        for key, value in filter.items():
            query = query.filter(getattr(SubTypeTable, key) == value)
        return query.delete() > 0

    @staticmethod
    def delete_all(db: Session, filter: dict) -> int:
        """Stage bulk delete (caller must commit)"""
        query = db.query(SubTypeTable)
        for key, value in filter.items():
            query = query.filter(getattr(SubTypeTable, key) == value)
        return query.delete()

    @staticmethod
    def count(db: Session, filter: Optional[dict] = None) -> int:
        """Count sub types"""
        query = db.query(SubTypeTable)
        if filter:
            for key, value in filter.items():
                query = query.filter(getattr(SubTypeTable, key) == value)
        return query.count()
