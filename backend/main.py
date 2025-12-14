from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from contextlib import asynccontextmanager
import asyncio
import os
import contextlib

from database import create_tables, get_db
from routers import students, universities, recommendations, ml_recommendations, auth, exam_attempts, coach_chat
from core.logging_config import api_logger


async def _periodic_ml_training_task():
    """Periodik olarak ML eğitimini tetikler (varsayılan: günde 1 kez)."""
    # Ortam değişkeni ile ayarlanabilir
    interval_seconds_str = os.getenv("ML_TRAIN_INTERVAL_SECONDS", "86400")
    try:
        interval_seconds = max(3600, int(interval_seconds_str))  # En az 1 saat
    except Exception:
        interval_seconds = 86400

    # Eğitim fonksiyonunu içe aktar
    from routers.ml_recommendations import train_models_background

    while True:
        try:
            await asyncio.sleep(interval_seconds)
            api_logger.info("Periodic ML training tick started")
            # DB session oluştur ve eğitimi çağır
            db = next(get_db())
            try:
                await train_models_background(db)
            finally:
                db.close()
            api_logger.info("Periodic ML training tick completed")
        except asyncio.CancelledError:
            api_logger.info("Periodic ML training task cancelled")
            break
        except Exception as e:
            api_logger.error("Periodic ML training failed", error=str(e))


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    api_logger.info("Starting application...")
    create_tables()
    
    # ✅ Cache'i startup'ta yükle - statik veriler için
    api_logger.info("Loading cache for static data...")
    try:
        db = next(get_db())
        try:
            # Cities cache
            from sqlalchemy import distinct
            from models.university import University, Department
            cities_result = db.query(distinct(University.city)).filter(University.city.isnot(None)).all()
            cities = [city[0] for city in cities_result if city[0]]
            from core.cache import set_cache
            from datetime import timedelta
            set_cache("cities", cities, ttl=timedelta(hours=24))  # 24 saat cache
            api_logger.info(f"Cached {len(cities)} cities")
            
            # Field types cache
            field_types_result = db.query(distinct(Department.field_type)).filter(Department.field_type.isnot(None)).all()
            field_types = [ft[0] for ft in field_types_result if ft[0]]
            set_cache("field_types", field_types, ttl=timedelta(hours=24))  # 24 saat cache
            api_logger.info(f"Cached {len(field_types)} field types")
        finally:
            db.close()
    except Exception as e:
        api_logger.warning(f"Cache loading failed (non-critical): {str(e)}")
    
    # Periodik ML eğitim görevini başlat
    app.state.ml_training_task = asyncio.create_task(_periodic_ml_training_task())
    api_logger.info("Application started successfully")
    yield
    # Shutdown
    api_logger.info("Shutting down application...")
    # Periodik görev iptali
    task = getattr(app.state, "ml_training_task", None)
    if task:
        task.cancel()
        with contextlib.suppress(Exception):
            await task
    api_logger.info("Application shutdown complete")


app = FastAPI(
    title="ÖSYM Rehberi API",
    description="""
    ## Yapay Zeka Destekli Üniversite ve Bölüm Öneri Sistemi
    
    Bu API, öğrenci profillerini analiz ederek YÖK Atlas verilerini kullanarak en uygun tercih önerilerini sunar.
    
    ### Özellikler
    
    * **Öğrenci Yönetimi**: Öğrenci profilleri oluşturma, güncelleme ve listeleme
    * **Puan Hesaplama**: TYT ve AYT netlerinden otomatik puan hesaplama
    * **Üniversite Verileri**: Üniversite ve bölüm bilgilerini listeleme
    * **Yapay Zeka Önerileri**: Öğrenci profiline göre kişiselleştirilmiş tercih önerileri
    * **Filtreleme**: Şehir, üniversite türü, alan türü gibi kriterlere göre filtreleme
    
    ### Kullanım
    
    1. Öğrenci profili oluşturun
    2. Deneme sonuçlarınızı girin
    3. Tercihlerinizi belirtin
    4. Yapay zeka destekli önerileri alın
    
    ### API Endpoints
    
    * **Students**: `/api/students/` - Öğrenci yönetimi
    * **Universities**: `/api/universities/` - Üniversite ve bölüm verileri
    * **Recommendations**: `/api/recommendations/` - Tercih önerileri
    """,
    version="1.0.0",
    contact={
        "name": "ÖSYM Rehberi API Support",
        "email": "support@osymrehberi.com",
    },
    license_info={
        "name": "MIT License",
        "url": "https://opensource.org/licenses/MIT",
    },
    lifespan=lifespan,
    redirect_slashes=False  # Disable automatic trailing slash redirects
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Response compression middleware (büyük JSON response'lar için)
app.add_middleware(GZipMiddleware, minimum_size=1000)  # 1KB'dan büyük response'ları sıkıştır

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(students.router, prefix="/api/students", tags=["students"])
app.include_router(universities.router, prefix="/api/universities", tags=["universities"])
app.include_router(recommendations.router, prefix="/api/recommendations", tags=["recommendations"])
app.include_router(ml_recommendations.router, prefix="/api/ml", tags=["ml-recommendations"])
app.include_router(exam_attempts.router, prefix="/api/exam-attempts", tags=["exam-attempts"])
app.include_router(coach_chat.router, prefix="/api/chat", tags=["coach-chat"])


@app.get("/")
async def root():
    return {"message": "ÖSYM Rehberi API - Yapay zeka destekli üniversite öneri sistemi"}


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "osym-rehberi-api"}
