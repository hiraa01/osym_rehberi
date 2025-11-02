from sqlalchemy import create_engine, MetaData
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# Database URL - PostgreSQL for production, SQLite for development
# ✅ SQLite dosyasını persistent volume'a kaydet (/app/data altında)
# Volume mount: backend_data:/app/data
DB_DIR = "/app/data"
DB_FILE = os.path.join(DB_DIR, "osym_rehber.db")

# Data dizinini oluştur (yoksa)
if not os.path.exists(DB_DIR):
    os.makedirs(DB_DIR, exist_ok=True)

# ✅ SQLite URL format: 4 slash (///) for absolute path on Unix
# sqlite:///path = relative, sqlite:////path = absolute
DATABASE_URL = os.getenv("DATABASE_URL", f"sqlite:///{os.path.abspath(DB_FILE)}")

# Create engine with connection pooling for better performance
if DATABASE_URL.startswith("sqlite"):
    # SQLite için pool ayarları
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False},
        pool_pre_ping=True,  # Connection health check
        pool_recycle=3600,   # Recycle connections after 1 hour
    )
else:
    # PostgreSQL için connection pool
    engine = create_engine(
        DATABASE_URL,
        pool_size=10,        # Connection pool size
        max_overflow=20,     # Additional connections beyond pool_size
        pool_pre_ping=True,  # Connection health check
        pool_recycle=3600,   # Recycle connections after 1 hour
    )

# Create session
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create base class for models
Base = declarative_base()

# Metadata for table creation
metadata = MetaData()


def get_db():
    """Dependency to get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def create_tables():
    """Create all tables in the database"""
    Base.metadata.create_all(bind=engine)
