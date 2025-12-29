"""
Study Session Schemas
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class StudySessionBase(BaseModel):
    subject: str = Field(..., min_length=1, max_length=100, description="Ders adı (Matematik, Fizik, vb.)")
    duration_minutes: int = Field(..., ge=0, description="Çalışma süresi (dakika)")
    notes: Optional[str] = Field(None, max_length=2000, description="Notlar")
    efficiency_score: Optional[float] = Field(None, ge=0.0, le=100.0, description="Verimlilik puanı (0-100)")


class StudySessionCreate(StudySessionBase):
    student_id: int = Field(..., description="Öğrenci ID")
    date: datetime = Field(..., description="Çalışma tarihi")


class StudySessionUpdate(BaseModel):
    subject: Optional[str] = Field(None, min_length=1, max_length=100)
    duration_minutes: Optional[int] = Field(None, ge=0)
    date: Optional[datetime] = None
    notes: Optional[str] = Field(None, max_length=2000)
    efficiency_score: Optional[float] = Field(None, ge=0.0, le=100.0)


class StudySessionResponse(StudySessionBase):
    id: int
    student_id: int
    date: datetime
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class StudySessionListResponse(BaseModel):
    sessions: list[StudySessionResponse]
    total: int
    page: int
    size: int


class StudyStatsResponse(BaseModel):
    """Ders çalışma istatistikleri"""
    total_sessions: int
    total_minutes: int
    total_hours: float
    average_duration_minutes: float
    subjects: dict[str, int]  # {subject: total_minutes}
    weekly_stats: list[dict]  # [{date: "2024-01-01", minutes: 120}, ...]
    efficiency_average: Optional[float] = None

