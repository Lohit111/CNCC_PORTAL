"""Department Controller"""
from fastapi import HTTPException
from sqlalchemy.orm import Session
from models.department import Department


def get_departments(db: Session):
    """Return all departments ordered alphabetically"""
    return Department.find(db)


def create_department(db: Session, department: str) -> Department:
    """Create a new department, enforcing uniqueness"""
    if Department.get(db, {"department": department.strip()}):
        raise HTTPException(
            status_code=409,
            detail=f"Department '{department}' already exists",
        )
    dept = Department.create(db, department=department.strip())
    db.commit()
    return dept


def update_department(db: Session, dept_id: int, department: str) -> Department:
    """Update a department's name, enforcing uniqueness"""
    existing = Department.get(db, {"id": dept_id})
    if not existing:
        raise HTTPException(status_code=404, detail="Department not found")

    conflict = Department.get(db, {"department": department.strip()})
    if conflict and conflict.id != dept_id:
        raise HTTPException(
            status_code=409,
            detail=f"Department '{department}' already exists",
        )

    Department.update(db, dept_id=dept_id, department=department.strip())
    db.commit()
    return Department.get(db, {"id": dept_id})  # pyright: ignore[reportReturnType]


def delete_department(db: Session, dept_id: int) -> None:
    """Delete a department by ID"""
    if not Department.get(db, {"id": dept_id}):
        raise HTTPException(status_code=404, detail="Department not found")
    Department.delete(db, dept_id=dept_id)
    db.commit()
