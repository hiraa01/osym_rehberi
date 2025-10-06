from pydantic import BaseModel, EmailStr, validator
from typing import Optional, List, Dict, Any
from datetime import datetime


class StudentBase(BaseModel):
    name: str
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    class_level: str
    exam_type: str
    field_type: str
    
    # TYT Scores
    tyt_turkish_net: float = 0.0
    tyt_math_net: float = 0.0
    tyt_social_net: float = 0.0
    tyt_science_net: float = 0.0
    
    # AYT Scores
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
    ayt_foreign_language_net: float = 0.0
    
    # Preferences
    preferred_cities: Optional[List[str]] = None
    preferred_university_types: Optional[List[str]] = None
    budget_preference: Optional[str] = None
    scholarship_preference: bool = False
    interest_areas: Optional[List[str]] = None

    @validator('field_type')
    def validate_field_type(cls, v):
        allowed_types = ['EA', 'SAY', 'SÖZ', 'DİL']
        if v not in allowed_types:
            raise ValueError(f'field_type must be one of {allowed_types}')
        return v

    @validator('exam_type')
    def validate_exam_type(cls, v):
        allowed_types = ['TYT', 'AYT', 'TYT+AYT']
        if v not in allowed_types:
            raise ValueError(f'exam_type must be one of {allowed_types}')
        return v


class StudentCreate(StudentBase):
    pass


class StudentUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    class_level: Optional[str] = None
    exam_type: Optional[str] = None
    field_type: Optional[str] = None
    
    # TYT Scores
    tyt_turkish_net: Optional[float] = None
    tyt_math_net: Optional[float] = None
    tyt_social_net: Optional[float] = None
    tyt_science_net: Optional[float] = None
    
    # AYT Scores
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
    
    # Preferences
    preferred_cities: Optional[List[str]] = None
    preferred_university_types: Optional[List[str]] = None
    budget_preference: Optional[str] = None
    scholarship_preference: Optional[bool] = None
    interest_areas: Optional[List[str]] = None


class StudentResponse(StudentBase):
    id: int
    tyt_total_score: float
    ayt_total_score: float
    total_score: float
    rank: int
    percentile: float
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class StudentListResponse(BaseModel):
    students: List[StudentResponse]
    total: int
    page: int
    size: int
