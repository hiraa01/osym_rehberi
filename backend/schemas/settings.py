"""
Settings Schemas - Kullanıcı ayarları için Pydantic modelleri
"""
from pydantic import BaseModel, EmailStr, Field
from typing import Optional


class NotificationPreferencesUpdate(BaseModel):
    """Bildirim tercihleri güncelleme modeli"""
    exam_results: Optional[bool] = None
    ai_recommendations: Optional[bool] = None
    goal_reminders: Optional[bool] = None
    forum_replies: Optional[bool] = None
    trending_topics: Optional[bool] = None
    app_updates: Optional[bool] = None
    email_notifications: Optional[bool] = None


class NotificationPreferencesResponse(BaseModel):
    """Bildirim tercihleri response modeli"""
    exam_results: bool = True
    ai_recommendations: bool = True
    goal_reminders: bool = False
    forum_replies: bool = True
    trending_topics: bool = False
    app_updates: bool = True
    email_notifications: bool = False

    class Config:
        from_attributes = True


class UserProfileUpdate(BaseModel):
    """Kullanıcı profil güncelleme modeli"""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    email: Optional[EmailStr] = None
    phone: Optional[str] = Field(None, min_length=10, max_length=20)


class UserSettingsResponse(BaseModel):
    """Kullanıcı ayarları response modeli"""
    id: int
    email: Optional[str] = None
    phone: Optional[str] = None
    name: Optional[str] = None
    two_factor_enabled: bool = False
    biometric_enabled: bool = False

    class Config:
        from_attributes = True


class PasswordChangeRequest(BaseModel):
    """Şifre değiştirme request modeli"""
    current_password: Optional[str] = None  # Telefon/email ile giriş yapanlar için opsiyonel
    new_password: str = Field(..., min_length=8, max_length=100)
    confirm_password: str = Field(..., min_length=8, max_length=100)

