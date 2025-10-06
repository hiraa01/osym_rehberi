from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from database import create_tables
from routers import students, universities, recommendations


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    create_tables()
    yield
    # Shutdown
    pass


app = FastAPI(
    title="ÖSYM Rehberi API",
    description="Yapay zeka destekli üniversite ve bölüm öneri sistemi",
    version="1.0.0",
    lifespan=lifespan
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
app.include_router(students.router, prefix="/api/students", tags=["students"])
app.include_router(universities.router, prefix="/api/universities", tags=["universities"])
app.include_router(recommendations.router, prefix="/api/recommendations", tags=["recommendations"])


@app.get("/")
async def root():
    return {"message": "ÖSYM Rehberi API - Yapay zeka destekli üniversite öneri sistemi"}


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "osym-rehberi-api"}
