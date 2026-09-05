"""
manage_roles.py — CLI tool to manage user roles directly in the database.

Usage (run from server/ directory):
    python scripts/manage_roles.py list
    python scripts/manage_roles.py get <email>
    python scripts/manage_roles.py set <email> <role>
    python scripts/manage_roles.py deactivate <email>
    python scripts/manage_roles.py activate <email>

Roles: USER | ADMIN | STAFF | STORE
"""

from models.enums import UserRole
from models.user import UserTable
from config.database import SessionLocal
import sys
import os
from pathlib import Path
from dotenv import load_dotenv


env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(env_path)

# Add current directory to path
sys.path.insert(0, str(Path(__file__).resolve().parent))

VALID_ROLES = [r.value for r in UserRole]


def get_db():
    db = SessionLocal()
    try:
        return db
    except Exception:
        db.close()
        raise


def cmd_list(db):
    """List all users with their roles"""
    users = db.query(UserTable).order_by(UserTable.role, UserTable.email).all()
    if not users:
        print("No users found.")
        return
    print(f"\n{'EMAIL':<40} {'ROLE':<10} {'ACTIVE'}")
    print("-" * 60)
    for u in users:
        active = "✓" if u.is_active else "✗"
        print(f"{u.email:<40} {u.role.value:<10} {active}")
    print(f"\nTotal: {len(users)} users")


def cmd_get(db, email: str):
    """Get a user's current role"""
    user = db.query(UserTable).filter(UserTable.email == email).first()
    if not user:
        print(f"No user found with email: {email}")
        return
    print(f"\nEmail:     {user.email}")
    print(f"Name:      {user.name or '—'}")
    print(f"Role:      {user.role.value}")
    print(f"Active:    {'Yes' if user.is_active else 'No'}")
    print(f"ID:        {user.id}")


def cmd_create(db):
    """Create a new user"""

    email = input("Email: ").strip()
    name = input("Name: ").strip()

    existing = db.query(UserTable).filter(UserTable.email == email).first()
    if existing:
        print(f"User already exists: {email}")
        return

    role = input(
        f"Role ({', '.join(VALID_ROLES)}): "
    ).strip().upper()

    if role not in VALID_ROLES:
        print(f"Invalid role. Valid roles: {', '.join(VALID_ROLES)}")
        return

    user = UserTable(
        email=email,
        name=name if name else None,
        role=UserRole(role),
        is_active=True
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    print(f"✓ Created user: {email}")
    print(f"  Role: {role}")
    print(f"  ID: {user.id}")


def cmd_set(db, email: str, role: str):
    """Set a user's role"""
    role = role.upper()
    if role not in VALID_ROLES:
        print(f"Invalid role '{role}'. Valid roles: {', '.join(VALID_ROLES)}")
        sys.exit(1)

    user = db.query(UserTable).filter(UserTable.email == email).first()
    if not user:
        print(f"No user found with email: {email}")
        sys.exit(1)

    old_role = user.role.value
    user.role = UserRole(role)
    db.commit()
    print(f"✓ Updated {email}: {old_role} → {role}")


def cmd_deactivate(db, email: str):
    """Deactivate a user (soft delete)"""
    user = db.query(UserTable).filter(UserTable.email == email).first()
    if not user:
        print(f"No user found with email: {email}")
        sys.exit(1)
    if not user.is_active:
        print(f"{email} is already inactive.")
        return
    user.is_active = False
    db.commit()
    print(f"✓ Deactivated {email}")


def cmd_activate(db, email: str):
    """Reactivate a deactivated user"""
    user = db.query(UserTable).filter(UserTable.email == email).first()
    if not user:
        print(f"No user found with email: {email}")
        sys.exit(1)
    if user.is_active:
        print(f"{email} is already active.")
        return
    user.is_active = True
    db.commit()
    print(f"✓ Activated {email}")


def main():
    db = get_db()

    try:
        while True:
            print("""
=============================
     User Role Manager
=============================
1. List users
2. Get user details
3. Create user
4. Set user role
5. Deactivate user
6. Activate user
7. Exit
""")

            choice = input("Select option: ").strip()

            if choice == "1":
                cmd_list(db)

            elif choice == "2":
                email = input("Enter email: ").strip()
                cmd_get(db, email)

            elif choice == "3":
                cmd_create(db)

            elif choice == "4":
                email = input("Enter email: ").strip()
                role = input(
                    f"Enter role ({', '.join(VALID_ROLES)}): "
                ).strip()
                cmd_set(db, email, role)

            elif choice == "5":
                email = input("Enter email: ").strip()
                cmd_deactivate(db, email)

            elif choice == "6":
                email = input("Enter email: ").strip()
                cmd_activate(db, email)

            elif choice == "7":
                print("Exiting...")
                break

            else:
                print("Invalid option.")

    finally:
        db.close()


if __name__ == "__main__":
    main()
