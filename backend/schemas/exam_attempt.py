from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class ExamAttemptBase(BaseModel):
    student_id: int
    attempt_number: int
    exam_date: Optional[datetime] = None
    exam_name: Optional[str] = None
    
    # TYT Netleri
    tyt_turkish_net: float = 0.0
    tyt_math_net: float = 0.0
    tyt_social_net: float = 0.0
    tyt_science_net: float = 0.0
    
    # AYT Netleri
    ayt_math_net: float = 0.0
    ayt_physics_net: float = 0.0
    ayt_chemistry_net: float = 0.0
    ayt_biology_net: float = 0.0
    ayt_literature_net: float = 0.0
    ayt_history1_net: float = 0.0
    ayt_geography1_net: float = 0.0
    ayt_philosophy_net: float = 0.0
    ayt_history2_net: float = 0.0
    ayt_geography2_net: float = 0.0
    ayt_religion_net: float = 0.0  # Din Kültürü
    ayt_foreign_language_net: float = 0.0
    
    # OBP (Okul Başarı Puanı) - Opsiyonel
    obp_score: Optional[float] = 0.0


class ExamAttemptCreate(ExamAttemptBase):
    pass


class ExamAttemptUpdate(BaseModel):
    exam_date: Optional[datetime] = None
    exam_name: Optional[str] = None
    
    # TYT Netleri
    tyt_turkish_net: Optional[float] = None
    tyt_math_net: Optional[float] = None
    tyt_social_net: Optional[float] = None
    tyt_science_net: Optional[float] = None
    
    # AYT Netleri
    ayt_math_net: Optional[float] = None
    ayt_physics_net: Optional[float] = None
    ayt_chemistry_net: Optional[float] = None
    ayt_biology_net: Optional[float] = None
    ayt_literature_net: Optional[float] = None
    ayt_history1_net: Optional[float] = None
    ayt_geography1_net: Optional[float] = None
    ayt_philosophy_net: Optional[float] = None
    ayt_history2_net: Optional[float] = None
    ayt_geography2_net: Optional[float] = None
    ayt_foreign_language_net: Optional[float] = None


class ExamAttemptResponse(ExamAttemptBase):
    id: int
    tyt_score: float
    ayt_score: float
    total_score: float
    obp_score: Optional[float] = 0.0  # ✅ OBP eklendi
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ExamAttemptListResponse(BaseModel):
    attempts: List[ExamAttemptResponse]
    total: int
    average_score: float

