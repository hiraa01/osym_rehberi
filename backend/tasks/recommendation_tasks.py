"""
Celery tasks for recommendation generation
Uzun süren recommendation hesaplamalarını asenkron olarak çalıştırır
"""
from celery_app import celery_app
from database import SessionLocal
from services.recommendation_engine import RecommendationEngine
from core.logging_config import api_logger
import traceback


@celery_app.task(bind=True, name="generate_recommendations_async")
def generate_recommendations_async(self, student_id: int, limit: int = 50, w_c: float = 0.4, w_s: float = 0.4, w_p: float = 0.2):
    """
    Asenkron recommendation generation task
    
    Args:
        student_id: Öğrenci ID'si
        limit: Öneri limiti
        w_c: Compatibility weight
        w_s: Success probability weight
        w_p: Preference weight
    
    Returns:
        dict: Task sonucu (job_id, status, recommendations)
    """
    db = SessionLocal()
    try:
        api_logger.info(
            f"Starting async recommendation generation",
            student_id=student_id,
            task_id=self.request.id
        )
        
        # Recommendation engine oluştur
        engine = RecommendationEngine(db)
        
        # Önerileri oluştur
        recommendations = engine.generate_recommendations(
            student_id=student_id,
            limit=limit,
            w_c=w_c,
            w_s=w_s,
            w_p=w_p
        )
        
        api_logger.info(
            f"Async recommendation generation completed",
            student_id=student_id,
            task_id=self.request.id,
            recommendations_count=len(recommendations)
        )
        
        return {
            "status": "completed",
            "student_id": student_id,
            "recommendations_count": len(recommendations),
            "job_id": self.request.id
        }
        
    except Exception as e:
        api_logger.error(
            f"Async recommendation generation failed",
            student_id=student_id,
            task_id=self.request.id,
            error=str(e),
            traceback=traceback.format_exc()
        )
        # Celery'ye hata bildir
        self.retry(exc=e, countdown=60, max_retries=3)
        raise
    finally:
        db.close()

