from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
import secrets

from database import get_db
from models import User, Student
from schemas.auth import UserRegister, UserLogin, AuthResponse, UserResponse, UserUpdate
from core.logging_config import api_logger

router = APIRouter()


def generate_token():
    """Basit token üreteci"""
    return secrets.token_urlsafe(32)


@router.post("/register", response_model=AuthResponse)
async def register(user_data: UserRegister, db: Session = Depends(get_db)):
    """
    Yeni kullanıcı kaydı
    
    Gelişmiş hata yönetimi ile veritabanı bağlantı hatalarını yakalar.
    """
    try:
        api_logger.info("User registration attempt", email=user_data.email, phone=user_data.phone)
        
        # ✅ Veritabanı bağlantısını test et
        try:
            from sqlalchemy import text
            db.execute(text("SELECT 1"))  # Basit bağlantı testi
        except Exception as conn_error:
            api_logger.error(f"Database connection error: {str(conn_error)}")
            raise HTTPException(
                status_code=503,
                detail="Veritabanı bağlantısı kurulamadı. Lütfen daha sonra tekrar deneyin."
            )
        
        # Email veya telefon ile kayıt kontrolü
        try:
            if user_data.email:
                existing_user = db.query(User).filter(User.email == user_data.email).first()
                if existing_user:
                    raise HTTPException(status_code=400, detail="Bu email adresi zaten kayıtlı")
            
            if user_data.phone:
                existing_user = db.query(User).filter(User.phone == user_data.phone).first()
                if existing_user:
                    raise HTTPException(status_code=400, detail="Bu telefon numarası zaten kayıtlı")
        except HTTPException:
            raise
        except Exception as query_error:
            api_logger.error(f"Database query error during registration check: {str(query_error)}")
            # Tablo yoksa veya bağlantı hatası varsa
            if "does not exist" in str(query_error).lower() or "relation" in str(query_error).lower():
                raise HTTPException(
                    status_code=503,
                    detail="Veritabanı tabloları hazır değil. Lütfen backend'i yeniden başlatın."
                )
            raise HTTPException(
                status_code=500,
                detail="Kayıt kontrolü sırasında bir hata oluştu"
            )
        
        # Yeni kullanıcı oluştur - Sadeleştirilmiş ve güvenli
        try:
            new_user = User(
                email=user_data.email,
                phone=user_data.phone,
                name=user_data.name,
                is_active=True,
                is_onboarding_completed=False,
                is_initial_setup_completed=False,
                last_login_at=datetime.now()
            )
            
            db.add(new_user)
            db.commit()
            db.refresh(new_user)
            
            # ✅ Student profilini şimdilik oluşturma - Register sırasında gerekli değil
            # Student profili kullanıcı initial setup yaparken oluşturulacak
            # Bu sayede circular import ve model yükleme sorunlarından kaçınıyoruz
            
            # Token oluştur
            token = generate_token()
            
            api_logger.info(f"User registered successfully: user_id={new_user.id}")
            
            return AuthResponse(
                user=new_user,
                token=token,
                message="Kayıt başarılı"
            )
            
        except Exception as create_error:
            db.rollback()
            api_logger.error(f"Error creating user: {str(create_error)}")
            import traceback
            api_logger.error(f"Traceback: {traceback.format_exc()}")
            
            # Tablo yoksa veya bağlantı hatası varsa
            error_str = str(create_error).lower()
            if "does not exist" in error_str or "relation" in error_str or "table" in error_str:
                raise HTTPException(
                    status_code=503,
                    detail="Veritabanı tabloları hazır değil. Lütfen backend'i yeniden başlatın."
                )
            
            raise HTTPException(
                status_code=500,
                detail="Kayıt sırasında bir hata oluştu. Lütfen daha sonra tekrar deneyin."
            )
        
    except HTTPException:
        raise
    except Exception as e:
        # ✅ CRITICAL: Tüm hataları yakala ve logla - sunucu çökmesin
        api_logger.error(f"🔥 KAYIT KRİTİK HATA: {str(e)}")
        import traceback
        api_logger.error(f"🔥 Traceback: {traceback.format_exc()}")
        
        # Rollback yap (eğer transaction varsa)
        try:
            db.rollback()
        except:
            pass
        
        # ✅ Tablo eksikliği kontrolü
        error_str = str(e).lower()
        if any(keyword in error_str for keyword in ["does not exist", "relation", "table", "no such table"]):
            api_logger.error("❌ VERİTABANI TABLOSU EKSİK! Backend'i yeniden başlatın.")
            raise HTTPException(
                status_code=503,
                detail="Veritabanı tabloları hazır değil. Lütfen backend'i yeniden başlatın."
            )
        
        # ✅ Genel hata
        raise HTTPException(
            status_code=500,
            detail=f"Kayıt sırasında beklenmeyen bir hata oluştu: {str(e)}"
        )


@router.post("/login", response_model=AuthResponse)
async def login(user_data: UserLogin, db: Session = Depends(get_db)):
    """Kullanıcı girişi"""
    try:
        api_logger.info("User login attempt", email=user_data.email, phone=user_data.phone)
        
        # Email veya telefon ile kullanıcı bul
        user = None
        if user_data.email:
            user = db.query(User).filter(User.email == user_data.email).first()
        elif user_data.phone:
            user = db.query(User).filter(User.phone == user_data.phone).first()
        
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı. Lütfen kayıt olun.")
        
        if not user.is_active:
            raise HTTPException(status_code=403, detail="Hesabınız aktif değil")
        
        # Son giriş zamanını güncelle
        user.last_login_at = datetime.now()
        db.commit()
        db.refresh(user)
        
        # Token oluştur
        token = generate_token()
        
        api_logger.info("User logged in successfully", user_id=user.id)
        
        return AuthResponse(
            user=user,
            token=token,
            message="Giriş başarılı"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        api_logger.error(f"Error during login: {str(e)}")
        raise HTTPException(status_code=500, detail="Giriş sırasında bir hata oluştu")


@router.get("/me/{user_id}", response_model=UserResponse)
async def get_current_user(user_id: int, db: Session = Depends(get_db)):
    """Kullanıcı bilgilerini getir"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    return user


@router.put("/me/{user_id}", response_model=UserResponse)
async def update_user(user_id: int, user_update: UserUpdate, db: Session = Depends(get_db)):
    """Kullanıcı bilgilerini güncelle"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    
    update_data = user_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)
    
    db.commit()
    db.refresh(user)
    
    return user


@router.get("/student/{user_id}")
async def get_user_student_profile(user_id: int, db: Session = Depends(get_db)):
    """Kullanıcının öğrenci profilini getir"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    
    # Email veya telefon ile öğrenci profilini bul
    student = None
    if user.email:
        student = db.query(Student).filter(Student.email == user.email).first()
    if not student and user.phone:
        student = db.query(Student).filter(Student.phone == user.phone).first()
    
    if not student:
        return {"message": "Öğrenci profili bulunamadı", "student": None}
    
    return {"message": "Öğrenci profili bulundu", "student": student}

