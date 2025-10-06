from sqlalchemy import Column, Integer, String, Float, DateTime, Text, Boolean
from sqlalchemy.sql import func
from database import Base


class Student(Base):
    __tablename__ = "students"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=True)
    phone = Column(String(20), nullable=True)
    
    # Academic Information
    class_level = Column(String(20), nullable=False)  # 12, mezun, etc.
    exam_type = Column(String(20), nullable=False)  # TYT, AYT, etc.
    field_type = Column(String(20), nullable=False)  # EA, SAY, SÖZ, DİL
    
    # Exam Scores
    tyt_turkish_net = Column(Float, default=0.0)
    tyt_math_net = Column(Float, default=0.0)
    tyt_social_net = Column(Float, default=0.0)
    tyt_science_net = Column(Float, default=0.0)
    
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
    
    # Calculated Scores
    tyt_total_score = Column(Float, default=0.0)
    ayt_total_score = Column(Float, default=0.0)
    total_score = Column(Float, default=0.0)
    rank = Column(Integer, default=0)
    percentile = Column(Float, default=0.0)
    
    # Preferences
    preferred_cities = Column(Text, nullable=True)  # JSON string
    preferred_university_types = Column(Text, nullable=True)  # JSON string
    budget_preference = Column(String(20), nullable=True)  # low, medium, high
    scholarship_preference = Column(Boolean, default=False)
    
    # Interest Areas
    interest_areas = Column(Text, nullable=True)  # JSON string
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    def __repr__(self):
        return f"<Student(id={self.id}, name='{self.name}', exam_type='{self.exam_type}')>"
