from pydantic import BaseModel
from typing import List, Optional
from schemas.university import DepartmentWithUniversityResponse

class MLRecommendationResponse(BaseModel):
    id: Optional[int] = None
    student_id: int
    department_id: int
    compatibility_score: float
    success_probability: float
    preference_score: float
    final_score: float
    recommendation_reason: str
    is_safe_choice: bool
    is_dream_choice: bool
    is_realistic_choice: bool
    department: DepartmentWithUniversityResponse

    class Config:
        from_attributes = True

class MLModelStatusResponse(BaseModel):
    is_trained: bool
    models_available: List[str]
    message: str

class MLTrainingResponse(BaseModel):
    message: str
    status: str
