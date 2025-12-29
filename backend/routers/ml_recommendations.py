from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List
import asyncio

from database import get_db
from services.ml_recommendation_engine import MLRecommendationEngine
from schemas.ml_recommendations import MLRecommendationResponse, MLModelStatusResponse, MLTrainingResponse
from schemas.university import DepartmentWithUniversityResponse
from models import University
from core.logging_config import api_logger
from core.exceptions import StudentNotFoundError

router = APIRouter()

@router.post("/train-models", response_model=MLTrainingResponse)
async def train_ml_models(background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    """ML modellerini eğit (arka planda)"""
    try:
        api_logger.info("ML model training requested")
        
        # Arka planda eğitimi başlat
        background_tasks.add_task(train_models_background, db)
        
        return MLTrainingResponse(
            message="ML model eğitimi başlatıldı. Eğitim tamamlandığında bildirim alacaksınız.",
            status="training_started"
        )
    except Exception as e:
        api_logger.error("ML training failed", error=str(e))
        raise HTTPException(status_code=500, detail=f"Model eğitimi başlatılamadı: {str(e)}")

@router.get("/ml-recommendations/{student_id}", response_model=List[MLRecommendationResponse])
async def get_ml_recommendations(
    student_id: int, 
    limit: int = 50,
    w_c: float = 0.4,
    w_s: float = 0.4,
    w_p: float = 0.2,
    db: Session = Depends(get_db)
):
    """ML destekli öneriler oluştur"""
    try:
        api_logger.info("ML recommendations requested", user_id=student_id, limit=limit)
        
        ml_engine = MLRecommendationEngine(db)
        
        # Ağırlıkları normalize et
        total_w = max(1e-9, (w_c + w_s + w_p))
        weights = (w_c / total_w, w_s / total_w, w_p / total_w)
        
        # ML önerileri oluştur
        recommendations = ml_engine.generate_recommendations(student_id, limit, weights)
        
        if not recommendations:
            raise HTTPException(status_code=404, detail="Öneri bulunamadı")
        
        # Response formatına çevir (ML dict çıktısı VEYA kural tabanlı Pydantic çıktısı desteklenir)
        result = []
        for rec in recommendations:
            # ML motoru dict döner
            if isinstance(rec, dict):
                department = rec['department']
                university = db.query(University).filter(University.id == department.university_id).first()
                result.append(MLRecommendationResponse(
                    id=rec.get('id'),
                    student_id=rec['student_id'],
                    department_id=rec['department_id'],
                    compatibility_score=rec['compatibility_score'],
                    success_probability=rec['success_probability'],
                    preference_score=rec['preference_score'],
                    final_score=rec['final_score'],
                    recommendation_reason=rec['recommendation_reason'],
                    is_safe_choice=rec['is_safe_choice'],
                    is_dream_choice=rec['is_dream_choice'],
                    is_realistic_choice=rec['is_realistic_choice'],
                    department=DepartmentWithUniversityResponse(
                        **department.__dict__,
                        university=university
                    )
                ))
            else:
                # Kural tabanlı motor RecommendationResponse (Pydantic) döner
                # rec.department zaten DepartmentWithUniversityResponse tipinde
                result.append(MLRecommendationResponse(
                    id=getattr(rec, 'id', None),
                    student_id=rec.student_id,
                    department_id=rec.department_id,
                    compatibility_score=rec.compatibility_score,
                    success_probability=rec.success_probability,
                    preference_score=rec.preference_score,
                    final_score=rec.final_score,
                    recommendation_reason=rec.recommendation_reason,
                    is_safe_choice=rec.is_safe_choice,
                    is_dream_choice=rec.is_dream_choice,
                    is_realistic_choice=rec.is_realistic_choice,
                    department=rec.department
                ))
        
        return result
        
    except StudentNotFoundError:
        raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")
    except Exception as e:
        api_logger.error("ML recommendations failed", error=str(e))
        raise HTTPException(status_code=500, detail=f"Öneriler oluşturulamadı: {str(e)}")

@router.get("/model-status", response_model=MLModelStatusResponse)
async def get_model_status(db: Session = Depends(get_db)):
    """ML model durumunu kontrol et"""
    try:
        ml_engine = MLRecommendationEngine(db)
        
        return MLModelStatusResponse(
            is_trained=ml_engine.is_trained,
            models_available=list(ml_engine.models.keys()),
            message="Modeller eğitilmiş" if ml_engine.is_trained else "Modeller henüz eğitilmemiş"
        )
    except Exception as e:
        api_logger.error("Model status check failed", error=str(e))
        raise HTTPException(status_code=500, detail=f"Model durumu kontrol edilemedi: {str(e)}")

async def train_models_background(db: Session):
    """Arka planda model eğitimi"""
    try:
        api_logger.info("Background ML training started")
        
        # Eğitim verisi oluştur
        from scripts.train_ml_models import generate_training_data
        training_data = generate_training_data()
        
        # ML engine oluştur ve eğit
        ml_engine = MLRecommendationEngine(db)
        ml_engine.train_models(training_data)
        
        api_logger.info("Background ML training completed successfully")
        
    except Exception as e:
        api_logger.error("Background ML training failed", error=str(e))
