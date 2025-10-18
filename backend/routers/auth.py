from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
import secrets

from database import get_db
from models.user import User
from models.student import Student
from schemas.auth import UserRegister, UserLogin, AuthResponse, UserResponse, UserUpdate
from core.logging_config import api_logger

router = APIRouter()


def generate_token():
    """Basit token üreteci"""
    return secrets.token_urlsafe(32)


@router.post("/register", response_model=AuthResponse)
async def register(user_data: UserRegister, db: Session = Depends(get_db)):
    """Yeni kullanıcı kaydı"""
    try:
        api_logger.info("User registration attempt", email=user_data.email, phone=user_data.phone)
        
        # Email veya telefon ile kayıt kontrolü
        if user_data.email:
            existing_user = db.query(User).filter(User.email == user_data.email).first()
            if existing_user:
                raise HTTPException(status_code=400, detail="Bu email adresi zaten kayıtlı")
        
        if user_data.phone:
            existing_user = db.query(User).filter(User.phone == user_data.phone).first()
            if existing_user:
                raise HTTPException(status_code=400, detail="Bu telefon numarası zaten kayıtlı")
        
        # Yeni kullanıcı oluştur
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
        
        # Token oluştur
        token = generate_token()
        
        api_logger.info("User registered successfully", user_id=new_user.id)
        
        return AuthResponse(
            user=new_user,
            token=token,
            message="Kayıt başarılı"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        api_logger.error(f"Error during registration: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=500, detail="Kayıt sırasında bir hata oluştu")


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

