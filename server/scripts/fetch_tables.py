import os
from pathlib import Path
import psycopg2
from dotenv import load_dotenv

# load .env from parent directory
env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(env_path)

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL not found")

# fix SQLAlchemy-style URLs
DATABASE_URL = DATABASE_URL.replace("postgresql+psycopg2://", "postgresql://")

conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

cur.execute("""
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, tablename;
""")

tables = cur.fetchall()

print("Tables found:\n")

for schema, table in tables:
    print(f"{schema}.{table}")

cur.close()
conn.close()
