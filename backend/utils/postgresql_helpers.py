"""
✅ PostgreSQL Uyumlu Veri Temizleme Yardımcı Fonksiyonları

SQLite'tan PostgreSQL'e geçiş sırasında veri tipi uyumsuzluklarını çözmek için
kullanılan yardımcı fonksiyonlar.

PostgreSQL katı tip kontrolü yapar, bu yüzden:
- Boş string'ler -> NULL'a çevrilmeli
- "NA", "N/A", "nan" -> NULL'a çevrilmeli
- String uzunlukları kontrol edilmeli
- Enum değerleri doğrulanmalı
"""

import pandas as pd
import re
from typing import Optional, Union, Any


def is_na_value(value: Any) -> bool:
    """
    ✅ Güvenli NaN/None/Boş değer kontrolü
    
    PostgreSQL için boş string'ler ve özel değerler NULL'a çevrilmeli.
    """
    if value is None:
        return True
    
    # Pandas NaN kontrolü
    try:
        if pd.isna(value):
            return True
    except (TypeError, ValueError):
        pass
    
    # String kontrolü
    if isinstance(value, str):
        value_clean = value.strip().lower()
        # Boş string veya özel değerler
        if not value_clean or value_clean in ['na', 'n/a', 'nan', 'none', 'null', '-', '?', '']:
            return True
    
    return False


def safe_to_int(value: Any, default: Optional[int] = None) -> Optional[int]:
    """
    ✅ Değeri PostgreSQL Integer'a güvenli şekilde çevirir
    
    Args:
        value: Dönüştürülecek değer
        default: Dönüştürme başarısız olursa döndürülecek değer (None = NULL)
    
    Returns:
        int veya None (PostgreSQL NULL)
    """
    if is_na_value(value):
        return default
    
    try:
        # String ise temizle
        if isinstance(value, str):
            value = value.replace(',', '').replace(' ', '').strip()
            # Özel değerleri kontrol et
            if value.lower() in ['na', 'n/a', 'nan', 'none', 'null', '-', '?', '']:
                return default
        
        # Sayıya çevir
        result = int(float(value))  # Float'a çevirip int'e çevir (ondalıklı sayılar için)
        return result if result >= 0 else default  # Negatif değerler genelde hata
    except (ValueError, TypeError, OverflowError):
        return default


def safe_to_float(value: Any, default: Optional[float] = None) -> Optional[float]:
    """
    ✅ Değeri PostgreSQL Float'a güvenli şekilde çevirir
    
    Args:
        value: Dönüştürülecek değer
        default: Dönüştürme başarısız olursa döndürülecek değer (None = NULL)
    
    Returns:
        float veya None (PostgreSQL NULL)
    """
    if is_na_value(value):
        return default
    
    try:
        # String ise temizle
        if isinstance(value, str):
            value = value.replace(',', '.').replace(' ', '').strip()
            # Özel değerleri kontrol et
            if value.lower() in ['na', 'n/a', 'nan', 'none', 'null', '-', '?', '']:
                return default
        
        # Float'a çevir
        result = float(value)
        # NaN veya Infinity kontrolü
        if pd.isna(result) or not pd.isfinite(result):
            return default
        return result
    except (ValueError, TypeError, OverflowError):
        return default


def safe_to_string(value: Any, max_length: Optional[int] = None, default: Optional[str] = None) -> Optional[str]:
    """
    ✅ Değeri PostgreSQL String'e güvenli şekilde çevirir
    
    Args:
        value: Dönüştürülecek değer
        max_length: Maksimum string uzunluğu (PostgreSQL String(n) için)
        default: Dönüştürme başarısız olursa döndürülecek değer (None = NULL)
    
    Returns:
        str veya None (PostgreSQL NULL)
    """
    if is_na_value(value):
        return default
    
    try:
        # String'e çevir
        result = str(value).strip()
        
        # Boş string kontrolü
        if not result:
            return default
        
        # Maksimum uzunluk kontrolü
        if max_length and len(result) > max_length:
            result = result[:max_length]
            # Uyarı log'u (production'da kapatılabilir)
            import logging
            logger = logging.getLogger("api")
            logger.warning(f"⚠️ String truncated to {max_length} chars: {result[:50]}...")
        
        return result
    except (ValueError, TypeError):
        return default


def safe_to_boolean(value: Any, default: Optional[bool] = None) -> Optional[bool]:
    """
    ✅ Değeri PostgreSQL Boolean'a güvenli şekilde çevirir
    
    Args:
        value: Dönüştürülecek değer
        default: Dönüştürme başarısız olursa döndürülecek değer (None = NULL)
    
    Returns:
        bool veya None (PostgreSQL NULL)
    """
    if is_na_value(value):
        return default
    
    # Boolean zaten boolean ise
    if isinstance(value, bool):
        return value
    
    # String kontrolü
    if isinstance(value, str):
        value_lower = value.strip().lower()
        if value_lower in ['true', '1', 'yes', 'evet', 't', 'y']:
            return True
        elif value_lower in ['false', '0', 'no', 'hayır', 'f', 'n']:
            return False
        else:
            return default
    
    # Sayı kontrolü
    try:
        num = int(value)
        return bool(num) if num in [0, 1] else default
    except (ValueError, TypeError):
        return default


def validate_enum_value(value: Any, allowed_values: list[str], default: Optional[str] = None) -> Optional[str]:
    """
    ✅ Enum değerini doğrular (PostgreSQL ENUM veya CHECK constraint için)
    
    Args:
        value: Doğrulanacak değer
        allowed_values: İzin verilen değerler listesi
        default: Geçersiz değer için döndürülecek değer (None = NULL)
    
    Returns:
        str (geçerli enum değeri) veya None
    """
    if is_na_value(value):
        return default
    
    value_str = str(value).strip()
    
    # Case-insensitive karşılaştırma
    for allowed in allowed_values:
        if value_str.lower() == allowed.lower():
            return allowed  # Orijinal case'i koru
    
    # Geçersiz değer
    import logging
    logger = logging.getLogger("api")
    logger.warning(f"⚠️ Invalid enum value '{value_str}', allowed: {allowed_values}, using default: {default}")
    return default


def clean_numeric_for_postgres(value: Any, numeric_type: str = "float", default: Optional[Union[int, float]] = None) -> Optional[Union[int, float]]:
    """
    ✅ PostgreSQL için sayısal değer temizleme (genel fonksiyon)
    
    Args:
        value: Temizlenecek değer
        numeric_type: "int" veya "float"
        default: Varsayılan değer
    
    Returns:
        int, float veya None
    """
    if numeric_type == "int":
        return safe_to_int(value, default)
    else:
        return safe_to_float(value, default)


# ✅ Excel'den okunan veriler için özel temizleme fonksiyonları

def clean_excel_numeric(value: Any, default: Optional[float] = None) -> Optional[float]:
    """
    ✅ Excel'den okunan sayısal değerleri temizle (pandas NaN, virgül, vs.)
    
    Excel'de sayılar bazen string olarak gelir (örn: "1,234.56" veya "1.234,56")
    """
    if is_na_value(value):
        return default
    
    try:
        # Pandas Series/DataFrame değeri ise
        if hasattr(value, 'item'):
            value = value.item()
        
        # String ise temizle
        if isinstance(value, str):
            # Türkçe format: "1.234,56" -> "1234.56"
            if ',' in value and '.' in value:
                # Hangi format olduğunu tespit et
                if value.rindex(',') > value.rindex('.'):
                    # Türkçe format: "1.234,56"
                    value = value.replace('.', '').replace(',', '.')
                else:
                    # İngilizce format: "1,234.56"
                    value = value.replace(',', '')
            elif ',' in value:
                # Sadece virgül varsa (Türkçe ondalık ayracı)
                value = value.replace(',', '.')
            
            value = value.replace(' ', '').strip()
        
        # Float'a çevir
        result = float(value)
        
        # NaN veya Infinity kontrolü
        if pd.isna(result) or not pd.isfinite(result):
            return default
        
        return result
    except (ValueError, TypeError, AttributeError):
        return default


def truncate_string_for_postgres(value: Any, max_length: int, field_name: str = "field") -> Optional[str]:
    """
    ✅ String'i PostgreSQL String(n) için keser ve loglar
    
    Args:
        value: Kesilecek string
        max_length: Maksimum uzunluk
        field_name: Alan adı (log için)
    
    Returns:
        str veya None
    """
    cleaned = safe_to_string(value, max_length=max_length)
    
    if cleaned and len(cleaned) == max_length:
        import logging
        logger = logging.getLogger("api")
        logger.warning(f"⚠️ {field_name} truncated to {max_length} chars: {cleaned[:50]}...")
    
    return cleaned

