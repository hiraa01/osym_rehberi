from sqlalchemy import create_engine, MetaData, event
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
import logging

# Logger setup
api_logger = logging.getLogger("api")

# ✅ CRITICAL: TÜM MODELLERİ BURADA IMPORT ET
# SQLAlchemy'nin Base.metadata.create_all() çalışması için
# modellerin Base'e kayıt olması gerekiyor. Bu import'lar
# Base tanımlandıktan SONRA ama create_tables() çağrılmadan ÖNCE yapılmalı.
# 
# NOT: Import'ları try-except içine alarak eksik modellerin
# uygulamayı çökertmesini engelliyoruz.

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

# ✅ IMPORT ALL MODELS FROM SINGLE FILE (After Base is created, before create_tables is called)
# Tüm modeller tek dosyada (models.py) - circular import sorunu kesin çözüm
try:
    # ✅ Tek dosyadan tüm modelleri import et
    from models import (  # noqa: F401
        User, Student, ExamAttempt,
        University, Department, DepartmentYearlyStats, Recommendation,
        Preference, Swipe,
        ForumPost, ForumComment,
        AgendaItem, StudySession, ChatMessage,
        YokUniversity, YokProgram, YokCity, ScoreCalculation
    )
    api_logger.info("✅ All models imported successfully from models.py")
        
except ImportError as e:
    api_logger.error(f"❌ CRITICAL: Failed to import models: {e}")
    api_logger.error("❌ Some models may not be registered with Base.metadata!")
    import traceback
    api_logger.error(f"❌ Traceback: {traceback.format_exc()}")
    # Uygulamayı çökertme, sadece log
    pass


def get_db():
    """Dependency to get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def create_tables(max_retries: int = 3, retry_delay: int = 2):
    """
    Create all tables in the database (Auto-Migration) with retry logic
    
    NOT: Modeller zaten dosyanın üstünde import edildi (Base.metadata'ya kayıt için).
    Bu fonksiyon sadece tabloları oluşturur.
    
    Args:
        max_retries: Maksimum deneme sayısı (varsayılan: 3)
        retry_delay: Her deneme arası bekleme süresi (saniye, varsayılan: 2)
    
    Returns:
        bool: Tablolar başarıyla oluşturuldu ise True, aksi halde False
    """
    import time
    
    for attempt in range(1, max_retries + 1):
        try:
            api_logger.info(f"🔄 Starting database table creation (Auto-Migration)... (Deneme {attempt}/{max_retries})")
            
            # ✅ Modeller zaten import edildi (dosyanın üstünde)
            # Sadece tabloları oluştur
            api_logger.info("🔨 Creating database tables from registered models...")
            
            # Base.metadata'da kayıtlı tüm modeller için tabloları oluştur
            Base.metadata.create_all(bind=engine)
            
            # Oluşturulan tabloları kontrol et
            from sqlalchemy import inspect
            inspector = inspect(engine)
            created_tables = inspector.get_table_names()
            
            api_logger.info(f"✅ Tablolar başarıyla oluşturuldu! ({len(created_tables)} tablo)")
            api_logger.info(f"📊 Oluşturulan tablolar: {', '.join(sorted(created_tables))}")
            
            # Kayıtlı modelleri kontrol et
            registered_tables = list(Base.metadata.tables.keys())
            api_logger.info(f"📋 Kayıtlı modeller: {len(registered_tables)} tablo metadata'da")
            
            return True
            
        except Exception as e:
            if attempt < max_retries:
                api_logger.warning(f"⚠️ Tablo oluşturma hatası (Deneme {attempt}/{max_retries}): {str(e)}")
                api_logger.info(f"⏳ {retry_delay} saniye bekleniyor...")
                time.sleep(retry_delay)
            else:
                api_logger.error(f"❌ TABLO OLUŞTURMA HATASI: {e}")
                import traceback
                api_logger.error(f"❌ Traceback: {traceback.format_exc()}")
                # Hata olsa bile uygulama çalışmaya devam etsin (sadece log)
                # Çünkü tablolar zaten var olabilir
                api_logger.warning("⚠️ Tablo oluşturma hatasına rağmen devam ediliyor (tablolar zaten var olabilir)")
                return False
    
    return False
