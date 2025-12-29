"""
✅ TÜM VERİTABANI MODELLERİ TEK DOSYADA
Circular import sorununu kesin olarak çözmek için tüm modeller burada toplandı.
"""
from sqlalchemy import Column, Integer, String, Float, DateTime, Text, Boolean, ForeignKey, UniqueConstraint, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


# ============================================================================
# CORE MODELS
# ============================================================================

class User(Base):
    """Kullanıcı modeli"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(100), unique=True, index=True, nullable=True)
    phone = Column(String(20), unique=True, index=True, nullable=True)
    name = Column(String(100), nullable=True)
    
    # Auth status
    # ✅ CRITICAL: PostgreSQL için nullable=False ve default değer zorunlu
    # SQLite'tan gelen NULL değerler için default değer kullanılır
    is_active = Column(Boolean, nullable=False, default=True)
    is_onboarding_completed = Column(Boolean, nullable=False, default=False)
    is_initial_setup_completed = Column(Boolean, nullable=False, default=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login_at = Column(DateTime(timezone=True), nullable=True)
    
    # Notification Preferences (JSON string)
    notification_preferences = Column(Text, nullable=True)  # JSON: {"exam_results": true, "ai_recommendations": true, ...}
    
    # Security Settings
    password_hash = Column(String(255), nullable=True)  # Şifre hash'i (bcrypt)
    two_factor_enabled = Column(Boolean, nullable=False, default=False)  # 2FA aktif mi?
    biometric_enabled = Column(Boolean, nullable=False, default=False)  # Face ID / Fingerprint aktif mi?
    
    # ✅ Relationships - String reference ile circular import'u önle
    student = relationship("Student", back_populates="user", uselist=False)
    
    def __repr__(self):
        return f"<User(id={self.id}, email='{self.email}', phone='{self.phone}')>"


class Student(Base):
    """Öğrenci profili modeli"""
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
    ayt_religion_net = Column(Float, default=0.0)  # Din Kültürü
    ayt_foreign_language_net = Column(Float, default=0.0)
    
    # Calculated Scores
    tyt_total_score = Column(Float, default=0.0)
    ayt_total_score = Column(Float, default=0.0)
    total_score = Column(Float, default=0.0)
    obp_score = Column(Float, default=0.0, nullable=True)  # ✅ OBP (Okul Başarı Puanı) - Opsiyonel
    rank = Column(Integer, default=0)
    percentile = Column(Float, default=0.0)
    
    # Preferences
    preferred_cities = Column(Text, nullable=True)  # JSON string
    preferred_university_types = Column(Text, nullable=True)  # JSON string
    preferred_departments = Column(Text, nullable=True)  # JSON string
    budget_preference = Column(String(20), nullable=True)  # low, medium, high
    scholarship_preference = Column(Boolean, default=False)
    
    # Interest Areas
    interest_areas = Column(Text, nullable=True)  # JSON string
    
    # Profile Information
    avatar_url = Column(String(500), nullable=True)  # Profil fotoğrafı URL'i
    bio = Column(Text, nullable=True)  # Kısa biyografi
    target_university = Column(String(200), nullable=True)  # Hedeflenen üniversite
    target_department_id = Column(Integer, ForeignKey("departments.id"), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # ✅ Relationships - String reference kullanarak circular import'u önle
    # User ilişkisi
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    user = relationship("User", back_populates="student")
    
    # Yeni Modüller - String reference ile
    preferences = relationship("Preference", back_populates="student", cascade="all, delete-orphan")
    forum_posts = relationship("ForumPost", back_populates="student", cascade="all, delete-orphan")
    forum_comments = relationship("ForumComment", back_populates="student", cascade="all, delete-orphan")
    exam_attempts = relationship("ExamAttempt", back_populates="student", cascade="all, delete-orphan")
    swipes = relationship("Swipe", back_populates="student", cascade="all, delete-orphan")
    agenda_items = relationship("AgendaItem", back_populates="student", cascade="all, delete-orphan")
    study_sessions = relationship("StudySession", back_populates="student", cascade="all, delete-orphan")
    chat_messages = relationship("ChatMessage", back_populates="student", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Student(id={self.id}, name='{self.name}', exam_type='{self.exam_type}')>"


class ExamAttempt(Base):
    """Öğrencinin deneme sınavı sonuçları"""
    __tablename__ = "exam_attempts"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey('students.id'), nullable=False, index=True)  # ✅ Index eklendi - performans için kritik
    
    # Deneme bilgileri
    attempt_number = Column(Integer, nullable=False, index=True)  # Kaçıncı deneme - index eklendi
    
    # ✅ Composite index: student_id + attempt_number (sıralama için kritik)
    __table_args__ = (
        Index('ix_exam_attempts_student_attempt', 'student_id', 'attempt_number'),
    )
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
    ayt_religion_net = Column(Float, default=0.0)  # Din Kültürü
    ayt_foreign_language_net = Column(Float, default=0.0)
    
    # Hesaplanan puanlar
    tyt_score = Column(Float, default=0.0)
    ayt_score = Column(Float, default=0.0)
    total_score = Column(Float, default=0.0)
    obp_score = Column(Float, default=0.0, nullable=True)  # ✅ OBP (Opsiyonel)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # ✅ Relationships - String reference ile circular import'u önle
    student = relationship("Student", back_populates="exam_attempts")
    
    def __repr__(self):
        return f"<ExamAttempt(id={self.id}, student_id={self.student_id}, attempt_number={self.attempt_number})>"


# ============================================================================
# UNIVERSITY MODELS
# ============================================================================

class University(Base):
    """Üniversite modeli"""
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
    """Bölüm modeli"""
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
    has_scholarship = Column(Boolean, nullable=False, default=False)  # ✅ PostgreSQL için nullable=False
    
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
    preferences = relationship("Preference", back_populates="department")
    swipes = relationship("Swipe", back_populates="department")
    
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
    """Tercih önerileri modeli"""
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
    is_safe_choice = Column(Boolean, nullable=False, default=False)  # ✅ PostgreSQL için nullable=False
    is_dream_choice = Column(Boolean, nullable=False, default=False)  # ✅ PostgreSQL için nullable=False
    is_realistic_choice = Column(Boolean, nullable=False, default=False)  # ✅ PostgreSQL için nullable=False
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    def __repr__(self):
        return f"<Recommendation(id={self.id}, student_id={self.student_id}, department_id={self.department_id})>"


# ============================================================================
# PREFERENCE & SWIPE MODELS
# ============================================================================

class Preference(Base):
    """Öğrencinin beğendiği bölümleri kaydeden tablo"""
    __tablename__ = "preferences"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    department_id = Column(Integer, ForeignKey("departments.id"), nullable=False, index=True)
    order = Column(Integer, nullable=True)  # Tercih sırası (opsiyonel)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # ✅ Relationships - String reference ile circular import'u önle
    student = relationship("Student", back_populates="preferences")
    department = relationship("Department", back_populates="preferences")
    
    # Unique constraint: Aynı öğrenci aynı bölümü birden fazla kez ekleyemez
    __table_args__ = (UniqueConstraint('student_id', 'department_id', name='uq_student_department'),)
    
    def __repr__(self):
        return f"<Preference(id={self.id}, student_id={self.student_id}, department_id={self.department_id}, order={self.order})>"


class Swipe(Base):
    """Kullanıcının bölümlere yaptığı swipe işlemleri (like/dislike)"""
    __tablename__ = "swipes"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    department_id = Column(Integer, ForeignKey("departments.id"), nullable=False, index=True)
    action = Column(String(20), nullable=False)  # 'like' or 'dislike'
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # ✅ Relationships - String reference ile circular import'u önle
    student = relationship("Student", back_populates="swipes")
    department = relationship("Department", back_populates="swipes")
    
    # Unique constraint: Aynı öğrenci aynı bölümü birden fazla kez swipe edemez
    __table_args__ = (UniqueConstraint('student_id', 'department_id', name='uq_student_department_swipe'),)
    
    def __repr__(self):
        return f"<Swipe(id={self.id}, student_id={self.student_id}, department_id={self.department_id}, action='{self.action}')>"


# ============================================================================
# FORUM MODELS
# ============================================================================

class ForumPost(Base):
    """Forum gönderileri (sorular)"""
    __tablename__ = "forum_posts"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    category = Column(String(50), nullable=False, index=True)  # TYT, AYT, Rehberlik
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # ✅ Relationships - String reference ile circular import'u önle
    student = relationship("Student", back_populates="forum_posts")
    comments = relationship("ForumComment", back_populates="post", cascade="all, delete-orphan")
    
    # Indexes
    __table_args__ = (
        Index('ix_forum_posts_category_created', 'category', 'created_at'),
    )
    
    def __repr__(self):
        return f"<ForumPost(id={self.id}, title='{self.title[:30]}...', category='{self.category}')>"


class ForumComment(Base):
    """Forum gönderilerine yapılan yorumlar"""
    __tablename__ = "forum_comments"

    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("forum_posts.id"), nullable=False, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    content = Column(Text, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # ✅ Relationships - String reference ile circular import'u önle
    post = relationship("ForumPost", back_populates="comments")
    student = relationship("Student", back_populates="forum_comments")
    
    def __repr__(self):
        return f"<ForumComment(id={self.id}, post_id={self.post_id}, student_id={self.student_id})>"


# ============================================================================
# YOK DATA MODELS (Optional)
# ============================================================================

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


# ============================================================================
# AGENDA & STUDY MODELS
# ============================================================================

class AgendaItem(Base):
    """Ajanda öğeleri (görevler, hatırlatıcılar)"""
    __tablename__ = "agenda_items"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    due_date = Column(DateTime(timezone=True), nullable=True)
    is_completed = Column(Boolean, default=False, index=True)
    priority = Column(String(20), default="medium")  # low, medium, high
    category = Column(String(50), nullable=True)  # Ders, Sınav, Ödev, vb.
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # ✅ Relationships - String reference ile circular import'u önle
    student = relationship("Student", back_populates="agenda_items")
    
    # Indexes
    __table_args__ = (
        Index('ix_agenda_items_student_due_date', 'student_id', 'due_date'),
    )
    
    def __repr__(self):
        return f"<AgendaItem(id={self.id}, title='{self.title[:30]}...', student_id={self.student_id})>"


class StudySession(Base):
    """Ders çalışma oturumları"""
    __tablename__ = "study_sessions"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    subject = Column(String(100), nullable=False)  # Matematik, Fizik, vb.
    duration_minutes = Column(Integer, nullable=False, default=0)
    date = Column(DateTime(timezone=True), nullable=False, index=True)
    notes = Column(Text, nullable=True)
    efficiency_score = Column(Float, nullable=True)  # 0-100 arası verimlilik puanı
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # ✅ Relationships - String reference ile circular import'u önle
    student = relationship("Student", back_populates="study_sessions")
    
    # Indexes
    __table_args__ = (
        Index('ix_study_sessions_student_date', 'student_id', 'date'),
    )
    
    def __repr__(self):
        return f"<StudySession(id={self.id}, subject='{self.subject}', student_id={self.student_id}, duration={self.duration_minutes}min)>"


# ============================================================================
# CHAT MODELS
# ============================================================================

class ChatMessage(Base):
    """Chatbot mesajları"""
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    message = Column(Text, nullable=False)
    reply = Column(Text, nullable=True)  # Bot'un cevabı
    intent = Column(String(50), nullable=True)  # Mesaj amacı (hesapla, öneri, vb.)
    is_from_bot = Column(Boolean, default=False)  # Bot'tan mı, kullanıcıdan mı
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # ✅ Relationships - String reference ile circular import'u önle
    student = relationship("Student", back_populates="chat_messages")
    
    # Indexes
    __table_args__ = (
        Index('ix_chat_messages_student_created', 'student_id', 'created_at'),
    )
    
    def __repr__(self):
        return f"<ChatMessage(id={self.id}, student_id={self.student_id}, is_from_bot={self.is_from_bot})>"

