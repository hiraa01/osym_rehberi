from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from models.exam_attempt import ExamAttempt
from models.student import Student
from schemas.exam_attempt import (
    ExamAttemptCreate, 
    ExamAttemptUpdate, 
    ExamAttemptResponse,
    ExamAttemptListResponse
)
from services.score_calculator import ScoreCalculator
from core.logging_config import api_logger

router = APIRouter()


@router.post("/", response_model=ExamAttemptResponse)
async def create_exam_attempt(
    attempt: ExamAttemptCreate, 
    db: Session = Depends(get_db)
):
    """Yeni deneme sonucu ekle ve puanları otomatik hesapla"""
    try:
        # Öğrenci kontrolü
        student = db.query(Student).filter(Student.id == attempt.student_id).first()
        if not student:
            raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")
        
        # Puanları hesapla (öğrencinin field_type'ını kullan)
        attempt_data = attempt.dict()
        attempt_data['field_type'] = student.field_type  # ✅ field_type eklendi!
        scores = ScoreCalculator.calculate_all_scores(attempt_data)
        
        # Deneme kaydet
        db_attempt = ExamAttempt(
            **attempt.dict(),
            tyt_score=scores['tyt_total_score'],
            ayt_score=scores['ayt_total_score'],
            total_score=scores['total_score'],
            obp_score=attempt_data.get('obp_score', 0.0)  # ✅ OBP eklendi
        )
        
        db.add(db_attempt)
        
        # ✅ Öğrencinin son skorlarını güncelle
        student.tyt_turkish_net = attempt_data.get('tyt_turkish_net', 0.0)
        student.tyt_math_net = attempt_data.get('tyt_math_net', 0.0)
        student.tyt_social_net = attempt_data.get('tyt_social_net', 0.0)
        student.tyt_science_net = attempt_data.get('tyt_science_net', 0.0)
        student.ayt_math_net = attempt_data.get('ayt_math_net', 0.0)
        student.ayt_physics_net = attempt_data.get('ayt_physics_net', 0.0)
        student.ayt_chemistry_net = attempt_data.get('ayt_chemistry_net', 0.0)
        student.ayt_biology_net = attempt_data.get('ayt_biology_net', 0.0)
        student.ayt_literature_net = attempt_data.get('ayt_literature_net', 0.0)
        student.ayt_history1_net = attempt_data.get('ayt_history1_net', 0.0)
        student.ayt_geography1_net = attempt_data.get('ayt_geography1_net', 0.0)
        student.ayt_philosophy_net = attempt_data.get('ayt_philosophy_net', 0.0)
        student.ayt_history2_net = attempt_data.get('ayt_history2_net', 0.0)
        student.ayt_geography2_net = attempt_data.get('ayt_geography2_net', 0.0)
        student.ayt_foreign_language_net = attempt_data.get('ayt_foreign_language_net', 0.0)
        student.tyt_total_score = scores['tyt_total_score']
        student.ayt_total_score = scores['ayt_total_score']
        student.total_score = scores['total_score']
        student.obp_score = attempt_data.get('obp_score', 0.0)  # ✅ OBP güncellendi
        student.rank = scores['rank']
        student.percentile = scores['percentile']
        
        db.commit()
        db.refresh(db_attempt)
        
        api_logger.info(
            "Exam attempt created and student scores updated", 
            student_id=attempt.student_id, 
            attempt_number=attempt.attempt_number,
            total_score=scores['total_score'],
            rank=scores['rank']
        )
        
        return db_attempt
        
    except HTTPException:
        raise
    except Exception as e:
        api_logger.error(f"Error creating exam attempt: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Deneme kaydedilirken hata oluştu: {str(e)}")


@router.get("/student/{student_id}", response_model=ExamAttemptListResponse)
async def get_student_attempts(
    student_id: int,
    db: Session = Depends(get_db)
):
    """Öğrencinin tüm denemelerini getir"""
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")
    
    attempts = db.query(ExamAttempt)\
        .filter(ExamAttempt.student_id == student_id)\
        .order_by(ExamAttempt.attempt_number.desc())\
        .all()
    
    total = len(attempts)
    average_score = sum(a.total_score for a in attempts) / total if total > 0 else 0.0
    
    return ExamAttemptListResponse(
        attempts=attempts,
        total=total,
        average_score=average_score
    )


@router.get("/{attempt_id}", response_model=ExamAttemptResponse)
async def get_exam_attempt(attempt_id: int, db: Session = Depends(get_db)):
    """Belirli bir denemeyi getir"""
    attempt = db.query(ExamAttempt).filter(ExamAttempt.id == attempt_id).first()
    if not attempt:
        raise HTTPException(status_code=404, detail="Deneme bulunamadı")
    return attempt


@router.put("/{attempt_id}", response_model=ExamAttemptResponse)
async def update_exam_attempt(
    attempt_id: int,
    attempt_update: ExamAttemptUpdate,
    db: Session = Depends(get_db)
):
    """Deneme bilgilerini güncelle"""
    attempt = db.query(ExamAttempt).filter(ExamAttempt.id == attempt_id).first()
    if not attempt:
        raise HTTPException(status_code=404, detail="Deneme bulunamadı")
    
    # Güncellenecek alanları belirle
    update_data = attempt_update.dict(exclude_unset=True)
    
    # Net skorlar güncelleniyorsa puanları yeniden hesapla
    if any(key in update_data for key in [
        'tyt_turkish_net', 'tyt_math_net', 'tyt_social_net', 'tyt_science_net',
        'ayt_math_net', 'ayt_physics_net', 'ayt_chemistry_net', 'ayt_biology_net',
        'ayt_literature_net', 'ayt_history1_net', 'ayt_geography1_net', 'ayt_philosophy_net',
        'ayt_history2_net', 'ayt_geography2_net', 'ayt_foreign_language_net'
    ]):
        attempt_data = attempt.__dict__.copy()
        attempt_data.update(update_data)
        scores = ScoreCalculator.calculate_all_scores(attempt_data)
        update_data['tyt_score'] = scores['tyt_total_score']
        update_data['ayt_score'] = scores['ayt_total_score']
        update_data['total_score'] = scores['total_score']
    
    # Güncellemeleri uygula
    for field, value in update_data.items():
        setattr(attempt, field, value)
    
    db.commit()
    db.refresh(attempt)
    
    return attempt


@router.delete("/{attempt_id}")
async def delete_exam_attempt(attempt_id: int, db: Session = Depends(get_db)):
    """Denemeyi sil"""
    attempt = db.query(ExamAttempt).filter(ExamAttempt.id == attempt_id).first()
    if not attempt:
        raise HTTPException(status_code=404, detail="Deneme bulunamadı")
    
    db.delete(attempt)
    db.commit()
    
    return {"message": "Deneme başarıyla silindi"}

