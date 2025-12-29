from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, or_
from typing import List, Optional
import random
from pydantic import BaseModel, Field

from database import get_db
from models import University, Department, Swipe, Preference, Student
from schemas.university import DepartmentWithUniversityResponse, UniversityResponse
from core.logging_config import api_logger
from core.exceptions import StudentNotFoundError
from routers.universities import get_university_logo_url

router = APIRouter()


class SwipeRequest(BaseModel):
    """Swipe işlemi için request modeli"""
    student_id: int
    department_id: int
    action: str = Field(..., description="'like' veya 'dislike'")


class SwipeResponse(BaseModel):
    """Swipe işlemi response"""
    message: str
    added_to_preferences: bool = False


@router.get("/departments", response_model=List[DepartmentWithUniversityResponse])
async def get_discovery_departments(
    city: Optional[List[str]] = Query(None, description="Şehir listesi (örn: ['İstanbul', 'Ankara'])"),
    field_type: Optional[str] = Query(None, description="Alan türü: SAY, EA, SÖZ, DİL"),
    min_score: Optional[float] = Query(None),
    max_score: Optional[float] = Query(None),
    random: bool = Query(False, description="Rastgele 10 bölüm getir (Keşfet modu için)"),
    db: Session = Depends(get_db)
):
    """
    Gelişmiş filtreleme ile bölümleri getir (Keşfet modülü için)
    
    Özellikler:
    - Şehir listesi ile filtreleme (birden fazla şehir)
    - Alan türü, puan aralığı filtreleme
    - random=true parametresi ile rastgele 10 bölüm getirme
    """
    try:
        from sqlalchemy.orm import selectinload
        
        # Base query
        query = db.query(Department).options(
            selectinload(Department.university)
        )
        
        # Şehir filtresi (birden fazla şehir desteklenir)
        if city:
            query = query.join(University, Department.university_id == University.id)
            # Şehir listesindeki herhangi bir şehirle eşleşen bölümleri getir
            city_filters = [University.city.ilike(f"%{c}%") for c in city]
            query = query.filter(or_(*city_filters))
        
        # Alan türü filtresi
        if field_type:
            query = query.filter(Department.field_type == field_type)
        
        # Puan aralığı filtreleme
        if min_score:
            query = query.filter(Department.min_score.isnot(None), Department.min_score >= min_score)
        if max_score:
            query = query.filter(Department.min_score.isnot(None), Department.min_score <= max_score)
        
        # Rastgele mod: 10 bölüm getir
        if random:
            # Toplam sayıyı al
            total_count = query.count()
            if total_count == 0:
                return []
            
            # Rastgele 10 bölüm seç (veya toplam sayı 10'dan azsa hepsini)
            limit = min(10, total_count)
            
            # PostgreSQL için RANDOM() kullan, SQLite için random() kullan
            from database import engine
            if engine.url.drivername == 'postgresql':
                departments = query.order_by(func.random()).limit(limit).all()
            else:
                # SQLite için: Tüm ID'leri al, rastgele seç, sonra sorgula
                all_ids = [row[0] for row in query.with_entities(Department.id).all()]
                if not all_ids:
                    return []
                selected_ids = random.sample(all_ids, min(limit, len(all_ids)))
                departments = query.filter(Department.id.in_(selected_ids)).all()
        else:
            # Normal mod: Sıralı getir
            from sqlalchemy import case
            query = query.order_by(
                case((Department.min_score.is_(None), 1), else_=0),
                Department.name
            )
            departments = query.limit(100).all()  # Varsayılan limit
        
        # Response oluştur
        result = []
        for dept in departments:
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
            
            dept_response = DepartmentWithUniversityResponse(
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
            result.append(dept_response)
        
        api_logger.info(f"Discovery: Retrieved {len(result)} departments (random={random})")
        return result
        
    except Exception as e:
        api_logger.error(f"Error in discovery departments: {str(e)}", error=str(e))
        raise HTTPException(status_code=500, detail=f"Bölümler getirilemedi: {str(e)}")


@router.post("/swipe", response_model=SwipeResponse)
async def swipe_department(
    swipe_request: SwipeRequest,
    db: Session = Depends(get_db)
):
    """
    Sağa/Sola kaydırma işlemini kaydet (Tinder usulü)
    
    Eğer action='like' ise, bölümü otomatik olarak preferences tablosuna da ekler.
    """
    try:
        # Validasyon
        if swipe_request.action not in ['like', 'dislike']:
            raise HTTPException(status_code=400, detail="action 'like' veya 'dislike' olmalı")
        
        # Öğrenci kontrolü
        student = db.query(Student).filter(Student.id == swipe_request.student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {swipe_request.student_id}")
        
        # Bölüm kontrolü
        department = db.query(Department).filter(Department.id == swipe_request.department_id).first()
        if not department:
            raise HTTPException(status_code=404, detail="Bölüm bulunamadı")
        
        # Mevcut swipe kontrolü
        existing_swipe = db.query(Swipe).filter(
            Swipe.student_id == swipe_request.student_id,
            Swipe.department_id == swipe_request.department_id
        ).first()
        
        if existing_swipe:
            # Mevcut swipe'ı güncelle
            existing_swipe.action = swipe_request.action
            db.commit()
            api_logger.info(
                f"Swipe updated: student_id={swipe_request.student_id}, department_id={swipe_request.department_id}, action={swipe_request.action}",
                user_id=swipe_request.student_id
            )
        else:
            # Yeni swipe oluştur
            db_swipe = Swipe(
                student_id=swipe_request.student_id,
                department_id=swipe_request.department_id,
                action=swipe_request.action
            )
            db.add(db_swipe)
            db.commit()
            api_logger.info(
                f"Swipe created: student_id={swipe_request.student_id}, department_id={swipe_request.department_id}, action={swipe_request.action}",
                user_id=swipe_request.student_id
            )
        
        # Eğer 'like' ise, preferences tablosuna da ekle
        added_to_preferences = False
        if swipe_request.action == 'like':
            # Mevcut preference kontrolü
            existing_preference = db.query(Preference).filter(
                Preference.student_id == swipe_request.student_id,
                Preference.department_id == swipe_request.department_id
            ).first()
            
            if not existing_preference:
                # Yeni preference oluştur
                # Order'ı mevcut tercih sayısına göre belirle
                max_order = db.query(Preference).filter(
                    Preference.student_id == swipe_request.student_id
                ).count()
                
                db_preference = Preference(
                    student_id=swipe_request.student_id,
                    department_id=swipe_request.department_id,
                    order=max_order + 1
                )
                db.add(db_preference)
                db.commit()
                added_to_preferences = True
                api_logger.info(
                    f"Department added to preferences via swipe: student_id={swipe_request.student_id}, department_id={swipe_request.department_id}",
                    user_id=swipe_request.student_id
                )
        
        action_text = "beğenildi" if swipe_request.action == 'like' else "beğenilmedi"
        message = f"Bölüm {action_text} ve kaydedildi."
        if added_to_preferences:
            message += " Tercih listenize de eklendi."
        
        return SwipeResponse(
            message=message,
            added_to_preferences=added_to_preferences
        )
        
    except (HTTPException, StudentNotFoundError):
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(
            f"Error in swipe: {str(e)}",
            error=str(e),
            user_id=swipe_request.student_id
        )
        raise HTTPException(status_code=500, detail=f"Swipe işlemi başarısız: {str(e)}")

