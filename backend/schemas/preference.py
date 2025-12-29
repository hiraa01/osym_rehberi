from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from schemas.university import DepartmentWithUniversityResponse


class PreferenceBase(BaseModel):
    student_id: int
    department_id: int
    order: Optional[int] = None


class PreferenceCreate(PreferenceBase):
    pass


class PreferenceUpdate(BaseModel):
    order: Optional[int] = None


class PreferenceResponse(PreferenceBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class PreferenceWithDepartmentResponse(BaseModel):
    """Tercih bilgisi + Bölüm detayları + Kazanma ihtimali"""
    id: int
    student_id: int
    department_id: int
    order: Optional[int] = None
    created_at: datetime
    department: DepartmentWithUniversityResponse
    probability: float  # Kazanma ihtimali (0-100)
    probability_label: str  # "Yüksek", "Orta", "Düşük"
    
    class Config:
        from_attributes = True

