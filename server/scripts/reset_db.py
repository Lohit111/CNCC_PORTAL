import os
from pathlib import Path
import psycopg2
from dotenv import load_dotenv

env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(env_path)

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL not found")

# remove sqlalchemy driver spec
DATABASE_URL = DATABASE_URL.replace("postgresql+psycopg2://", "postgresql://")

conn = psycopg2.connect(DATABASE_URL)
conn.autocommit = True
cur = conn.cursor()

SKIP_TABLES = {"users", "roles"}

cur.execute("""
SELECT tablename
FROM pg_tables
WHERE schemaname='public';
""")

tables = cur.fetchall()

for (table,) in tables:
    if table in SKIP_TABLES:
        print(f"Skipping  {table}")
        continue
    print(f"Truncating {table}")
    cur.execute(f'TRUNCATE TABLE public."{table}" CASCADE;')

cur.close()
conn.close()

print("Done.")
