"""
Study Session Router - Ders çalışma oturumları yönetimi
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from typing import List, Optional
from datetime import datetime, timedelta

from database import get_db
from models import StudySession, Student
from schemas.study import (
    StudySessionCreate, StudySessionUpdate, StudySessionResponse,
    StudySessionListResponse, StudyStatsResponse
)
from core.logging_config import api_logger
from core.exceptions import StudentNotFoundError

router = APIRouter()


@router.get("", response_model=StudySessionListResponse)
async def get_study_sessions(
    student_id: int = Query(..., description="Öğrenci ID"),
    page: int = Query(1, ge=1, description="Sayfa numarası"),
    size: int = Query(20, ge=1, le=100, description="Sayfa başına kayıt sayısı"),
    subject: Optional[str] = Query(None, description="Ders filtresi"),
    start_date: Optional[datetime] = Query(None, description="Başlangıç tarihi"),
    end_date: Optional[datetime] = Query(None, description="Bitiş tarihi"),
    db: Session = Depends(get_db)
):
    """
    Öğrencinin ders çalışma oturumlarını listele (Sayfalama ile)
    """
    try:
        # Öğrenci var mı kontrol et
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {student_id}")

        # Base query
        query = db.query(StudySession).filter(StudySession.student_id == student_id)

        # Filtreler
        if subject:
            query = query.filter(StudySession.subject == subject)
        if start_date:
            query = query.filter(StudySession.date >= start_date)
        if end_date:
            query = query.filter(StudySession.date <= end_date)

        # Toplam sayı
        total = query.count()

        # Sayfalama
        skip = (page - 1) * size
        sessions = query.order_by(desc(StudySession.date)).offset(skip).limit(size).all()

        return StudySessionListResponse(
            sessions=[StudySessionResponse.from_orm(session) for session in sessions],
            total=total,
            page=page,
            size=size
        )
    except StudentNotFoundError:
        raise
    except Exception as e:
        api_logger.error(f"Error getting study sessions: {str(e)}")
        raise HTTPException(status_code=500, detail="Ders çalışma oturumları alınırken bir hata oluştu")


@router.post("", response_model=StudySessionResponse)
async def create_study_session(
    session: StudySessionCreate,
    db: Session = Depends(get_db)
):
    """
    Yeni ders çalışma oturumu oluştur
    """
    try:
        # Öğrenci var mı kontrol et
        student = db.query(Student).filter(Student.id == session.student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {session.student_id}")

        # Yeni oturum oluştur
        new_session = StudySession(
            student_id=session.student_id,
            subject=session.subject,
            duration_minutes=session.duration_minutes,
            date=session.date,
            notes=session.notes,
            efficiency_score=session.efficiency_score
        )

        db.add(new_session)
        db.commit()
        db.refresh(new_session)

        api_logger.info(f"Study session created: id={new_session.id}, student_id={session.student_id}")
        return StudySessionResponse.from_orm(new_session)
    except StudentNotFoundError:
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(f"Error creating study session: {str(e)}")
        raise HTTPException(status_code=500, detail="Ders çalışma oturumu oluşturulurken bir hata oluştu")


@router.get("/stats", response_model=StudyStatsResponse)
async def get_study_stats(
    student_id: int = Query(..., description="Öğrenci ID"),
    days: int = Query(30, ge=1, le=365, description="Son kaç günün istatistikleri"),
    db: Session = Depends(get_db)
):
    """
    Öğrencinin ders çalışma istatistiklerini getir
    """
    try:
        # Öğrenci var mı kontrol et
        student = db.query(Student).filter(Student.id == student_id).first()
        if not student:
            raise StudentNotFoundError(f"Öğrenci bulunamadı: {student_id}")

        # Tarih aralığı
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)

        # Oturumları getir
        sessions = db.query(StudySession).filter(
            StudySession.student_id == student_id,
            StudySession.date >= start_date,
            StudySession.date <= end_date
        ).all()

        # İstatistikleri hesapla
        total_sessions = len(sessions)
        total_minutes = sum(s.duration_minutes for s in sessions)
        total_hours = total_minutes / 60.0
        average_duration = total_minutes / total_sessions if total_sessions > 0 else 0.0

        # Ders bazında toplam dakika
        subjects = {}
        for session in sessions:
            if session.subject not in subjects:
                subjects[session.subject] = 0
            subjects[session.subject] += session.duration_minutes

        # Haftalık istatistikler
        weekly_stats = []
        current_date = start_date
        while current_date <= end_date:
            day_sessions = [s for s in sessions if s.date.date() == current_date.date()]
            day_minutes = sum(s.duration_minutes for s in day_sessions)
            weekly_stats.append({
                "date": current_date.strftime("%Y-%m-%d"),
                "minutes": day_minutes
            })
            current_date += timedelta(days=1)

        # Verimlilik ortalaması
        efficiency_scores = [s.efficiency_score for s in sessions if s.efficiency_score is not None]
        efficiency_average = sum(efficiency_scores) / len(efficiency_scores) if efficiency_scores else None

        return StudyStatsResponse(
            total_sessions=total_sessions,
            total_minutes=total_minutes,
            total_hours=round(total_hours, 2),
            average_duration_minutes=round(average_duration, 2),
            subjects=subjects,
            weekly_stats=weekly_stats,
            efficiency_average=round(efficiency_average, 2) if efficiency_average else None
        )
    except StudentNotFoundError:
        raise
    except Exception as e:
        api_logger.error(f"Error getting study stats: {str(e)}")
        raise HTTPException(status_code=500, detail="Ders çalışma istatistikleri alınırken bir hata oluştu")

