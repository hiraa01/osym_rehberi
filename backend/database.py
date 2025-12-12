from sqlalchemy import create_engine, MetaData, event
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
    engine = create_engine(
        DATABASE_URL,
        connect_args={
            "check_same_thread": False,
        },
        pool_pre_ping=True,  # Connection health check
        pool_recycle=3600,   # Recycle connections after 1 hour
    )
    
    # ✅ SQLite performans optimizasyonları - Event listener ile
    @event.listens_for(engine, "connect")
    def set_sqlite_pragma(dbapi_conn, connection_record):
        """SQLite performans optimizasyonları - Her bağlantıda çalışır"""
        cursor = dbapi_conn.cursor()
        # WAL mode - çoklu okuma/yazma performansı için kritik (10x hızlanma)
        cursor.execute("PRAGMA journal_mode=WAL")
        # Synchronous mode - güvenlik vs performans dengesi (NORMAL = güvenli ama hızlı)
        cursor.execute("PRAGMA synchronous=NORMAL")
        # Cache size - daha fazla bellek kullan ama daha hızlı (64MB)
        cursor.execute("PRAGMA cache_size=-64000")
        # Temp store - geçici verileri RAM'de tut
        cursor.execute("PRAGMA temp_store=MEMORY")
        # Foreign keys - referans bütünlüğü için
        cursor.execute("PRAGMA foreign_keys=ON")
        # Optimize - sorgu planlayıcıyı optimize et
        cursor.execute("PRAGMA optimize")
        cursor.close()
else:
    # PostgreSQL için connection pool - OPTIMIZED
    engine = create_engine(
        DATABASE_URL,
        pool_size=20,        # Connection pool size (artırıldı)
        max_overflow=30,     # Additional connections beyond pool_size (artırıldı)
        pool_pre_ping=True,  # Connection health check
        pool_recycle=1800,   # Recycle connections after 30 minutes (daha sık)
        echo=False,          # SQL query logging (production'da kapalı)
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
