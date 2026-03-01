"""User Management Script - Add, Update, or Delete User Roles"""
import sys
import re
from config.database import SessionLocal
from models.role import Role

# Hardcoded list of users to add
USERS_TO_ADD = {
    "sailohit948@gmail.com": "USER",
}

VALID_ROLES = ["USER", "ADMIN", "STAFF", "STORE"]


def is_valid_email(email: str) -> bool:
    """Validate email format"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def add_users():
    """Add users from hardcoded list"""
    db = SessionLocal()
    try:
        print("\n" + "="*60)
        print("ADDING USERS FROM HARDCODED LIST")
        print("="*60 + "\n")

        added_count = 0
        skipped_count = 0

        for email, role in USERS_TO_ADD.items():
            # Validate email
            if not is_valid_email(email):
                print(f"✗ {email} - Invalid email format, skipping")
                skipped_count += 1
                continue

            # Check if role already exists
            existing_role = Role.get(db, {"email": email})

            if existing_role:
                print(
                    f"⚠ {email} - Already exists with role: {existing_role.role}")
                skipped_count += 1
            else:
                # Create new role
                Role.create(db, {"email": email, "role": role})
                print(f"✓ {email} - Added with role: {role}")
                added_count += 1

        print(f"\n{'='*60}")
        print(f"Summary: {added_count} added, {skipped_count} skipped")
        print(f"{'='*60}\n")

    except Exception as e:
        print(f"\n✗ Error: {str(e)}")
        sys.exit(1)
    finally:
        db.close()


def list_all_users():
    """List all users in the database"""
    db = SessionLocal()
    try:
        roles = Role.find(db)

        if not roles:
            print("\n⚠ No users found in database\n")
            return []

        print("\n" + "="*60)
        print("ALL USERS IN DATABASE")
        print("="*60)
        print(f"{'#':<5} {'Email':<35} {'Role':<10}")
        print("-"*60)

        for idx, role in enumerate(roles, 1):
            print(f"{idx:<5} {role.email:<35} {role.role:<10}")

        print("="*60 + "\n")
        return roles

    except Exception as e:
        print(f"\n✗ Error: {str(e)}")
        return []
    finally:
        db.close()


def update_user(email: str, new_role: str):
    """Update user's role"""
    db = SessionLocal()
    try:
        # Validate new role
        if new_role not in VALID_ROLES:
            print(f"\n✗ Invalid role: {new_role}")
            print(f"Valid roles: {', '.join(VALID_ROLES)}\n")
            return

        # Check if user exists
        existing_role = Role.get(db, {"email": email})
        if not existing_role:
            print(f"\n✗ User {email} not found\n")
            return

        # Update role
        Role.update(db, {"email": email}, {"role": new_role})
        print(f"\n✓ Updated {email} from {existing_role.role} to {new_role}\n")

    except Exception as e:
        print(f"\n✗ Error: {str(e)}\n")
    finally:
        db.close()


def delete_user(email: str):
    """Delete user's role"""
    db = SessionLocal()
    try:
        # Check if user exists
        existing_role = Role.get(db, {"email": email})
        if not existing_role:
            print(f"\n✗ User {email} not found\n")
            return

        # Confirm deletion
        confirm = input(
            f"\n⚠ Are you sure you want to delete {email} ({existing_role.role})? (yes/no): ").strip().lower()

        if confirm == "yes":
            Role.delete(db, {"email": email})
            print(f"\n✓ Deleted {email}\n")
        else:
            print(f"\n✗ Deletion cancelled\n")

    except Exception as e:
        print(f"\n✗ Error: {str(e)}\n")
    finally:
        db.close()


def manage_users():
    """Interactive user management"""
    while True:
        users = list_all_users()

        if not users:
            print("No users to manage. Exiting...\n")
            break

        print("Options:")
        print("  - Enter user number to select")
        print("  - Type 'quit' to exit")

        choice = input("\nYour choice: ").strip()

        if choice.lower() == 'quit':
            print("\nExiting user management...\n")
            break

        # Try to parse as number
        try:
            user_idx = int(choice) - 1
            if user_idx < 0 or user_idx >= len(users):
                print(
                    f"\n✗ Invalid selection. Please enter a number between 1 and {len(users)}\n")
                continue

            selected_user = users[user_idx]

            # Show selected user
            print(f"\n{'='*60}")
            print(f"Selected User: {selected_user.email}")
            print(f"Current Role: {selected_user.role}")
            print(f"{'='*60}")

            # Ask for action
            print("\nWhat would you like to do?")
            print("  1. Update role")
            print("  2. Delete user")
            print("  3. Cancel")

            action = input("\nEnter choice (1/2/3): ").strip()

            if action == "1":
                # Update role
                print(f"\nValid roles: {', '.join(VALID_ROLES)}")
                new_role = input("Enter new role: ").strip().upper()
                update_user(selected_user.email, new_role)

            elif action == "2":
                # Delete user
                delete_user(selected_user.email)

            elif action == "3":
                print("\n✗ Action cancelled\n")

            else:
                print("\n✗ Invalid choice\n")

        except ValueError:
            print(f"\n✗ Invalid input. Please enter a number or 'quit'\n")


def main():
    """Main function"""
    print("\n" + "="*60)
    print("USER MANAGEMENT TOOL")
    print("="*60)
    print("\nWhat would you like to do?")
    print("  1. Add users from hardcoded list")
    print("  2. Manage existing users (update/delete)")
    print("  3. Exit")

    choice = input("\nEnter choice (1/2/3): ").strip()

    if choice == "1":
        add_users()
    elif choice == "2":
        manage_users()
    elif choice == "3":
        print("\nExiting...\n")
        sys.exit(0)
    else:
        print("\n✗ Invalid choice\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
