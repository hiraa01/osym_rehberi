from sqlalchemy import Column, Integer, String, Float, DateTime, Text, Boolean
from sqlalchemy.sql import func
from database import Base


class University(Base):
    __tablename__ = "universities"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False, index=True)
    city = Column(String(50), nullable=False, index=True)
    university_type = Column(String(20), nullable=False, index=True)  # ✅ Index eklendi - filtreleme için kritik
    website = Column(String(200), nullable=True)
    established_year = Column(Integer, nullable=True)
    
    # Location
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    def __repr__(self):
        return f"<University(id={self.id}, name='{self.name}', city='{self.city}')>"


class Department(Base):
    __tablename__ = "departments"

    id = Column(Integer, primary_key=True, index=True)
    university_id = Column(Integer, nullable=False, index=True)
    name = Column(String(200), nullable=False, index=True)
    field_type = Column(String(20), nullable=False, index=True)  # ✅ Index eklendi - filtreleme için kritik
    language = Column(String(20), default="Turkish")  # Turkish, English
    
    # Academic Information
    faculty = Column(String(100), nullable=True)
    duration = Column(Integer, default=4)  # years
    degree_type = Column(String(20), default="Bachelor")  # Bachelor, Master, PhD
    
    # Admission Requirements
    min_score = Column(Float, nullable=True, index=True)  # ✅ Index eklendi - filtreleme için kritik
    min_rank = Column(Integer, nullable=True)
    quota = Column(Integer, nullable=True)
    scholarship_quota = Column(Integer, default=0)
    
    # Fees
    tuition_fee = Column(Float, nullable=True)
    has_scholarship = Column(Boolean, default=False)
    
    # Statistics
    last_year_min_score = Column(Float, nullable=True)
    last_year_min_rank = Column(Integer, nullable=True)
    last_year_quota = Column(Integer, nullable=True)
    
    # Additional Info
    description = Column(Text, nullable=True)
    requirements = Column(Text, nullable=True)  # JSON string
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    def __repr__(self):
        return f"<Department(id={self.id}, name='{self.name}', university_id={self.university_id})>"


class Recommendation(Base):
    __tablename__ = "recommendations"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, nullable=False, index=True)
    department_id = Column(Integer, nullable=False, index=True)
    
    # Recommendation Scores
    compatibility_score = Column(Float, nullable=False)  # 0-100
    success_probability = Column(Float, nullable=False)  # 0-100
    preference_score = Column(Float, nullable=False)  # 0-100
    final_score = Column(Float, nullable=False)  # weighted average
    
    # Recommendation Details
    recommendation_reason = Column(Text, nullable=True)
    is_safe_choice = Column(Boolean, default=False)
    is_dream_choice = Column(Boolean, default=False)
    is_realistic_choice = Column(Boolean, default=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    def __repr__(self):
        return f"<Recommendation(id={self.id}, student_id={self.student_id}, department_id={self.department_id})>"
