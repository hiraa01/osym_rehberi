"""Basit in-memory cache için yardımcı modül"""
from typing import Any, Optional, Dict
from datetime import datetime, timedelta
import threading

# ✅ Thread-safe basit cache implementasyonu
_cache: Dict[str, tuple[Any, datetime]] = {}
_cache_lock = threading.Lock()
_default_ttl = timedelta(minutes=5)  # 5 dakika default TTL


def get_cache(key: str, ttl: Optional[timedelta] = None) -> Optional[Any]:
    """
    Cache'den değer getir.
    
    Args:
        key: Cache anahtarı
        ttl: Time-to-live (None ise default kullanılır)
    
    Returns:
        Cache'deki değer veya None (expired/not found)
    """
    with _cache_lock:
        if key not in _cache:
            return None
        
        value, expiry = _cache[key]
        
        # Expiry kontrolü
        if datetime.now() > expiry:
            del _cache[key]
            return None
        
        return value


def set_cache(key: str, value: Any, ttl: Optional[timedelta] = None) -> None:
    """
    Cache'e değer kaydet.
    
    Args:
        key: Cache anahtarı
        value: Kaydedilecek değer
        ttl: Time-to-live (None ise default kullanılır)
    """
    with _cache_lock:
        if ttl is None:
            ttl = _default_ttl
        expiry = datetime.now() + ttl
        _cache[key] = (value, expiry)


def clear_cache(key: Optional[str] = None) -> None:
    """
    Cache'i temizle.
    
    Args:
        key: Belirli bir key temizlemek için, None ise tüm cache temizlenir
    """
    with _cache_lock:
        if key is None:
            _cache.clear()
        elif key in _cache:
            del _cache[key]


def clear_expired() -> None:
    """Expired cache entry'lerini temizle"""
    with _cache_lock:
        now = datetime.now()
        expired_keys = [key for key, (_, expiry) in _cache.items() if now > expiry]
        for key in expired_keys:
            del _cache[key]

