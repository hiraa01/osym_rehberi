from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
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
from services.recommendation_engine import RecommendationEngine
from routers.ml_recommendations import train_models_background
from core.logging_config import api_logger
from core.logging_config import api_logger

router = APIRouter()


@router.post("/", response_model=ExamAttemptResponse)
async def create_exam_attempt(
    attempt: ExamAttemptCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Yeni deneme sonucu ekle ve puanları otomatik hesapla"""
    try:
        api_logger.info(f"Creating exam attempt for student_id={attempt.student_id}")
        
        # Öğrenci kontrolü
        api_logger.debug(f"Checking student existence: student_id={attempt.student_id}")
        student = db.query(Student).filter(Student.id == attempt.student_id).first()
        if not student:
            api_logger.warning(f"Student not found: student_id={attempt.student_id}")
            raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")
        
        # ✅ attempt_number'ı otomatik hesapla (öğrencinin mevcut deneme sayısına göre)
        if attempt.attempt_number is None:
            existing_attempts_count = db.query(ExamAttempt).filter(
                ExamAttempt.student_id == attempt.student_id
            ).count()
            attempt_number = existing_attempts_count + 1
            api_logger.debug(f"Auto-calculated attempt_number={attempt_number} for student_id={attempt.student_id}")
        else:
            attempt_number = attempt.attempt_number
        
        # Puanları hesapla (öğrencinin field_type'ını kullan)
        api_logger.debug(f"Calculating scores for student_id={attempt.student_id}")
        attempt_data = attempt.dict()
        attempt_data['field_type'] = student.field_type  # ✅ field_type eklendi!
        attempt_data['attempt_number'] = attempt_number  # ✅ attempt_number eklendi!
        scores = ScoreCalculator.calculate_all_scores(attempt_data)
        api_logger.debug(f"Scores calculated: total_score={scores.get('total_score')}")
        
        # Deneme kaydet - obp_score'u dict'ten çıkarıp ayrı ver
        attempt_dict = attempt.dict()
        attempt_dict['attempt_number'] = attempt_number  # ✅ attempt_number eklendi!
        obp_score = attempt_dict.pop('obp_score', 0.0)  # ✅ obp_score'u çıkar
        
        api_logger.debug(f"Creating ExamAttempt object for student_id={attempt.student_id}")
        db_attempt = ExamAttempt(
            **attempt_dict,
            tyt_score=scores['tyt_total_score'],
            ayt_score=scores['ayt_total_score'],
            total_score=scores['total_score'],
            obp_score=obp_score  # ✅ OBP ayrı veriliyor
        )
        
        db.add(db_attempt)
        api_logger.debug(f"ExamAttempt added to session")
        
        # ✅ Öğrencinin son skorlarını güncelle
        api_logger.debug(f"Updating student scores for student_id={attempt.student_id}")
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
        
        # ✅ Güvenli commit işlemi
        api_logger.debug(f"Committing transaction for student_id={attempt.student_id}")
        try:
            db.commit()
            api_logger.debug(f"Transaction committed successfully")
        except Exception as commit_error:
            api_logger.error(f"Commit failed: {str(commit_error)}")
            db.rollback()
            raise HTTPException(
                status_code=500,
                detail="Veritabanına kayıt yapılamadı. Lütfen tekrar deneyin."
            )
        
        # ✅ Güvenli refresh işlemi
        try:
            db.refresh(db_attempt)
            api_logger.debug(f"ExamAttempt refreshed successfully")
        except Exception as refresh_error:
            api_logger.warning(f"Refresh failed (non-critical): {str(refresh_error)}")
            # Refresh hatası kritik değil, response'u gönderebiliriz

        # Arka planda önerileri ve ML eğitimini tetikle (non-blocking)
        try:
            student_id = attempt.student_id

            def _regenerate_recommendations_task(student_id_inner: int):
                # Yeni DB session oluştur (background task için)
                from database import SessionLocal
                bg_db = SessionLocal()
                try:
                    engine = RecommendationEngine(bg_db)
                    try:
                        engine.generate_recommendations(student_id_inner, limit=50)
                    except Exception as e:
                        api_logger.error("Recommendation regen failed", user_id=student_id_inner, error=str(e))
                finally:
                    bg_db.close()

            background_tasks.add_task(_regenerate_recommendations_task, student_id)
            background_tasks.add_task(train_models_background, db)
        except Exception as bt_err:
            api_logger.warning("Background tasks scheduling failed", error=str(bt_err))
            # Background task hatası kritik değil, response'u gönderebiliriz
        
        api_logger.info(
            "Exam attempt created and student scores updated successfully", 
            student_id=attempt.student_id, 
            attempt_number=attempt.attempt_number,
            total_score=scores['total_score'],
            rank=scores['rank'],
            attempt_id=db_attempt.id if hasattr(db_attempt, 'id') else None
        )
        
        # ✅ Response'u güvenli şekilde döndür
        try:
            return db_attempt
        except Exception as response_error:
            api_logger.error(f"Error serializing response: {str(response_error)}")
            # Response serialize edilemezse bile başarılı olduğunu belirt
            raise HTTPException(
                status_code=500,
                detail="Deneme kaydedildi ancak yanıt oluşturulamadı. Lütfen sayfayı yenileyin."
            )
        
    except HTTPException as he:
        api_logger.error(
            f"HTTPException in create_exam_attempt: {he.detail}",
            student_id=attempt.student_id if hasattr(attempt, 'student_id') else None,
            status_code=he.status_code
        )
        try:
            db.rollback()
        except Exception:
            pass
        raise
    except Exception as e:
        api_logger.error(
            f"Error creating exam attempt: {str(e)}",
            student_id=attempt.student_id if hasattr(attempt, 'student_id') else None,
            error_type=type(e).__name__,
            error_traceback=str(e.__traceback__) if hasattr(e, '__traceback__') else None
        )
        try:
            db.rollback()
        except Exception as rollback_error:
            api_logger.error(f"Rollback failed: {str(rollback_error)}")
        
        # Güvenli hata mesajı döndür
        raise HTTPException(
            status_code=500,
            detail="Deneme kaydedilirken bir hata oluştu. Lütfen tekrar deneyin."
        )


@router.get("/student/{student_id}", response_model=ExamAttemptListResponse)
async def get_student_attempts(
    student_id: int,
    db: Session = Depends(get_db)
):
    """Öğrencinin tüm denemelerini getir"""
    try:
        api_logger.info(f"Getting attempts for student_id={student_id}")
        
        # Öğrenci kontrolü
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            api_logger.warning(f"Student not found: student_id={student_id}")
            raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")
        
        # ✅ OPTIMIZED: Index kullanarak hızlı sorgu + composite index ile sıralama
        api_logger.debug(f"Querying attempts for student_id={student_id}")
        # Composite index (student_id, attempt_number) kullanarak hızlı sorgu
        # Limit ekle - performans için
        attempts = db.query(ExamAttempt)\
            .filter(ExamAttempt.student_id == student_id)\
            .order_by(ExamAttempt.attempt_number.desc())\
            .limit(100)\
            .all()
        
        api_logger.debug(f"Found {len(attempts)} attempts for student_id={student_id}")
        
        total = len(attempts)
        average_score = sum(a.total_score for a in attempts) / total if total > 0 else 0.0
        
        # Response oluşturma
        api_logger.debug(f"Creating response for student_id={student_id}")
        response = ExamAttemptListResponse(
            attempts=attempts,
            total=total,
            average_score=average_score
        )
        
        api_logger.info(
            "Student attempts retrieved successfully",
            student_id=student_id,
            total_attempts=total,
            average_score=average_score
        )
        
        return response
        
    except HTTPException as he:
        api_logger.error(
            f"HTTPException in get_student_attempts: {he.detail}",
            student_id=student_id,
            status_code=he.status_code
        )
        raise
    except Exception as e:
        api_logger.error(
            f"Error retrieving student attempts: {str(e)}",
            student_id=student_id,
            error_type=type(e).__name__,
            error_traceback=str(e.__traceback__) if hasattr(e, '__traceback__') else None
        )
        try:
            db.rollback()
        except Exception as rollback_error:
            api_logger.error(f"Rollback failed: {str(rollback_error)}")
        
        # Güvenli hata mesajı döndür
        raise HTTPException(
            status_code=500,
            detail="Denemeler getirilirken bir hata oluştu. Lütfen tekrar deneyin."
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
    background_tasks: BackgroundTasks,
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

    # Arka planda önerileri ve ML eğitimini tetikle
    try:
        student_id = attempt.student_id

        def _regenerate_recommendations_task(student_id_inner: int):
            engine = RecommendationEngine(db)
            try:
                engine.generate_recommendations(student_id_inner, limit=50)
            except Exception as e:
                api_logger.error("Recommendation regen failed", user_id=student_id_inner, error=str(e))

        background_tasks.add_task(_regenerate_recommendations_task, student_id)
        background_tasks.add_task(train_models_background, db)
    except Exception as bt_err:
        api_logger.warning("Background tasks scheduling failed", error=str(bt_err))
    
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

