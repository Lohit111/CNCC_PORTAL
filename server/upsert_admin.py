"""Create the admin user if it does not already exist."""

from pathlib import Path

from dotenv import load_dotenv

# Load environment variables from root .env
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from config.database import SessionLocal
from models import UserTable
from models.enums import UserRole


def main() -> None:
    email = input("Enter admin email: ").strip().lower()

    if not email:
        print("Error: email cannot be empty")
        return

    db = SessionLocal()

    try:
        user = (
            db.query(UserTable)
            .filter(UserTable.email == email)
            .first()
        )

        if user:
            print(f"User already exists: {email}")
            return

        user = UserTable(
            email=email,
            role=UserRole.ADMIN,
        )

        db.add(user)
        db.commit()

        print(f"Admin user created: {email}")

    except Exception:
        db.rollback()
        raise

    finally:
        db.close()


if __name__ == "__main__":
    main()