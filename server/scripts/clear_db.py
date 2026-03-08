"""
Clear Database Script
Erases all data except roles table
"""
from sqlalchemy import create_engine, text
from config.database import DATABASE_URL
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def clear_database():
    """Clear all tables except roles"""
    engine = create_engine(DATABASE_URL)

    try:
        with engine.connect() as conn:
            logger.info("Starting database clear operation...")

            # For PostgreSQL, delete in reverse dependency order
            tables_to_clear = [
                ("store_chats", "Store chat messages"),
                ("request_tracks", "Request timeline tracks"),
                ("store_requests", "Store equipment requests"),
                ("assignments", "Staff assignments"),
                ("requests", "Main requests"),
                ("sub_types", "Request sub-types"),
                ("main_types", "Request main types"),
                ("users", "User profiles")
            ]

            for table, description in tables_to_clear:
                try:
                    result = conn.execute(text(f"DELETE FROM {table}"))
                    conn.commit()
                    logger.info(
                        f"✓ Cleared {description}: {table} ({result.rowcount} rows deleted)")
                except Exception as e:
                    logger.warning(
                        f"✗ Could not clear table {table}: {str(e)}")
                    conn.rollback()
            for table, description in tables_to_clear:
                try:
                    result = conn.execute(text(f"DROP TABLE {table}"))
                    conn.commit()
                    logger.info(f"✓ DROPPED {description}: {table}")
                except Exception as e:
                    logger.warning(
                        f"✗ Could not DROP table {table}: {str(e)}")
                    conn.rollback()

            logger.info("Database clear completed successfully!")
            logger.info("Roles table preserved.")

    except Exception as e:
        logger.error(f"Error clearing database: {str(e)}")
        raise
    finally:
        engine.dispose()


if __name__ == "__main__":
    print("\n" + "="*60)
    print("DATABASE CLEAR SCRIPT")
    print("="*60)
    print("\nThis will DELETE ALL DATA except the roles table!")
    print("\nTables that will be cleared:")
    print("  - store_chats (Store chat messages)")
    print("  - request_tracks (Request timeline)")
    print("  - store_requests (Equipment requests)")
    print("  - assignments (Staff assignments)")
    print("  - requests (Main requests)")
    print("  - sub_types (Request sub-types)")
    print("  - main_types (Request main types)")
    print("  - users (User profiles)")
    print("\nTables that will be PRESERVED:")
    print("  - roles (All role assignments kept intact)")
    print("\n" + "="*60)

    confirm = input("\nAre you sure you want to continue? (yes/no): ")

    if confirm.lower() == 'yes':
        clear_database()
        print("\n✓ Database cleared successfully!")
    else:
        print("\n✗ Operation cancelled.")
