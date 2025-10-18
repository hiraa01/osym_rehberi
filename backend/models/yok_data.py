"""
YÖK Atlas Veri Modelleri
2024-2025 YKS Verileri için güncellenmiş modeller
"""
from sqlalchemy import Column, Integer, String, Float, DateTime, Text, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class YokUniversity(Base):
    """YÖK Atlas Üniversite Modeli"""
    __tablename__ = "yok_universities"

    id = Column(Integer, primary_key=True, index=True)
    yok_code = Column(String(20), unique=True, index=True, nullable=False)  # YÖK üniversite kodu
    name = Column(String(200), nullable=False, index=True)
    city = Column(String(50), nullable=False, index=True)
    university_type = Column(String(20), nullable=False)  # DEVLET, VAKIF
    
    # İletişim
    phone = Column(String(20), nullable=True)
    email = Column(String(100), nullable=True)
    website = Column(String(200), nullable=True)
    address = Column(Text, nullable=True)
    
    # Konum
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    # Meta
    established_year = Column(Integer, nullable=True)
    rector = Column(String(100), nullable=True)
    student_count = Column(Integer, nullable=True)
    academic_staff_count = Column(Integer, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # İlişkiler
    programs = relationship("YokProgram", back_populates="university")
    
    def __repr__(self):
        return f"<YokUniversity(id={self.id}, name='{self.name}', type='{self.university_type}')>"


class YokProgram(Base):
    """YÖK Atlas Program (Bölüm) Modeli"""
    __tablename__ = "yok_programs"

    id = Column(Integer, primary_key=True, index=True)
    yok_code = Column(String(20), unique=True, index=True, nullable=False)  # YÖK program kodu
    university_id = Column(Integer, ForeignKey("yok_universities.id"), nullable=False, index=True)
    
    # Program Bilgileri
    program_name = Column(String(300), nullable=False, index=True)
    faculty = Column(String(200), nullable=True)
    field_type = Column(String(20), nullable=False, index=True)  # SAY, EA, SÖZ, DİL
    education_type = Column(String(50), nullable=False)  # Örgün Öğretim, İkinci Öğretim, Uzaktan Öğretim
    language = Column(String(50), default="Türkçe")  # Türkçe, İngilizce, %30 İngilizce, vb.
    
    # Akademik Bilgiler
    duration = Column(Integer, default=4)  # Yıl
    degree_type = Column(String(50), default="Lisans")  # Lisans, Önlisans, YL, DR
    
    # 2024-2025 Kontenjan Bilgileri
    total_quota = Column(Integer, nullable=True)
    general_quota = Column(Integer, nullable=True)
    scholarship_quota = Column(Integer, nullable=True)
    paid_quota = Column(Integer, nullable=True)
    
    # 2024 Yerleşme İstatistikleri
    min_score_2024 = Column(Float, nullable=True, index=True)  # Taban puan
    max_score_2024 = Column(Float, nullable=True)  # Tavan puan
    min_rank_2024 = Column(Integer, nullable=True)  # Taban sıralama
    max_rank_2024 = Column(Integer, nullable=True)  # Tavan sıralama
    placed_students_2024 = Column(Integer, nullable=True)  # Yerleşen sayısı
    
    # 2023 Yerleşme İstatistikleri (karşılaştırma için)
    min_score_2023 = Column(Float, nullable=True)
    max_score_2023 = Column(Float, nullable=True)
    min_rank_2023 = Column(Integer, nullable=True)
    placed_students_2023 = Column(Integer, nullable=True)
    
    # Ücret Bilgileri (Vakıf üniversiteleri için)
    tuition_fee_tl = Column(Float, nullable=True)  # Yıllık ücret (TL)
    has_full_scholarship = Column(Boolean, default=False)  # Tam burs
    has_half_scholarship = Column(Boolean, default=False)  # %50 burs
    has_quarter_scholarship = Column(Boolean, default=False)  # %25 burs
    
    # Özel Koşullar
    special_talent_exam = Column(Boolean, default=False)  # Özel yetenek sınavı var mı
    special_conditions = Column(Text, nullable=True)  # Özel koşullar (JSON)
    
    # Tercih Kodu (YKS tercih kodları)
    preference_code = Column(String(20), unique=True, index=True, nullable=True)
    
    # Aktif mi?
    is_active = Column(Boolean, default=True, index=True)  # 2025'te açık mı
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # İlişkiler
    university = relationship("YokUniversity", back_populates="programs")
    
    def __repr__(self):
        return f"<YokProgram(id={self.id}, name='{self.program_name}', code='{self.yok_code}')>"


class YokCity(Base):
    """Şehir Listesi"""
    __tablename__ = "yok_cities"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, nullable=False, index=True)
    plate_code = Column(String(3), nullable=True)  # Plaka kodu (örn: 34 İstanbul)
    region = Column(String(50), nullable=True)  # Bölge (Marmara, Ege, vb.)
    university_count = Column(Integer, default=0)  # Şehirdeki üniversite sayısı
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    def __repr__(self):
        return f"<YokCity(id={self.id}, name='{self.name}')>"


class ScoreCalculation(Base):
    """Puan Hesaplama Katsayıları (YKS 2025)"""
    __tablename__ = "score_calculations"
    
    id = Column(Integer, primary_key=True, index=True)
    field_type = Column(String(20), nullable=False, unique=True, index=True)  # SAY, EA, SÖZ, DİL
    
    # TYT Katsayıları
    tyt_turkish_coefficient = Column(Float, default=0.0)
    tyt_math_coefficient = Column(Float, default=0.0)
    tyt_social_coefficient = Column(Float, default=0.0)
    tyt_science_coefficient = Column(Float, default=0.0)
    
    # AYT Katsayıları
    ayt_math_coefficient = Column(Float, default=0.0)
    ayt_physics_coefficient = Column(Float, default=0.0)
    ayt_chemistry_coefficient = Column(Float, default=0.0)
    ayt_biology_coefficient = Column(Float, default=0.0)
    ayt_literature_coefficient = Column(Float, default=0.0)
    ayt_history1_coefficient = Column(Float, default=0.0)
    ayt_geography1_coefficient = Column(Float, default=0.0)
    ayt_history2_coefficient = Column(Float, default=0.0)
    ayt_geography2_coefficient = Column(Float, default=0.0)
    ayt_philosophy_coefficient = Column(Float, default=0.0)
    ayt_religion_coefficient = Column(Float, default=0.0)
    ayt_language_coefficient = Column(Float, default=0.0)
    
    # Sabitler
    base_score = Column(Float, default=100.0)  # Taban puan
    max_score = Column(Float, default=560.0)  # Maksimum puan
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    def __repr__(self):
        return f"<ScoreCalculation(field_type='{self.field_type}')>"

