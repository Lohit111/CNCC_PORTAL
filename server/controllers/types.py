"""Request Type Controller"""
from sqlalchemy.orm import Session
from fastapi import HTTPException
from models.request_type import MainType, SubType


# --- Main Type ---

def get_main_types(db: Session) -> list:
    """Get all main types"""
    return MainType.find(db)


def create_main_type(db: Session, name: str) -> MainType:
    """Create a new main type"""
    existing = MainType.get(db, {"name": name})
    if existing:
        raise HTTPException(
            status_code=409, detail="Main type with this name already exists")
    main_type = MainType.create(db, {"name": name})
    db.commit()
    return main_type


def update_main_type(db: Session, main_id: int, name: str) -> MainType:
    """Update the name of a main type"""
    main_type = MainType.get(db, {"id": main_id})
    if not main_type:
        raise HTTPException(status_code=404, detail="Main type not found")
    existing = MainType.get(db, {"name": name})
    if existing and existing.id != main_id:
        raise HTTPException(
            status_code=409, detail="Main type with this name already exists")
    MainType.update(db, {"id": main_id}, {"name": name})
    db.commit()
    return MainType.get(db, {"id": main_id}) # pyright: ignore[reportReturnType]


def delete_main_type(db: Session, main_id: int) -> bool:
    """Delete a main type (cascades to sub types)"""
    main_type = MainType.get(db, {"id": main_id})
    if not main_type:
        raise HTTPException(status_code=404, detail="Main type not found")
    MainType.delete(db, {"id": main_id})
    db.commit()
    return True


# --- Sub Type ---

def get_sub_types(db: Session, main_id: int) -> list:
    """Get all sub types for a given main type"""
    main_type = MainType.get(db, {"id": main_id})
    if not main_type:
        raise HTTPException(status_code=404, detail="Main type not found")
    return SubType.find(db, {"main_type_id": main_id})


def create_sub_type(db: Session, main_id: int, name: str) -> SubType:
    """Create a new sub type under a main type"""
    main_type = MainType.get(db, {"id": main_id})
    if not main_type:
        raise HTTPException(status_code=404, detail="Main type not found")
    sub_type = SubType.create(db, {"name": name, "main_type_id": main_id})
    db.commit()
    return sub_type


def update_sub_type(db: Session, sub_id: int, name: str) -> SubType:
    """Update the name of a sub type"""
    sub_type = SubType.get(db, {"id": sub_id})
    if not sub_type:
        raise HTTPException(status_code=404, detail="Sub type not found")
    SubType.update(db, {"id": sub_id}, {"name": name})
    db.commit()
    return SubType.get(db, {"id": sub_id}) # pyright: ignore[reportReturnType]


def delete_sub_type(db: Session, sub_id: int) -> bool:
    """Delete a sub type"""
    sub_type = SubType.get(db, {"id": sub_id})
    if not sub_type:
        raise HTTPException(status_code=404, detail="Sub type not found")
    SubType.delete(db, {"id": sub_id})
    db.commit()
    return True
