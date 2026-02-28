"""Script to add admin role to a user"""
import sys
from config.database import SessionLocal
from models.role import Role

def add_admin(email: str):
    """Add or update admin role for an email"""
    db = SessionLocal()
    try:
        # Check if role exists
        existing_role = Role.get(db, {"email": email})
        
        if existing_role:
            # Update to ADMIN
            Role.update(db, {"email": email}, {"role": "ADMIN"})
            print(f"✓ Updated {email} to ADMIN role")
        else:
            # Create new ADMIN role
            Role.create(db, {"email": email, "role": "ADMIN"})
            print(f"✓ Created ADMIN role for {email}")
        
        print(f"\n{email} now has ADMIN access")
        
    except Exception as e:
        print(f"✗ Error: {str(e)}")
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python add_admin.py <email>")
        sys.exit(1)
    
    email = sys.argv[1]
    add_admin(email)
