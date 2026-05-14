import sys
import time
import argparse

import sqlalchemy
from config.database import SessionLocal
from models.role import Role

# ---------------------------------------------------------------------------
# Hardcoded seed list — same format as update_roles.py
# ---------------------------------------------------------------------------
SEED_ROLES: dict[str, str] = {
    "sailohit948@gmail.com": "USER",
    "lingalalohit@gmail.com": "ADMIN",
    "24071a12f5@vnrvjiet.in": "STAFF",
}

VALID_ROLES = {"USER", "ADMIN", "STAFF", "STORE"}

# ---------------------------------------------------------------------------
# DB helpers
# ---------------------------------------------------------------------------


def _wait_for_db() -> object:
    """Wait up to 10 attempts for the database to be ready and return a session."""
    for attempt in range(10):
        try:
            db = SessionLocal()
            db.execute(sqlalchemy.text("SELECT 1"))
            return db
        except Exception as e:
            print(f"  Waiting for database… ({attempt + 1}/10): {e}")
            try:
                db.close()
            except Exception:
                pass
            time.sleep(2)
    print("Database not ready after 10 attempts. Exiting.")
    raise SystemExit(1)


# ---------------------------------------------------------------------------
# Core operations (return plain dicts / None so the CLI can pretty-print)
# ---------------------------------------------------------------------------

def cmd_list(db) -> None:
    roles = Role.find(db)
    total = Role.count(db)
    if not roles:
        print("  (no roles found)")
        return
    print(f"\n  {'EMAIL':<40} {'ROLE':<10} {'CREATED'}")
    print("  " + "-" * 70)
    for r in roles:
        print(
            f"  {r.email:<40} {r.role:<10} {r.created_at.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"\n  Total: {total}")


def cmd_get(db, email: str) -> None:
    role = Role.get(db, {"email": email})
    if not role:
        print(f"  Role not found for: {email}")
        return
    print(f"\n  Email   : {role.email}")
    print(f"  Role    : {role.role}")
    print(f"  Created : {role.created_at.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"  Updated : {role.updated_at.strftime('%Y-%m-%d %H:%M:%S')}")


def cmd_create(db, email: str, role_value: str) -> None:
    role_value = role_value.upper()
    if role_value not in VALID_ROLES:
        print(
            f"  Invalid role '{role_value}'. Valid roles: {', '.join(sorted(VALID_ROLES))}")
        return
    existing = Role.get(db, {"email": email})
    if existing:
        print(
            f"  Role already exists for {email} ({existing.role}). Use 'update' to change it.")
        return
    Role.create(db, {"email": email, "role": role_value})
    print(f"  Created: {email} -> {role_value}")


def cmd_update(db, email: str, role_value: str) -> None:
    role_value = role_value.upper()
    if role_value not in VALID_ROLES:
        print(
            f"  Invalid role '{role_value}'. Valid roles: {', '.join(sorted(VALID_ROLES))}")
        return
    existing = Role.get(db, {"email": email})
    if not existing:
        print(f"  No role found for {email}. Use 'create' to add one.")
        return
    Role.update(db, {"email": email}, {"role": role_value})
    print(f"  Updated: {email} -> {role_value}  (was: {existing.role})")


def cmd_delete(db, email: str) -> None:
    existing = Role.get(db, {"email": email})
    if not existing:
        print(f"  No role found for {email}.")
        return
    confirm = input(
        f"  Delete role for '{email}' ({existing.role})? [y/N]: ").strip().lower()
    if confirm != "y":
        print("  Cancelled.")
        return
    Role.delete(db, {"email": email})
    print(f"  Deleted: {email}")


def cmd_seed(db) -> None:
    print(f"\n  Seeding {len(SEED_ROLES)} role(s)…")
    for email, role_value in SEED_ROLES.items():
        existing = Role.get(db, {"email": email})
        if existing:
            Role.update(db, {"email": email}, {"role": role_value})
            print(
                f"  Updated : {email} -> {role_value}  (was: {existing.role})")
        else:
            Role.create(db, {"email": email, "role": role_value})
            print(f"  Created : {email} -> {role_value}")
    print("  Done.")


# ---------------------------------------------------------------------------
# Interactive menu
# ---------------------------------------------------------------------------

def _prompt(msg: str, required: bool = True) -> str:
    while True:
        value = input(msg).strip()
        if value or not required:
            return value
        print("  (cannot be empty)")


def _pick_role() -> str:
    roles_list = sorted(VALID_ROLES)
    for i, r in enumerate(roles_list, 1):
        print(f"  {i}. {r}")
    while True:
        choice = input("  Select role number: ").strip()
        if choice.isdigit() and 1 <= int(choice) <= len(roles_list):
            return roles_list[int(choice) - 1]
        print("  Invalid choice. Try again.")


MENU = """
╔══════════════════════════════╗
║     Role Manager — Menu      ║
╠══════════════════════════════╣
║  1. List all roles           ║
║  2. Get role by email        ║
║  3. Create role              ║
║  4. Update role              ║
║  5. Delete role              ║
║  6. Seed hardcoded roles     ║
║  0. Exit                     ║
╚══════════════════════════════╝
"""


def interactive_menu(db) -> None:
    while True:
        print(MENU)
        choice = input("Choice: ").strip()

        if choice == "0":
            print("Bye!")
            break

        elif choice == "1":
            cmd_list(db)

        elif choice == "2":
            email = _prompt("  Email: ")
            cmd_get(db, email)

        elif choice == "3":
            email = _prompt("  Email: ")
            print("  Available roles:")
            role_value = _pick_role()
            cmd_create(db, email, role_value)

        elif choice == "4":
            email = _prompt("  Email: ")
            print("  Available roles:")
            role_value = _pick_role()
            cmd_update(db, email, role_value)

        elif choice == "5":
            email = _prompt("  Email: ")
            cmd_delete(db, email)

        elif choice == "6":
            cmd_seed(db)

        else:
            print("  Unknown choice. Please enter 0–6.")

        input("\n  Press Enter to continue…")


# ---------------------------------------------------------------------------
# CLI entry-point
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="manage_roles",
        description="Manage roles in the CNCC Portal database.",
    )
    sub = parser.add_subparsers(dest="command")

    sub.add_parser("list", help="List all roles")

    p_get = sub.add_parser("get", help="Get role by email")
    p_get.add_argument("email")

    p_create = sub.add_parser("create", help="Create a new role")
    p_create.add_argument("email")
    p_create.add_argument("role", choices=sorted(VALID_ROLES))

    p_update = sub.add_parser("update", help="Update an existing role")
    p_update.add_argument("email")
    p_update.add_argument("role", choices=sorted(VALID_ROLES))

    p_delete = sub.add_parser("delete", help="Delete a role")
    p_delete.add_argument("email")

    sub.add_parser("seed", help="Upsert hardcoded SEED_ROLES")
    sub.add_parser("interactive", help="Launch the interactive menu (default)")

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    print("Connecting to database…")
    db = _wait_for_db()

    try:
        command = args.command or "interactive"

        if command == "list":
            cmd_list(db)

        elif command == "get":
            cmd_get(db, args.email)

        elif command == "create":
            cmd_create(db, args.email, args.role)

        elif command == "update":
            cmd_update(db, args.email, args.role)

        elif command == "delete":
            # Non-interactive delete from CLI — skip confirm prompt
            existing = Role.get(db, {"email": args.email})
            if not existing:
                print(f"  No role found for {args.email}.")
            else:
                Role.delete(db, {"email": args.email})
                print(f"  Deleted: {args.email}")

        elif command == "seed":
            cmd_seed(db)

        elif command == "interactive":
            interactive_menu(db)

    finally:
        db.close() # type: ignore


if __name__ == "__main__":
    main()
