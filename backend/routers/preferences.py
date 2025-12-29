from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, selectinload
from typing import List, Optional, Tuple

from database import get_db
from models import Preference, Student, Department, University
from schemas.preference import PreferenceCreate, PreferenceResponse, PreferenceWithDepartmentResponse
from schemas.university import DepartmentWithUniversityResponse, UniversityResponse
from core.logging_config import api_logger
from core.exceptions import StudentNotFoundError


router = APIRouter()


def calculate_probability(student_score: float, department_min_score: Optional[float]) -> tuple[float, str]:
    """
    Kazanma ihtimalini hesapla
    
    Logic:
    - Eğer (Öğrenci Puanı - Bölüm Puanı) > 20 ise "Yüksek"
    - Eğer (Öğrenci Puanı - Bölüm Puanı) < -20 ise "Düşük"
    - Diğer durumlarda "Orta"
    
    Returns:
        (probability: float, label: str)
    """
    if department_min_score is None:
        return 50.0, "Belirsiz"
    
    score_diff = student_score - department_min_score
    
    if score_diff > 20:
        probability = min(95.0, 70.0 + (score_diff - 20) * 0.5)  # 70-95 arası
        return probability, "Yüksek"
    elif score_diff < -20:
        probability = max(5.0, 30.0 + (score_diff + 20) * 0.5)  # 5-30 arası
        return probability, "Düşük"
    else:
        # -20 ile 20 arası
        probability = 30.0 + ((score_diff + 20) / 40.0) * 40.0  # 30-70 arası
        return probability, "Orta"


def get_university_logo_url(university: University) -> Optional[str]:
    """Üniversite logosu URL'i oluştur"""
    if university.website:
        domain = university.website.replace('http://', '').replace('https://', '').replace('www.', '').split('/')[0]
        return f"https://www.google.com/s2/favicons?domain={domain}&sz=256"
    return None


@router.get("/", response_model=List[PreferenceWithDepartmentResponse])
async def get_preferences(
    student_id: int,
    db: Session = Depends(get_db)
):
    """
    Öğrencinin tercih listesini getir
    
    Dönen veride:
    - Bölüm detayları (DepartmentWithUniversityResponse)
    - Kazanma ihtimali (probability: float, probability_label: str)
    """
    try:
        # Öğrenciyi kontrol et
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {student_id}")
        
        # Tercihleri getir (eager loading ile)
        preferences = db.query(Preference).filter(
            Preference.student_id == student_id
        ).options(
            selectinload(Preference.department).selectinload(Department.university)
        ).order_by(
            Preference.order.asc().nullslast(),
            Preference.created_at.asc()
        ).all()
        
        if not preferences:
            return []
        
        # Response oluştur
        result = []
        for pref in preferences:
            dept = pref.department
            if not dept:
                continue
            
            uni = dept.university
            if not uni:
                continue
            
            # University response
            university_response = UniversityResponse(
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
                logo_url=get_university_logo_url(uni)
            )
            
            # Department response
            import json
            attributes = []
            if dept.attributes:
                try:
                    attributes = json.loads(dept.attributes)
                except:
                    attributes = []
            
            department_response = DepartmentWithUniversityResponse(
                id=dept.id,
                university_id=dept.university_id,
                name=dept.name,
                normalized_name=dept.normalized_name,
                attributes=attributes,
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
                university=university_response
            )
            
            # Kazanma ihtimalini hesapla
            probability, label = calculate_probability(
                student.total_score or 0.0,
                dept.min_score
            )
            
            result.append(PreferenceWithDepartmentResponse(
                id=pref.id,
                student_id=pref.student_id,
                department_id=pref.department_id,
                order=pref.order,
                created_at=pref.created_at,
                department=department_response,
                probability=probability,
                probability_label=label
            ))
        
        api_logger.info(f"Retrieved {len(result)} preferences for student {student_id}")
        return result
        
    except StudentNotFoundError:
        raise
    except Exception as e:
        api_logger.error(f"Error getting preferences: {str(e)}", error=str(e), user_id=student_id)
        raise HTTPException(status_code=500, detail=f"Tercihler getirilemedi: {str(e)}")


@router.post("", response_model=PreferenceResponse)
async def create_preference(
    preference: PreferenceCreate,
    db: Session = Depends(get_db)
):
    """Listeye yeni bölüm ekle"""
    try:
        # Öğrenciyi kontrol et
        student = db.query(Student).filter(Student.id == preference.student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {preference.student_id}")
        
        # Bölümü kontrol et
        department = db.query(Department).filter(Department.id == preference.department_id).first()
        if not department:
            raise HTTPException(status_code=404, detail="Bölüm bulunamadı")
        
        # Aynı bölüm zaten eklenmiş mi kontrol et
        existing = db.query(Preference).filter(
            Preference.student_id == preference.student_id,
            Preference.department_id == preference.department_id
        ).first()
        
        if existing:
            raise HTTPException(
                status_code=400,
                detail="Bu bölüm zaten tercih listenizde mevcut"
            )
        
        # Order belirtilmemişse, mevcut tercih sayısına göre otomatik atama
        if preference.order is None:
            max_order = db.query(Preference).filter(
                Preference.student_id == preference.student_id
            ).count()
            preference.order = max_order + 1
        
        # Yeni tercih oluştur
        db_preference = Preference(
            student_id=preference.student_id,
            department_id=preference.department_id,
            order=preference.order
        )
        db.add(db_preference)
        db.commit()
        db.refresh(db_preference)
        
        api_logger.info(
            f"Preference created: student_id={preference.student_id}, department_id={preference.department_id}",
            user_id=preference.student_id
        )
        
        return db_preference
        
    except (StudentNotFoundError, HTTPException):
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(f"Error creating preference: {str(e)}", error=str(e), user_id=preference.student_id)
        raise HTTPException(status_code=500, detail=f"Tercih eklenemedi: {str(e)}")


@router.delete("/{preference_id}")
async def delete_preference(
    preference_id: int,
    db: Session = Depends(get_db)
):
    """Listeden tercih çıkar"""
    try:
        preference = db.query(Preference).filter(Preference.id == preference_id).first()
        if not preference:
            raise HTTPException(status_code=404, detail="Tercih bulunamadı")
        
        student_id = preference.student_id
        db.delete(preference)
        db.commit()
        
        api_logger.info(f"Preference deleted: id={preference_id}", user_id=student_id)
        
        return {"message": "Tercih başarıyla silindi"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(f"Error deleting preference: {str(e)}", error=str(e))
        raise HTTPException(status_code=500, detail=f"Tercih silinemedi: {str(e)}")

