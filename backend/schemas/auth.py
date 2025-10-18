from pydantic import BaseModel, EmailStr, validator
from typing import Optional
from datetime import datetime


class UserRegister(BaseModel):
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    name: Optional[str] = None

    @validator('phone', 'email')
    def check_email_or_phone(cls, v, values, **kwargs):
        """En az biri (email veya telefon) dolu olmalı"""
        if not v and not values.get('email') and not values.get('phone'):
            raise ValueError('Email veya telefon numarasından en az biri gereklidir')
        return v


class UserLogin(BaseModel):
    email: Optional[EmailStr] = None
    phone: Optional[str] = None

    @validator('phone', 'email')
    def check_email_or_phone(cls, v, values, **kwargs):
        """En az biri (email veya telefon) dolu olmalı"""
        if not v and not values.get('email') and not values.get('phone'):
            raise ValueError('Email veya telefon numarasından en az biri gereklidir')
        return v


class UserResponse(BaseModel):
    id: int
    email: Optional[str] = None
    phone: Optional[str] = None
    name: Optional[str] = None
    is_active: bool
    is_onboarding_completed: bool
    is_initial_setup_completed: bool
    created_at: datetime
    last_login_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class AuthResponse(BaseModel):
    user: UserResponse
    token: str
    message: str


class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    is_onboarding_completed: Optional[bool] = None
    is_initial_setup_completed: Optional[bool] = None

