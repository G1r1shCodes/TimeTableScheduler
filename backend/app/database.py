import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from dotenv import load_dotenv

load_dotenv()

# Default to SQLite for local development (no PostgreSQL required).
# Set DATABASE_URL in your .env to switch to PostgreSQL in production.
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:///./college_timetable.db"
)

_is_sqlite = DATABASE_URL.startswith("sqlite")
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if _is_sqlite else {},
    **({"pool_size": 5, "pool_pre_ping": True} if not _is_sqlite else {}),
)
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
