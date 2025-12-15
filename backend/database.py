from sqlalchemy import create_engine, MetaData, event
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
import logging

# Logger setup
api_logger = logging.getLogger("api")

# Database URL - PostgreSQL for production, SQLite for development
# ✅ PostgreSQL'e geçiş yapıldı - performans için kritik
# Environment variable'dan al, yoksa PostgreSQL varsayılan değerlerini kullan
POSTGRES_USER = os.getenv("POSTGRES_USER", "osym_user")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "osym_password")
POSTGRES_DB = os.getenv("POSTGRES_DB", "osym_rehber")
POSTGRES_HOST = os.getenv("POSTGRES_HOST", "db")  # Docker compose'da servis adı
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")

# PostgreSQL connection string
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"
)

# Create engine with connection pooling for better performance
# ✅ PostgreSQL'e geçiş yapıldı - SQLite artık kullanılmıyor
if DATABASE_URL.startswith("sqlite"):
    # SQLite fallback (sadece development için)
    engine = create_engine(
        DATABASE_URL,
        connect_args={
            "check_same_thread": False,
        },
        pool_pre_ping=True,
        pool_recycle=3600,
    )
    
    @event.listens_for(engine, "connect")
    def set_sqlite_pragma(dbapi_conn, connection_record):
        """SQLite performans optimizasyonları"""
        cursor = dbapi_conn.cursor()
        cursor.execute("PRAGMA journal_mode=WAL")
        cursor.execute("PRAGMA synchronous=NORMAL")
        cursor.execute("PRAGMA cache_size=-64000")
        cursor.execute("PRAGMA temp_store=MEMORY")
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.execute("PRAGMA optimize")
        cursor.close()
else:
    # ✅ PostgreSQL için optimize edilmiş connection pool
    engine = create_engine(
        DATABASE_URL,
        pool_size=20,        # Connection pool size (optimal for most cases)
        max_overflow=30,     # Additional connections beyond pool_size
        pool_pre_ping=True,  # Connection health check
        pool_recycle=1800,   # Recycle connections after 30 minutes
        pool_timeout=30,     # Wait time for connection from pool (seconds)
        echo=False,          # SQL query logging (production'da kapalı)
        # PostgreSQL özel optimizasyonlar
        connect_args={
            "connect_timeout": 20,  # Connection timeout (10 -> 20 seconds)
            "application_name": "osym_rehberi_api",  # Connection identifier
            "options": "-c statement_timeout=300000",  # 5 minutes query timeout
        },
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
    # ✅ Tüm modelleri import et (Base.metadata'ya kayıt olmaları için)
    # Modeller zaten import edilmiş olmalı, ama emin olmak için:
    from models.student import Student
    from models.exam_attempt import ExamAttempt
    from models.university import University, Department, Recommendation
    from models.user import User
    
    # ✅ PostgreSQL için tabloları oluştur
    try:
        Base.metadata.create_all(bind=engine)
        api_logger.info("✅ Database tables created successfully")
    except Exception as e:
        api_logger.error(f"❌ Error creating tables: {e}")
        raise
