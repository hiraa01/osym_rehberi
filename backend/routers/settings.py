"""
Settings Router - Kullanıcı ayarları yönetimi
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional
import json

from database import get_db
from models import User
from schemas.settings import (
    NotificationPreferencesUpdate,
    NotificationPreferencesResponse,
    UserSettingsResponse,
    PasswordChangeRequest,
    UserProfileUpdate,
)
from core.logging_config import api_logger
from core.security import verify_password, get_password_hash

router = APIRouter()


@router.get("/notifications/{user_id}", response_model=NotificationPreferencesResponse)
async def get_notification_preferences(
    user_id: int,
    db: Session = Depends(get_db)
):
    """Kullanıcının bildirim tercihlerini getir"""
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")

        # Default preferences
        default_prefs = {
            "exam_results": True,
            "ai_recommendations": True,
            "goal_reminders": False,
            "forum_replies": True,
            "trending_topics": False,
            "app_updates": True,
            "email_notifications": False,
        }

        if user.notification_preferences:
            try:
                prefs = json.loads(user.notification_preferences)
                # Default değerlerle birleştir (eksik olanları ekle)
                for key, value in default_prefs.items():
                    if key not in prefs:
                        prefs[key] = value
                return NotificationPreferencesResponse(**prefs)
            except json.JSONDecodeError:
                api_logger.warning(f"Invalid JSON in notification_preferences for user {user_id}")
                return NotificationPreferencesResponse(**default_prefs)
        
        return NotificationPreferencesResponse(**default_prefs)
        
    except HTTPException:
        raise
    except Exception as e:
        api_logger.error(f"Error getting notification preferences: {str(e)}")
        raise HTTPException(status_code=500, detail="Bildirim tercihleri alınırken bir hata oluştu")


@router.put("/notifications/{user_id}", response_model=NotificationPreferencesResponse)
async def update_notification_preferences(
    user_id: int,
    preferences: NotificationPreferencesUpdate,
    db: Session = Depends(get_db)
):
    """Kullanıcının bildirim tercihlerini güncelle"""
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")

        # Mevcut tercihleri al
        current_prefs = {}
        if user.notification_preferences:
            try:
                current_prefs = json.loads(user.notification_preferences)
            except json.JSONDecodeError:
                pass

        # Yeni tercihleri birleştir
        update_data = preferences.dict(exclude_unset=True)
        current_prefs.update(update_data)

        # JSON'a çevir ve kaydet
        user.notification_preferences = json.dumps(current_prefs)
        db.commit()
        db.refresh(user)

        api_logger.info(f"Notification preferences updated for user {user_id}")
        return NotificationPreferencesResponse(**current_prefs)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(f"Error updating notification preferences: {str(e)}")
        raise HTTPException(status_code=500, detail="Bildirim tercihleri güncellenirken bir hata oluştu")


@router.get("/profile/{user_id}", response_model=UserSettingsResponse)
async def get_user_settings(
    user_id: int,
    db: Session = Depends(get_db)
):
    """Kullanıcı ayarlarını getir (profil bilgileri + güvenlik)"""
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")

        return UserSettingsResponse(
            id=user.id,
            email=user.email,
            phone=user.phone,
            name=user.name,
            two_factor_enabled=user.two_factor_enabled,
            biometric_enabled=user.biometric_enabled,
        )
        
    except HTTPException:
        raise
    except Exception as e:
        api_logger.error(f"Error getting user settings: {str(e)}")
        raise HTTPException(status_code=500, detail="Kullanıcı ayarları alınırken bir hata oluştu")


@router.put("/profile/{user_id}", response_model=UserSettingsResponse)
async def update_user_profile(
    user_id: int,
    profile_update: UserProfileUpdate,
    db: Session = Depends(get_db)
):
    """Kullanıcı profil bilgilerini güncelle"""
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")

        # Güncelleme
        update_data = profile_update.dict(exclude_unset=True)
        for key, value in update_data.items():
            setattr(user, key, value)

        db.commit()
        db.refresh(user)

        api_logger.info(f"User profile updated: id={user_id}")
        return UserSettingsResponse(
            id=user.id,
            email=user.email,
            phone=user.phone,
            name=user.name,
            two_factor_enabled=user.two_factor_enabled,
            biometric_enabled=user.biometric_enabled,
        )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(f"Error updating user profile: {str(e)}")
        raise HTTPException(status_code=500, detail="Profil güncellenirken bir hata oluştu")


@router.post("/password/{user_id}")
async def change_password(
    user_id: int,
    password_data: PasswordChangeRequest,
    db: Session = Depends(get_db)
):
    """Kullanıcı şifresini değiştir"""
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")

        # Mevcut şifreyi kontrol et
        if user.password_hash:
            if not verify_password(password_data.current_password, user.password_hash):
                raise HTTPException(status_code=400, detail="Mevcut şifre yanlış")
        else:
            # Şifre yoksa (telefon/email ile giriş), mevcut şifre kontrolü yapma
            pass

        # Yeni şifre doğrulama
        if password_data.new_password != password_data.confirm_password:
            raise HTTPException(status_code=400, detail="Yeni şifreler eşleşmiyor")

        if len(password_data.new_password) < 8:
            raise HTTPException(status_code=400, detail="Şifre en az 8 karakter olmalıdır")

        # Şifreyi hash'le ve kaydet
        user.password_hash = get_password_hash(password_data.new_password)
        db.commit()

        api_logger.info(f"Password changed for user {user_id}")
        return {"message": "Şifre başarıyla değiştirildi"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(f"Error changing password: {str(e)}")
        raise HTTPException(status_code=500, detail="Şifre değiştirilirken bir hata oluştu")


@router.put("/security/{user_id}")
async def update_security_settings(
    user_id: int,
    two_factor_enabled: Optional[bool] = None,
    biometric_enabled: Optional[bool] = None,
    db: Session = Depends(get_db)
):
    """Güvenlik ayarlarını güncelle (2FA, Biometric)"""
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")

        if two_factor_enabled is not None:
            user.two_factor_enabled = two_factor_enabled
        if biometric_enabled is not None:
            user.biometric_enabled = biometric_enabled

        db.commit()
        db.refresh(user)

        api_logger.info(f"Security settings updated for user {user_id}")
        return {
            "two_factor_enabled": user.two_factor_enabled,
            "biometric_enabled": user.biometric_enabled,
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        api_logger.error(f"Error updating security settings: {str(e)}")
        raise HTTPException(status_code=500, detail="Güvenlik ayarları güncellenirken bir hata oluştu")

