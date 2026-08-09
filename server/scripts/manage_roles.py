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

# Must happen before importing models
env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(env_path)
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))


# Load .env from server/
env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(env_path)

# Add server/ to path so models can be imported
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))


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
    args = sys.argv[1:]

    if not args:
        print(__doc__)
        sys.exit(0)

    command = args[0].lower()
    db = get_db()

    try:
        if command == "list":
            cmd_list(db)

        elif command == "get":
            if len(args) < 2:
                print("Usage: manage_roles.py get <email>")
                sys.exit(1)
            cmd_get(db, args[1])

        elif command == "set":
            if len(args) < 3:
                print("Usage: manage_roles.py set <email> <role>")
                sys.exit(1)
            cmd_set(db, args[1], args[2])

        elif command == "deactivate":
            if len(args) < 2:
                print("Usage: manage_roles.py deactivate <email>")
                sys.exit(1)
            cmd_deactivate(db, args[1])

        elif command == "activate":
            if len(args) < 2:
                print("Usage: manage_roles.py activate <email>")
                sys.exit(1)
            cmd_activate(db, args[1])

        else:
            print(f"Unknown command: '{command}'")
            print(__doc__)
            sys.exit(1)

    finally:
        db.close()


if __name__ == "__main__":
    main()
