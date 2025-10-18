from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.sql import func
from database import Base


class ExamAttempt(Base):
    """Öğrencinin deneme sınavı sonuçları"""
    __tablename__ = "exam_attempts"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey('students.id'), nullable=False)
    
    # Deneme bilgileri
    attempt_number = Column(Integer, nullable=False)  # Kaçıncı deneme
    exam_date = Column(DateTime(timezone=True), nullable=True)
    exam_name = Column(String(100), nullable=True)  # Deneme adı (örn: "TYT Deneme 1")
    
    # TYT Netleri
    tyt_turkish_net = Column(Float, default=0.0)
    tyt_math_net = Column(Float, default=0.0)
    tyt_social_net = Column(Float, default=0.0)
    tyt_science_net = Column(Float, default=0.0)
    
    # AYT Netleri
    ayt_math_net = Column(Float, default=0.0)
    ayt_physics_net = Column(Float, default=0.0)
    ayt_chemistry_net = Column(Float, default=0.0)
    ayt_biology_net = Column(Float, default=0.0)
    ayt_literature_net = Column(Float, default=0.0)
    ayt_history1_net = Column(Float, default=0.0)
    ayt_geography1_net = Column(Float, default=0.0)
    ayt_philosophy_net = Column(Float, default=0.0)
    ayt_history2_net = Column(Float, default=0.0)
    ayt_geography2_net = Column(Float, default=0.0)
    ayt_foreign_language_net = Column(Float, default=0.0)
    
    # Hesaplanan puanlar
    tyt_score = Column(Float, default=0.0)
    ayt_score = Column(Float, default=0.0)
    total_score = Column(Float, default=0.0)
    obp_score = Column(Float, default=0.0, nullable=True)  # ✅ OBP (Opsiyonel)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    def __repr__(self):
        return f"<ExamAttempt(id={self.id}, student_id={self.student_id}, attempt_number={self.attempt_number})>"

