"""
Security utilities - Şifre hash ve doğrulama
"""
from passlib.context import CryptContext
from typing import Optional

# Passlib context - bcrypt kullan
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def get_password_hash(password: str) -> str:
    """Şifreyi bcrypt ile hash'le"""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Şifreyi doğrula"""
    try:
        return pwd_context.verify(plain_password, hashed_password)
    except Exception:
        return False

