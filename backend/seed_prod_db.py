"""Create a minimal initial production database.

This script is intentionally destructive, but it will only operate when the
configured SQLite database filename is exactly ``progress_prod.db``.
"""

from datetime import UTC, datetime, timedelta
from pathlib import Path
from urllib.parse import urlparse

from pwdlib import PasswordHash

from config import settings
from database import Base, SessionLocal, engine
from models import Account, AdminProfile, Country, MentorProfile


password_hash = PasswordHash.recommended()

PRODUCTION_ACCOUNTS = (
    ("Peter", "Mekis", "0781653508", "123456", "Peter123"),
    ("Abdallah", "Kiggundu", "0742361991", "123456", "Abdallah123"),
    ("Margret", "Nakalema", "0774231538", "123456", "Margret123"),
)

REVIEWER_ACCOUNTS = (
    ("Judge", "Mentor", "0123456789", "123456", None),
    ("Judge", "Administrator", "0987654321", None, "Judge123"),
)


def _assert_production_seed_target() -> None:
    parsed = urlparse(settings.database_url)
    database_path = Path(parsed.path)
    if (
        parsed.scheme != "sqlite"
        or database_path.name != "progress_prod.db"
    ):
        raise RuntimeError(
            "Refusing to seed: DATABASE_URL must target progress_prod.db."
        )


def _add_account(
    db,
    country: Country,
    first_name: str,
    last_name: str,
    phone: str,
    mentor_pin: str | None,
    admin_password: str | None,
    *,
    temporary: bool,
) -> None:
    account = Account(
        first_name=first_name,
        last_name=last_name,
        phone=phone,
        country=country,
        preferred_language="en",
    )
    db.add(account)
    db.flush()

    expires_at = (
        datetime.now(UTC)
        + timedelta(days=settings.temporary_secret_days)
        if temporary
        else None
    )

    if mentor_pin is not None:
        account.mentor_profile = MentorProfile(
            pin_hash=password_hash.hash(mentor_pin),
            must_change_pin=temporary,
            temporary_pin_expires_at=expires_at,
        )

    if admin_password is not None:
        account.admin_profile = AdminProfile(
            password_hash=password_hash.hash(admin_password),
            must_change_password=temporary,
            temporary_password_expires_at=expires_at,
        )

    db.flush()


def main() -> None:
    _assert_production_seed_target()
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    with SessionLocal() as db:
        uganda = Country(code="UG", name="Uganda")
        db.add(uganda)
        db.flush()

        for account in PRODUCTION_ACCOUNTS:
            _add_account(db, uganda, *account, temporary=True)

        for account in REVIEWER_ACCOUNTS:
            _add_account(db, uganda, *account, temporary=False)

        db.commit()

    print("Created progress_prod.db with 5 accounts.")


if __name__ == "__main__":
    main()
