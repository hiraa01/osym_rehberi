"""
Targets Router - Tercih hedefleri yönetimi (Preference modelini kullanır)
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy.orm import selectinload
from typing import List, Optional

from database import get_db
from models import Preference, Student, Department, University
from schemas.preference import (
    PreferenceCreate, PreferenceResponse, PreferenceWithDepartmentResponse
)
from schemas.university import DepartmentWithUniversityResponse
from core.logging_config import api_logger
from core.exceptions import StudentNotFoundError

router = APIRouter()


@router.get("", response_model=List[PreferenceWithDepartmentResponse])
async def get_targets(
    student_id: int = Query(..., description="Öğrenci ID"),
    db: Session = Depends(get_db)
):
    """
    Öğrencinin tercih hedeflerini listele (Bölüm detaylarıyla birlikte)
    """
    try:
        # Öğrenci var mı kontrol et
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {student_id}")

        # Tercihleri getir (eager loading ile)
        preferences = db.query(Preference).filter(
            Preference.student_id == student_id
        ).options(
            selectinload(Preference.department).selectinload(Department.university)
        ).order_by(Preference.order, Preference.created_at).all()

        result = []
        for pref in preferences:
            dept = pref.department
            uni = dept.university if dept else None


            # Kazanma ihtimali hesapla (detaylı)
            probability_value = 50.0
            if student and dept and dept.min_score:
                score_diff = (student.total_score or 0) - dept.min_score
                if score_diff > 20:
                    probability_value = 85.0
                    probability = "Yüksek"
                elif score_diff < -20:
                    probability_value = 15.0
                    probability = "Düşük"
                else:
                    probability_value = 50.0
                    probability = "Orta"
            else:
                probability = "Belirsiz"
                probability_value = 50.0

            # DepartmentWithUniversityResponse oluştur
            from schemas.university import UniversityResponse
            
            dept_response = None
            if dept:
                uni_response = None
                if uni:
                    uni_response = UniversityResponse(
                        id=uni.id,
                        name=uni.name,
                        city=uni.city,
                        university_type=uni.university_type,
                        website=uni.website,
                        established_year=uni.established_year,
                        latitude=uni.latitude,
                        longitude=uni.longitude,
                        created_at=uni.created_at,
                        updated_at=uni.updated_at,
                        logo_url=None
                    )
                
                dept_response = DepartmentWithUniversityResponse(
                    id=dept.id,
                    university_id=dept.university_id,
                    name=dept.name,
                    normalized_name=dept.normalized_name,
                    attributes=dept.attributes,
                    field_type=dept.field_type,
                    language=dept.language,
                    faculty=dept.faculty,
                    duration=dept.duration,
                    degree_type=dept.degree_type,
                    min_score=dept.min_score,
                    min_rank=dept.min_rank,
                    quota=dept.quota,
                    scholarship_quota=dept.scholarship_quota,
                    tuition_fee=dept.tuition_fee,
                    has_scholarship=dept.has_scholarship,
                    last_year_min_score=dept.last_year_min_score,
                    last_year_min_rank=dept.last_year_min_rank,
                    last_year_quota=dept.last_year_quota,
                    description=dept.description,
                    requirements=dept.requirements,
                    created_at=dept.created_at,
                    updated_at=dept.updated_at,
                    university=uni_response
                )

            result.append(PreferenceWithDepartmentResponse(
                id=pref.id,
                student_id=pref.student_id,
                department_id=pref.department_id,
                order=pref.order,
                created_at=pref.created_at,
                department=dept_response,
                probability=probability_value,
                probability_label=probability
            ))

        return result
    except StudentNotFoundError:
        raise
    except Exception as e:
        api_logger.error(f"Error getting targets: {str(e)}")
        raise HTTPException(status_code=500, detail="Tercih hedefleri alınırken bir hata oluştu")


@router.post("", response_model=PreferenceResponse)
async def add_target(
    preference: PreferenceCreate,
    db: Session = Depends(get_db)
):
    """
    Yeni tercih hedefi ekle
    """
    try:
        # Öğrenci var mı kontrol et
        student = db.query(Student).filter(Student.id == preference.student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {preference.student_id}")

        # Bölüm var mı kontrol et
        department = db.query(Department).filter(Department.id == preference.department_id).first()
        if not department:
            raise HTTPException(status_code=404, detail="Bölüm bulunamadı")

        # Aynı tercih zaten var mı kontrol et
        existing = db.query(Preference).filter(
            Preference.student_id == preference.student_id,
            Preference.department_id == preference.department_id
        ).first()
        if existing:
            raise HTTPException(status_code=400, detail="Bu bölüm zaten tercih listesinde")

        # Yeni tercih oluştur
        new_preference = Preference(
            student_id=preference.student_id,
            department_id=preference.department_id,
            order=preference.order
        )

        db.add(new_preference)
        db.commit()
        db.refresh(new_preference)

        api_logger.info(f"Target added: id={new_preference.id}, student_id={preference.student_id}, department_id={preference.department_id}")
        return PreferenceResponse.from_orm(new_preference)
    except (StudentNotFoundError, HTTPException):
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(f"Error adding target: {str(e)}")
        raise HTTPException(status_code=500, detail="Tercih hedefi eklenirken bir hata oluştu")


@router.delete("/{preference_id}")
async def delete_target(
    preference_id: int,
    db: Session = Depends(get_db)
):
    """
    Tercih hedefini sil
    """
    try:
        preference = db.query(Preference).filter(Preference.id == preference_id).first()
        if not preference:
            raise HTTPException(status_code=404, detail="Tercih hedefi bulunamadı")

        db.delete(preference)
        db.commit()

        api_logger.info(f"Target deleted: id={preference_id}")
        return {"message": "Tercih hedefi başarıyla silindi", "id": preference_id}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(f"Error deleting target: {str(e)}")
        raise HTTPException(status_code=500, detail="Tercih hedefi silinirken bir hata oluştu")

