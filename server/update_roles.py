"""Seed script - upserts roles from USERS_TO_ADD into the database"""
import time
from config.database import SessionLocal
from models.role import Role

USERS_TO_ADD = {
    "sailohit948@gmail.com": "USER",
    "lingalalohit@gmail.com": "ADMIN",
    "24071a12f5@vnrvjiet.in": "STAFF",
    "24071a12f4@vnrvjiet.in": "ADMIN"
}

# Wait for DB/tables to be ready
for attempt in range(10):
    try:
        db = SessionLocal()
        db.execute(__import__('sqlalchemy').text("SELECT 1"))
        break
    except Exception as e:
        print(f"Waiting for database... ({attempt + 1}/10)")
        db.close()
        time.sleep(2)
else:
    print("Database not ready after 10 attempts, exiting.")
    raise SystemExit(1)

try:
    for email, role in USERS_TO_ADD.items():
        existing = Role.get(db, {"email": email})
        if existing:
            Role.update(db, {"email": email}, {"role": role})
            print(f"Updated {email} -> {role}")
        else:
            Role.create(db, {"email": email, "role": role})
            print(f"Added {email} -> {role}")
finally:
    db.close()
