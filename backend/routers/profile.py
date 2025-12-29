from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional

from database import get_db
from models import Student
from schemas.student import StudentResponse
from core.logging_config import api_logger
from core.exceptions import StudentNotFoundError

router = APIRouter()


class ProfileUpdate(BaseModel):
    """Profil güncelleme şeması"""
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    target_university: Optional[str] = None


@router.patch("/{student_id}", response_model=StudentResponse)
async def update_profile(
    student_id: int,
    profile_update: ProfileUpdate,
    db: Session = Depends(get_db)
):
    """
    Kullanıcının profil bilgilerini güncelle
    
    Güncellenebilir alanlar:
    - avatar_url: Profil fotoğrafı URL'i
    - bio: Kısa biyografi
    - target_university: Hedeflenen üniversite
    """
    try:
        # Öğrenciyi bul
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {student_id}")
        
        # Güncelleme verilerini al
        update_data = profile_update.dict(exclude_unset=True)
        
        # Alanları güncelle
        for field, value in update_data.items():
            if hasattr(student, field):
                setattr(student, field, value)
        
        db.commit()
        db.refresh(student)
        
        api_logger.info(
            f"Profile updated for student {student_id}",
            user_id=student_id
        )
        
        # Response oluştur
        import json
        from schemas.student import StudentResponse
        
        # JSON alanları parse et
        preferred_cities = None
        if student.preferred_cities:
            try:
                preferred_cities = json.loads(student.preferred_cities)
            except:
                preferred_cities = None
        
        preferred_university_types = None
        if student.preferred_university_types:
            try:
                preferred_university_types = json.loads(student.preferred_university_types)
            except:
                preferred_university_types = None
        
        preferred_departments = None
        if student.preferred_departments:
            try:
                preferred_departments = json.loads(student.preferred_departments)
            except:
                preferred_departments = None
        
        interest_areas = None
        if student.interest_areas:
            try:
                interest_areas = json.loads(student.interest_areas)
            except:
                interest_areas = None
        
        return StudentResponse(
            id=student.id,
            name=student.name,
            email=student.email,
            phone=student.phone,
            class_level=student.class_level,
            exam_type=student.exam_type,
            field_type=student.field_type,
            tyt_turkish_net=student.tyt_turkish_net,
            tyt_math_net=student.tyt_math_net,
            tyt_social_net=student.tyt_social_net,
            tyt_science_net=student.tyt_science_net,
            ayt_math_net=student.ayt_math_net,
            ayt_physics_net=student.ayt_physics_net,
            ayt_chemistry_net=student.ayt_chemistry_net,
            ayt_biology_net=student.ayt_biology_net,
            ayt_literature_net=student.ayt_literature_net,
            ayt_history1_net=student.ayt_history1_net,
            ayt_geography1_net=student.ayt_geography1_net,
            ayt_philosophy_net=student.ayt_philosophy_net,
            ayt_history2_net=student.ayt_history2_net,
            ayt_geography2_net=student.ayt_geography2_net,
            ayt_religion_net=student.ayt_religion_net,
            ayt_foreign_language_net=student.ayt_foreign_language_net,
            preferred_cities=preferred_cities,
            preferred_university_types=preferred_university_types,
            preferred_departments=preferred_departments,
            budget_preference=student.budget_preference,
            scholarship_preference=student.scholarship_preference,
            interest_areas=interest_areas,
            tyt_total_score=student.tyt_total_score,
            ayt_total_score=student.ayt_total_score,
            total_score=student.total_score,
            obp_score=student.obp_score,
            rank=student.rank,
            percentile=student.percentile,
            avatar_url=student.avatar_url,
            bio=student.bio,
            target_university=student.target_university,
            created_at=student.created_at,
            updated_at=student.updated_at
        )
        
    except StudentNotFoundError:
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(
            f"Error updating profile: {str(e)}",
            error=str(e),
            user_id=student_id
        )
        raise HTTPException(status_code=500, detail=f"Profil güncellenemedi: {str(e)}")

