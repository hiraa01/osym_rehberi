from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from database import create_tables
from routers import students, universities, recommendations, ml_recommendations, auth, exam_attempts


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    create_tables()
    yield
    # Shutdown
    pass


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

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(students.router, prefix="/api/students", tags=["students"])
app.include_router(universities.router, prefix="/api/universities", tags=["universities"])
app.include_router(recommendations.router, prefix="/api/recommendations", tags=["recommendations"])
app.include_router(ml_recommendations.router, prefix="/api/ml", tags=["ml-recommendations"])
app.include_router(exam_attempts.router, prefix="/api/exam-attempts", tags=["exam-attempts"])


@app.get("/")
async def root():
    return {"message": "ÖSYM Rehberi API - Yapay zeka destekli üniversite öneri sistemi"}


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "osym-rehberi-api"}
