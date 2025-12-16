from sqlalchemy import Column, Integer, String, Float, DateTime, Text, Boolean, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
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
    
    # ✅ OPTIMIZED: Relationship tanımlandı - eager loading için
    departments = relationship("Department", back_populates="university", lazy="selectin")
    
    def __repr__(self):
        return f"<University(id={self.id}, name='{self.name}', city='{self.city}')>"


class Department(Base):
    __tablename__ = "departments"

    id = Column(Integer, primary_key=True, index=True)
    university_id = Column(Integer, ForeignKey("universities.id"), nullable=False, index=True)  # ✅ ForeignKey eklendi
    name = Column(String(200), nullable=False, index=True)  # Orijinal isim (tam isim)
    normalized_name = Column(String(200), nullable=True, index=True)  # ✅ Normalize edilmiş isim (parantez içi detaylar çıkarılmış)
    attributes = Column(Text, nullable=True)  # ✅ JSON string: ["İngilizce", "%50 İndirimli", "Burslu"] gibi
    field_type = Column(String(20), nullable=False, index=True)  # ✅ Index eklendi - filtreleme için kritik
    language = Column(String(20), default="Turkish")  # Turkish, English
    
    # Academic Information
    faculty = Column(String(100), nullable=True)
    duration = Column(Integer, default=4)  # years
    degree_type = Column(String(20), default="Bachelor")  # Bachelor, Master, PhD
    
    # Admission Requirements (en güncel yıl için)
    min_score = Column(Float, nullable=True, index=True)  # ✅ Index eklendi - filtreleme için kritik
    min_rank = Column(Integer, nullable=True)
    quota = Column(Integer, nullable=True)
    scholarship_quota = Column(Integer, default=0)
    
    # Fees
    tuition_fee = Column(Float, nullable=True)
    has_scholarship = Column(Boolean, default=False)
    
    # Statistics (en güncel yıl için - backward compatibility)
    last_year_min_score = Column(Float, nullable=True)
    last_year_min_rank = Column(Integer, nullable=True)
    last_year_quota = Column(Integer, nullable=True)
    
    # Additional Info
    description = Column(Text, nullable=True)
    requirements = Column(Text, nullable=True)  # JSON string
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # ✅ OPTIMIZED: Relationship tanımlandı - eager loading için
    university = relationship("University", back_populates="departments")
    yearly_stats = relationship("DepartmentYearlyStats", back_populates="department", cascade="all, delete-orphan")  # ✅ Tarihsel veriler
    
    def __repr__(self):
        return f"<Department(id={self.id}, name='{self.name}', normalized_name='{self.normalized_name}', university_id={self.university_id})>"


class DepartmentYearlyStats(Base):
    """✅ Bölümlerin yıllara göre istatistikleri (2022-2025)"""
    __tablename__ = "department_yearly_stats"
    
    id = Column(Integer, primary_key=True, index=True)
    department_id = Column(Integer, ForeignKey("departments.id"), nullable=False, index=True)
    year = Column(Integer, nullable=False, index=True)  # 2022, 2023, 2024, 2025
    
    # Yerleşme İstatistikleri
    min_score = Column(Float, nullable=True)  # Taban puan
    max_score = Column(Float, nullable=True)  # Tavan puan
    min_rank = Column(Integer, nullable=True)  # Taban sıralama
    max_rank = Column(Integer, nullable=True)  # Tavan sıralama
    quota = Column(Integer, nullable=True)  # Kontenjan
    placed_students = Column(Integer, nullable=True)  # Yerleşen öğrenci sayısı
    
    # Net Ortalamaları (TYT/AYT net ortalamaları - opsiyonel)
    avg_tyt_turkish_net = Column(Float, nullable=True)
    avg_tyt_math_net = Column(Float, nullable=True)
    avg_tyt_social_net = Column(Float, nullable=True)
    avg_tyt_science_net = Column(Float, nullable=True)
    avg_ayt_math_net = Column(Float, nullable=True)
    avg_ayt_physics_net = Column(Float, nullable=True)
    avg_ayt_chemistry_net = Column(Float, nullable=True)
    avg_ayt_biology_net = Column(Float, nullable=True)
    avg_ayt_literature_net = Column(Float, nullable=True)
    avg_ayt_history1_net = Column(Float, nullable=True)
    avg_ayt_geography1_net = Column(Float, nullable=True)
    avg_ayt_philosophy_net = Column(Float, nullable=True)
    avg_ayt_history2_net = Column(Float, nullable=True)
    avg_ayt_geography2_net = Column(Float, nullable=True)
    avg_ayt_religion_net = Column(Float, nullable=True)
    avg_ayt_foreign_language_net = Column(Float, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # ✅ Unique constraint: Aynı bölüm için aynı yıl sadece bir kez olabilir
    __table_args__ = (UniqueConstraint('department_id', 'year', name='uq_department_year'),)
    
    # İlişkiler
    department = relationship("Department", back_populates="yearly_stats")
    
    def __repr__(self):
        return f"<DepartmentYearlyStats(id={self.id}, department_id={self.department_id}, year={self.year}, min_score={self.min_score})>"


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
