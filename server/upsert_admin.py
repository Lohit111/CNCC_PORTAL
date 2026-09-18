"""Create the admin user if it does not already exist."""

from pathlib import Path
import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from models import UserTable
from models.enums import UserRole


# server/upsert_admin.py -> project root/.env
ROOT_DIR = Path(__file__).resolve().parent.parent
load_dotenv(ROOT_DIR / ".env")


def main() -> None:
    email = input("Enter admin email: ").strip().lower()

    if not email:
        print("Error: email cannot be empty")
        return

    database_url = os.getenv("DATABASE_URL")

    if not database_url:
        database_url = (
            f"postgresql://{os.getenv('POSTGRES_USER')}:"
            f"{os.getenv('POSTGRES_PASSWORD')}@localhost:5432/"
            f"{os.getenv('POSTGRES_DB')}"
        )

    if not database_url:
        print("Error: database configuration is missing")
        return

    engine = create_engine(database_url)
    SessionLocal = sessionmaker(bind=engine)

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
        engine.dispose()


if __name__ == "__main__":
    main()