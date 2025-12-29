from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import List, Dict, Any
from datetime import datetime

from database import get_db
from models import Student, ExamAttempt
from core.logging_config import api_logger
from core.exceptions import StudentNotFoundError

router = APIRouter()


@router.get("/progress")
async def get_student_progress(
    student_id: int,
    db: Session = Depends(get_db)
):
    """
    Öğrencinin son 10 denemesindeki net değişimini getir
    
    Grafik çizimi için uygun formatta döner:
    [
        {
            "date": "2024-01-01",
            "attempt_number": 1,
            "tyt_total": 65.5,
            "ayt_total": 45.0,
            "total_score": 110.5,
            "tyt_turkish": 15.0,
            "tyt_math": 20.0,
            "tyt_social": 12.0,
            "tyt_science": 18.5,
            ...
        },
        ...
    ]
    """
    try:
        # Öğrenci kontrolü
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {student_id}")
        
        # Son 10 denemeyi getir
        attempts = db.query(ExamAttempt).filter(
            ExamAttempt.student_id == student_id
        ).order_by(desc(ExamAttempt.created_at)).limit(10).all()
        
        if not attempts:
            return {
                "student_id": student_id,
                "progress": [],
                "message": "Henüz deneme kaydı bulunmuyor"
            }
        
        # Progress verilerini hazırla
        progress = []
        for attempt in reversed(attempts):  # En eski en başta
            # TYT toplam net
            tyt_total = (
                (attempt.tyt_turkish_net or 0.0) +
                (attempt.tyt_math_net or 0.0) +
                (attempt.tyt_social_net or 0.0) +
                (attempt.tyt_science_net or 0.0)
            )
            
            # AYT toplam net (field_type'a göre)
            ayt_total = 0.0
            if student.field_type == "SAY":
                ayt_total = (
                    (attempt.ayt_math_net or 0.0) +
                    (attempt.ayt_physics_net or 0.0) +
                    (attempt.ayt_chemistry_net or 0.0) +
                    (attempt.ayt_biology_net or 0.0)
                )
            elif student.field_type == "EA":
                ayt_total = (
                    (attempt.ayt_math_net or 0.0) +
                    (attempt.ayt_literature_net or 0.0) +
                    (attempt.ayt_history1_net or 0.0) +
                    (attempt.ayt_geography1_net or 0.0)
                )
            elif student.field_type == "SÖZ":
                ayt_total = (
                    (attempt.ayt_literature_net or 0.0) +
                    (attempt.ayt_history1_net or 0.0) +
                    (attempt.ayt_geography1_net or 0.0) +
                    (attempt.ayt_history2_net or 0.0) +
                    (attempt.ayt_geography2_net or 0.0) +
                    (attempt.ayt_philosophy_net or 0.0) +
                    (attempt.ayt_religion_net or 0.0)
                )
            elif student.field_type == "DİL":
                ayt_total = attempt.ayt_foreign_language_net or 0.0
            
            # Tarih formatı
            date_str = attempt.exam_date.strftime("%Y-%m-%d") if attempt.exam_date else attempt.created_at.strftime("%Y-%m-%d")
            
            progress.append({
                "date": date_str,
                "attempt_number": attempt.attempt_number,
                "exam_name": attempt.exam_name or f"Deneme {attempt.attempt_number}",
                "tyt_total": round(tyt_total, 2),
                "ayt_total": round(ayt_total, 2),
                "total_score": round(attempt.total_score or 0.0, 2),
                # TYT detayları
                "tyt_turkish": round(attempt.tyt_turkish_net or 0.0, 2),
                "tyt_math": round(attempt.tyt_math_net or 0.0, 2),
                "tyt_social": round(attempt.tyt_social_net or 0.0, 2),
                "tyt_science": round(attempt.tyt_science_net or 0.0, 2),
                # AYT detayları
                "ayt_math": round(attempt.ayt_math_net or 0.0, 2),
                "ayt_physics": round(attempt.ayt_physics_net or 0.0, 2),
                "ayt_chemistry": round(attempt.ayt_chemistry_net or 0.0, 2),
                "ayt_biology": round(attempt.ayt_biology_net or 0.0, 2),
                "ayt_literature": round(attempt.ayt_literature_net or 0.0, 2),
                "ayt_history1": round(attempt.ayt_history1_net or 0.0, 2),
                "ayt_geography1": round(attempt.ayt_geography1_net or 0.0, 2),
                "ayt_philosophy": round(attempt.ayt_philosophy_net or 0.0, 2),
                "ayt_history2": round(attempt.ayt_history2_net or 0.0, 2),
                "ayt_geography2": round(attempt.ayt_geography2_net or 0.0, 2),
                "ayt_religion": round(attempt.ayt_religion_net or 0.0, 2),
                "ayt_foreign_language": round(attempt.ayt_foreign_language_net or 0.0, 2),
            })
        
        api_logger.info(f"Retrieved progress for student {student_id}: {len(progress)} attempts")
        
        return {
            "student_id": student_id,
            "progress": progress,
            "total_attempts": len(progress)
        }
        
    except StudentNotFoundError:
        raise
    except Exception as e:
        api_logger.error(f"Error getting student progress: {str(e)}", error=str(e), user_id=student_id)
        raise HTTPException(status_code=500, detail=f"İlerleme verileri getirilemedi: {str(e)}")


@router.get("/summary")
async def get_student_summary(
    student_id: int,
    db: Session = Depends(get_db)
):
    """
    Öğrencinin en iyi ve en kötü derslerini analiz et
    
    Örnek çıktı:
    {
        "best_subjects": ["Matematik", "Fizik"],
        "worst_subjects": ["Tarih", "Coğrafya"],
        "improving_subjects": ["Matematik"],
        "declining_subjects": ["Fizik"],
        "analysis": "Matematik artışta, Fizik düşüşte"
    }
    """
    try:
        # Öğrenci kontrolü
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {student_id}")
        
        # Son 5 denemeyi getir (trend analizi için)
        attempts = db.query(ExamAttempt).filter(
            ExamAttempt.student_id == student_id
        ).order_by(desc(ExamAttempt.created_at)).limit(5).all()
        
        if len(attempts) < 2:
            return {
                "student_id": student_id,
                "message": "Analiz için en az 2 deneme kaydı gerekiyor",
                "best_subjects": [],
                "worst_subjects": [],
                "improving_subjects": [],
                "declining_subjects": [],
                "analysis": "Yeterli veri yok"
            }
        
        # Ders isimleri ve alanları
        subject_names = {
            "tyt_turkish": "TYT Türkçe",
            "tyt_math": "TYT Matematik",
            "tyt_social": "TYT Sosyal",
            "tyt_science": "TYT Fen",
            "ayt_math": "AYT Matematik",
            "ayt_physics": "AYT Fizik",
            "ayt_chemistry": "AYT Kimya",
            "ayt_biology": "AYT Biyoloji",
            "ayt_literature": "AYT Edebiyat",
            "ayt_history1": "AYT Tarih-1",
            "ayt_geography1": "AYT Coğrafya-1",
            "ayt_philosophy": "AYT Felsefe",
            "ayt_history2": "AYT Tarih-2",
            "ayt_geography2": "AYT Coğrafya-2",
            "ayt_religion": "AYT Din Kültürü",
            "ayt_foreign_language": "AYT Yabancı Dil"
        }
        
        # Alan türüne göre aktif dersler
        active_subjects = ["tyt_turkish", "tyt_math", "tyt_social", "tyt_science"]
        if student.field_type == "SAY":
            active_subjects.extend(["ayt_math", "ayt_physics", "ayt_chemistry", "ayt_biology"])
        elif student.field_type == "EA":
            active_subjects.extend(["ayt_math", "ayt_literature", "ayt_history1", "ayt_geography1"])
        elif student.field_type == "SÖZ":
            active_subjects.extend(["ayt_literature", "ayt_history1", "ayt_geography1", "ayt_history2", "ayt_geography2", "ayt_philosophy", "ayt_religion"])
        elif student.field_type == "DİL":
            active_subjects.append("ayt_foreign_language")
        
        # Her ders için ortalama ve trend hesapla
        subject_stats = {}
        for subject in active_subjects:
            values = []
            for attempt in attempts:
                attr_name = subject
                value = getattr(attempt, attr_name, 0.0) or 0.0
                values.append(value)
            
            if values:
                avg = sum(values) / len(values)
                # Trend: Son 2 deneme ortalaması - İlk 2 deneme ortalaması
                if len(values) >= 4:
                    recent_avg = sum(values[:2]) / 2
                    older_avg = sum(values[-2:]) / 2
                    trend = recent_avg - older_avg
                elif len(values) >= 2:
                    trend = values[0] - values[-1]  # Son - İlk
                else:
                    trend = 0.0
                
                subject_stats[subject] = {
                    "name": subject_names.get(subject, subject),
                    "average": round(avg, 2),
                    "trend": round(trend, 2),
                    "latest": round(values[0], 2) if values else 0.0
                }
        
        # En iyi ve en kötü dersler (ortalama nete göre)
        sorted_by_avg = sorted(
            subject_stats.items(),
            key=lambda x: x[1]["average"],
            reverse=True
        )
        
        best_subjects = [stats["name"] for _, stats in sorted_by_avg[:3] if stats["average"] > 0]
        worst_subjects = [stats["name"] for _, stats in sorted_by_avg[-3:] if stats["average"] >= 0]
        
        # Artışta ve düşüşte olan dersler
        improving_subjects = [
            stats["name"] for _, stats in subject_stats.items()
            if stats["trend"] > 2.0  # 2 netten fazla artış
        ]
        declining_subjects = [
            stats["name"] for _, stats in subject_stats.items()
            if stats["trend"] < -2.0  # 2 netten fazla düşüş
        ]
        
        # Analiz metni
        analysis_parts = []
        if improving_subjects:
            analysis_parts.append(f"{', '.join(improving_subjects)} artışta")
        if declining_subjects:
            analysis_parts.append(f"{', '.join(declining_subjects)} düşüşte")
        
        analysis = ". ".join(analysis_parts) if analysis_parts else "Genel olarak stabil bir performans gösteriyorsun."
        
        api_logger.info(f"Generated summary for student {student_id}")
        
        return {
            "student_id": student_id,
            "best_subjects": best_subjects,
            "worst_subjects": worst_subjects,
            "improving_subjects": improving_subjects,
            "declining_subjects": declining_subjects,
            "analysis": analysis,
            "subject_details": {
                subject: stats for subject, stats in subject_stats.items()
            }
        }
        
    except StudentNotFoundError:
        raise
    except Exception as e:
        api_logger.error(f"Error getting student summary: {str(e)}", error=str(e), user_id=student_id)
        raise HTTPException(status_code=500, detail=f"Özet verileri getirilemedi: {str(e)}")

