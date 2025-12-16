from pydantic import BaseModel, validator
from typing import Optional, List, Dict, Any
from datetime import datetime


class UniversityBase(BaseModel):
    name: str
    city: str
    university_type: str
    website: Optional[str] = None
    established_year: Optional[int] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

    @validator('university_type')
    def validate_university_type(cls, v):
        allowed_types = ['devlet', 'vakif']
        if v not in allowed_types:
            raise ValueError(f'university_type must be one of {allowed_types}')
        return v


class UniversityCreate(UniversityBase):
    pass


class UniversityUpdate(BaseModel):
    name: Optional[str] = None
    city: Optional[str] = None
    university_type: Optional[str] = None
    website: Optional[str] = None
    established_year: Optional[int] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class UniversityResponse(UniversityBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    logo_url: Optional[str] = None

    class Config:
        from_attributes = True


class DepartmentBase(BaseModel):
    university_id: int
    name: str  # Orijinal isim (tam isim)
    normalized_name: Optional[str] = None  # ✅ Normalize edilmiş isim
    attributes: Optional[List[str]] = None  # ✅ ["İngilizce", "%50 İndirimli"] gibi
    field_type: str
    language: str = "Turkish"
    faculty: Optional[str] = None
    duration: int = 4
    degree_type: str = "Bachelor"
    min_score: Optional[float] = None
    min_rank: Optional[int] = None
    quota: Optional[int] = None
    scholarship_quota: int = 0
    tuition_fee: Optional[float] = None
    has_scholarship: bool = False
    last_year_min_score: Optional[float] = None
    last_year_min_rank: Optional[int] = None
    last_year_quota: Optional[int] = None
    description: Optional[str] = None
    requirements: Optional[Dict[str, Any]] = None

    @validator('field_type')
    def validate_field_type(cls, v):
        allowed_types = ['EA', 'SAY', 'SÖZ', 'DİL']
        if v not in allowed_types:
            raise ValueError(f'field_type must be one of {allowed_types}')
        return v


class DepartmentCreate(DepartmentBase):
    pass


class DepartmentUpdate(BaseModel):
    university_id: Optional[int] = None
    name: Optional[str] = None
    normalized_name: Optional[str] = None  # ✅
    attributes: Optional[List[str]] = None  # ✅
    field_type: Optional[str] = None
    language: Optional[str] = None
    faculty: Optional[str] = None
    duration: Optional[int] = None
    degree_type: Optional[str] = None
    min_score: Optional[float] = None
    min_rank: Optional[int] = None
    quota: Optional[int] = None
    scholarship_quota: Optional[int] = None
    tuition_fee: Optional[float] = None
    has_scholarship: Optional[bool] = None
    last_year_min_score: Optional[float] = None
    last_year_min_rank: Optional[int] = None
    last_year_quota: Optional[int] = None
    description: Optional[str] = None
    requirements: Optional[Dict[str, Any]] = None


class DepartmentResponse(DepartmentBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    @validator('attributes', pre=True)
    def parse_attributes(cls, v):
        """Database'den gelen JSON string'i parse et"""
        if v is None:
            return None
        if isinstance(v, str):
            try:
                import json
                return json.loads(v)
            except (json.JSONDecodeError, TypeError):
                return None
        return v

    class Config:
        from_attributes = True


class DepartmentWithUniversityResponse(DepartmentResponse):
    university: UniversityResponse


class RecommendationBase(BaseModel):
    student_id: int
    department_id: int
    compatibility_score: float
    success_probability: float
    preference_score: float
    final_score: float
    recommendation_reason: Optional[str] = None
    is_safe_choice: bool = False
    is_dream_choice: bool = False
    is_realistic_choice: bool = False


class RecommendationCreate(RecommendationBase):
    pass


class RecommendationResponse(RecommendationBase):
    id: int
    created_at: datetime
    department: DepartmentWithUniversityResponse

    class Config:
        from_attributes = True


class RecommendationListResponse(BaseModel):
    recommendations: List[RecommendationResponse]
    total: int
    page: int
    size: int
