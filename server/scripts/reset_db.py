"""
Reset Database Script
Drops all tables and recreates them from models
"""
from sqlalchemy import create_engine, text
from config.database import DATABASE_URL
from models.base import Base
import models  # Import all models to register them
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def reset_database():
    """Drop all tables and recreate from models"""
    engine = create_engine(DATABASE_URL)

    try:
        with engine.connect() as conn:
            logger.info("Dropping all tables...")

            # First, drop the old request_comments table if it exists
            try:
                conn.execute(
                    text("DROP TABLE IF EXISTS request_comments CASCADE"))
                conn.commit()
                logger.info("✓ Dropped old request_comments table")
            except Exception as e:
                logger.warning(f"Could not drop request_comments: {str(e)}")
                conn.rollback()

            # Drop all other tables using CASCADE
            try:
                conn.execute(text("""
                    DROP TABLE IF EXISTS store_chats CASCADE;
                    DROP TABLE IF EXISTS request_tracks CASCADE;
                    DROP TABLE IF EXISTS store_requests CASCADE;
                    DROP TABLE IF EXISTS assignments CASCADE;
                    DROP TABLE IF EXISTS requests CASCADE;
                    DROP TABLE IF EXISTS sub_types CASCADE;
                    DROP TABLE IF EXISTS main_types CASCADE;
                    DROP TABLE IF EXISTS users CASCADE;
                    DROP TABLE IF EXISTS roles CASCADE;
                """))
                conn.commit()
                logger.info("✓ All tables dropped")
            except Exception as e:
                logger.error(f"Error dropping tables: {str(e)}")
                raise

        logger.info("Creating all tables from models...")

        # Create all tables
        Base.metadata.create_all(engine)
        logger.info("✓ All tables created")

        logger.info("\n" + "="*60)
        logger.info("Database reset completed successfully!")
        logger.info("="*60)
        logger.info("\nTables created:")
        for table in Base.metadata.sorted_tables:
            logger.info(f"  - {table.name}")

    except Exception as e:
        logger.error(f"Error resetting database: {str(e)}")
        raise
    finally:
        engine.dispose()


if __name__ == "__main__":
    print("\n" + "="*60)
    print("DATABASE RESET SCRIPT")
    print("="*60)
    print("\n⚠️  WARNING: This will DELETE ALL DATA!")
    print("\nThis will:")
    print("  1. Drop ALL tables (including roles)")
    print("  2. Recreate all tables from models")
    print("  3. Database will be completely empty")
    print("\n" + "="*60)

    confirm = input("\nAre you sure you want to continue? (yes/no): ")

    if confirm.lower() == 'yes':
        reset_database()
        print("\n✓ Database reset successfully!")
        print("\nYou can now:")
        print("  1. Restart your server")
        print("  2. Create roles for users")
        print("  3. Start fresh with the new track system")
    else:
        print("\n✗ Operation cancelled.")
