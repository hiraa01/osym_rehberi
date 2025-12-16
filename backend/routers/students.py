from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional
import json

from database import get_db
from models.student import Student
from schemas.student import StudentCreate, StudentUpdate, StudentResponse, StudentListResponse
from services.score_calculator import ScoreCalculator
from core.logging_config import api_logger
from services.recommendation_engine import RecommendationEngine
from routers.ml_recommendations import train_models_background
from core.exceptions import StudentNotFoundError, InvalidScoreError

router = APIRouter()


@router.post("/", response_model=StudentResponse)
async def create_student(student: StudentCreate, db: Session = Depends(get_db)):
    """Yeni öğrenci profili oluştur"""
    try:
        api_logger.info("Creating new student profile", name=student.name)
        
        # Puanları hesapla
        student_data = student.dict()
        scores = ScoreCalculator.calculate_all_scores(student_data)
        
        # JSON alanları için dönüşüm
        preferred_cities = json.dumps(student.preferred_cities) if student.preferred_cities else None
        preferred_university_types = json.dumps(student.preferred_university_types) if student.preferred_university_types else None
        preferred_departments = json.dumps(student.preferred_departments) if student.preferred_departments else None
        interest_areas = json.dumps(student.interest_areas) if student.interest_areas else None
        
        # Veritabanı nesnesi oluştur
        db_student = Student(
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
            **scores
        )
        
        db.add(db_student)
        db.commit()
        db.refresh(db_student)
        
        api_logger.info("Student profile created successfully", student_id=db_student.id)
        return db_student
        
    except InvalidScoreError as e:
        api_logger.error(f"Invalid score error: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        api_logger.error(f"Error creating student: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=500, detail="Öğrenci profili oluşturulurken bir hata oluştu")


@router.get("/", response_model=StudentListResponse)
async def get_students(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db)
):
    """Öğrenci listesini getir"""
    students = db.query(Student).offset(skip).limit(limit).all()
    total = db.query(Student).count()
    
    return StudentListResponse(
        students=students,
        total=total,
        page=skip // limit + 1,
        size=limit
    )


@router.get("/{student_id}", response_model=StudentResponse)
async def get_student(student_id: int, db: Session = Depends(get_db)):
    """Belirli bir öğrenciyi getir"""
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")
    return student


@router.put("/{student_id}", response_model=StudentResponse)
async def update_student(
    student_id: int, 
    student_update: StudentUpdate, 
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Öğrenci bilgilerini güncelle"""
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")
    
    # Güncellenecek alanları belirle
    update_data = student_update.dict(exclude_unset=True)
    
    # Eğer net skorlar güncelleniyorsa, puanları yeniden hesapla
    if any(key in update_data for key in [
        'tyt_turkish_net', 'tyt_math_net', 'tyt_social_net', 'tyt_science_net',
        'ayt_math_net', 'ayt_physics_net', 'ayt_chemistry_net', 'ayt_biology_net',
        'ayt_literature_net', 'ayt_history1_net', 'ayt_geography1_net', 'ayt_philosophy_net',
        'ayt_history2_net', 'ayt_geography2_net', 'ayt_religion_net', 'ayt_foreign_language_net'
    ]):
        # Mevcut verilerle güncellenmiş verileri birleştir
        student_data = student.__dict__.copy()
        student_data.update(update_data)
        scores = ScoreCalculator.calculate_all_scores(student_data)
        update_data.update(scores)
    
    # JSON alanları için dönüşüm
    if 'preferred_cities' in update_data and update_data['preferred_cities']:
        update_data['preferred_cities'] = json.dumps(update_data['preferred_cities'])
    if 'preferred_university_types' in update_data and update_data['preferred_university_types']:
        update_data['preferred_university_types'] = json.dumps(update_data['preferred_university_types'])
    if 'preferred_departments' in update_data and update_data['preferred_departments']:
        update_data['preferred_departments'] = json.dumps(update_data['preferred_departments'])
    if 'interest_areas' in update_data and update_data['interest_areas']:
        update_data['interest_areas'] = json.dumps(update_data['interest_areas'])
    
    # Güncellemeleri uygula
    for field, value in update_data.items():
        setattr(student, field, value)
    
    db.commit()
    db.refresh(student)

    # Tercihler değiştiğinde önerileri ve ML eğitimini arka planda tetikle
    try:
        def _regenerate_recommendations_task(student_id_inner: int):
            engine = RecommendationEngine(db)
            try:
                engine.generate_recommendations(student_id_inner, limit=50)
            except Exception as e:
                api_logger.error("Recommendation regen failed", user_id=student_id_inner, error=str(e))

        background_tasks.add_task(_regenerate_recommendations_task, student.id)
        background_tasks.add_task(train_models_background, db)
    except Exception as bt_err:
        api_logger.warning("Background tasks scheduling failed", error=str(bt_err))
    
    return student


@router.delete("/{student_id}")
async def delete_student(student_id: int, db: Session = Depends(get_db)):
    """Öğrenciyi sil"""
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")
    
    db.delete(student)
    db.commit()
    
    return {"message": "Öğrenci başarıyla silindi"}


@router.post("/{student_id}/calculate-scores")
async def calculate_scores(student_id: int, db: Session = Depends(get_db)):
    """Öğrencinin puanlarını yeniden hesapla"""
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")
    
    # Puanları hesapla
    student_data = student.__dict__.copy()
    scores = ScoreCalculator.calculate_all_scores(student_data)
    
    # Güncellemeleri uygula
    for field, value in scores.items():
        setattr(student, field, value)
    
    db.commit()
    db.refresh(student)
    
    return {"message": "Puanlar başarıyla hesaplandı", "scores": scores}
