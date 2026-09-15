"""Create or update users with their required roles."""

from config.database import SessionLocal
from models.user import UserTable
from models.enums import UserRole


USERS = {
    "cncc@vnrvjiet.in": UserRole.ADMIN,
    "ramakrishna_it@vnrvjiet.in": UserRole.STAFF,
    "bsrinivasreddy_it@vnrvjiet.in": UserRole.STAFF,
    "purushothamanaidu_c@vnrvjiet.in": UserRole.STAFF,
    "24071a12f0@vnrvjiet.in": UserRole.ADMIN,
    "sailohit948@gmail.com": UserRole.USER,
    "support@vnrvjiet.in": UserRole.ADMIN,
    "akhil_it@vnrvjiet.in": UserRole.STAFF,
    "srikrishnakireeti_it@vnrvjiet.in": UserRole.USER,
    "24071a12f1@vnrvjiet.in": UserRole.USER,
    "24071a12f5@vnrvjiet.in": UserRole.USER,
    "dinesh_adm@vnrvjiet.in": UserRole.USER,
    "kpeerya_it@vnrvjiet.in": UserRole.STORE,
    "vijaykumar_it@vnrvjiet.in": UserRole.STORE,
}


def main() -> None:
    db = SessionLocal()

    created = 0
    updated = 0

    try:
        for email, role in USERS.items():
            user = (
                db.query(UserTable)
                .filter(UserTable.email == email)
                .first()
            )

            if user:
                if user.role != role:
                    old_role = user.role
                    user.role = role

                    print(
                        f"Updated: {email} "
                        f"{old_role.value} -> {role.value}"
                    )

                    updated += 1
                else:
                    print(f"Already correct: {email} ({role.value})")

            else:
                user = UserTable(
                    email=email,
                    role=role,
                )

                db.add(user)

                print(f"Created: {email} ({role.value})")
                created += 1

        db.commit()

        print()
        print("Done.")
        print(f"Created: {created}")
        print(f"Updated: {updated}")

    except Exception:
        db.rollback()
        raise

    finally:
        db.close()


if __name__ == "__main__":
    main()