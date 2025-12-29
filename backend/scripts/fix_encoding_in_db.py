"""
✅ Veritabanındaki Bozuk Encoding'leri Düzelt Scripti

Bu script, veritabanındaki mevcut bozuk karakterleri (mojibake) düzeltir.
Özellikle University ve Department tablolarındaki name ve city alanlarını temizler.

KULLANIM:
    docker exec -it osym_rehberi_backend python scripts/fix_encoding_in_db.py
"""

import sys
import os
import re
from typing import Optional

sys.path.append('/app' if os.path.exists('/app') else os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import SessionLocal
from models import University, Department

# ✅ Renkli terminal çıktısı için ANSI kodları
class Colors:
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    OKCYAN = '\033[96m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_success(text: str):
    print(f"{Colors.OKGREEN}✅ {text}{Colors.ENDC}")

def print_warning(text: str):
    print(f"{Colors.WARNING}⚠️  {text}{Colors.ENDC}")

def print_error(text: str):
    print(f"{Colors.FAIL}❌ {text}{Colors.ENDC}")

def print_info(text: str):
    print(f"{Colors.OKCYAN}ℹ️  {text}{Colors.ENDC}")


def fix_encoding_text(text: str) -> Optional[str]:
    """
    ✅ HARDOCRE Mojibake (bozuk karakter) düzeltme fonksiyonu
    """
    if not text:
        return None
    
    text = str(text)
    
    if not text.strip():
        return None
    
    # ✅ Yaygın mojibake hatalarını manuel düzelt (SIRALAMA ÖNEMLİ - uzun pattern'ler önce)
    replacements = [
        # Özel durumlar (önce bunlar - çünkü uzun pattern'ler)
        ('GÃL', 'GÜL'),
        ('KayseriÌ', 'Kayseri'),
        ('KayseriÃ', 'Kayseri'),
        ('ÃNÄ°VERSÄ°TESÄ°', 'ÜNİVERSİTESİ'),
        ('ÃNÄ°VERSÄ°TE', 'ÜNİVERSİTE'),
        # Küçük harfler
        ('Ã¼', 'ü'), ('Ã§', 'ç'), ('Ä±', 'ı'), ('Ä°', 'İ'),
        ('Ã¶', 'ö'), ('ÅŸ', 'ş'), ('ÄŸ', 'ğ'),
        # Büyük harfler
        ('Ã‡', 'Ç'), ('Åž', 'Ş'), ('Ã–', 'Ö'), ('Ãœ', 'Ü'),
        ('Ã—', 'Ö'), ('Ã°', 'ğ'), ('Ã¨', 'ğ'),
        # Gereksiz artık karakterleri sil (son sırada)
        ('Ì', ''), ('Î', ''), ('Â', ''), 
        # Genel bozuk karakterler (en son - genel pattern)
        ('Ã', 'ı'),  # Genel bozuk karakter
    ]
    
    for bad, good in replacements:
        text = text.replace(bad, good)
    
    # ✅ Ekstra temizleme: Artık karakterleri regex ile temizle
    text = re.sub(r'[ÌÎÂÃ]', '', text)  # Artık karakterleri sil
    
    # ✅ Satır sonu karakterlerini ve gereksiz boşlukları temizle
    text = text.replace('\n', ' ').replace('\r', ' ').replace('\t', ' ')
    text = ' '.join(text.split())  # Çoklu boşlukları tek boşluğa çevir
    
    return text.strip() if text.strip() else None


def main():
    """✅ Ana fonksiyon - Veritabanındaki bozuk encoding'leri düzelt"""
    print(f"\n{Colors.BOLD}🔧 VERİTABANI ENCODING DÜZELTME{Colors.ENDC}\n")
    
    db = SessionLocal()
    
    try:
        # ✅ 1. University tablosunu düzelt
        print_info("University tablosu düzeltiliyor...")
        universities = db.query(University).all()
        fixed_unis = 0
        
        for uni in universities:
            original_name = uni.name
            original_city = uni.city
            
            fixed_name = fix_encoding_text(original_name) or original_name
            fixed_city = fix_encoding_text(original_city) or original_city
            
            # Şehir adındaki artık karakterleri temizle
            if fixed_city:
                fixed_city = re.sub(r'[ÌÎÂÃ]', '', fixed_city).strip()
                fixed_city = fix_encoding_text(fixed_city) or fixed_city
            
            if fixed_name != original_name or fixed_city != original_city:
                uni.name = fixed_name
                uni.city = fixed_city
                fixed_unis += 1
                print_info(f"   Düzeltildi: {original_name} → {fixed_name}")
                print_info(f"              {original_city} → {fixed_city}")
        
        # ✅ 2. Department tablosunu düzelt
        print_info("\nDepartment tablosu düzeltiliyor...")
        departments = db.query(Department).all()
        fixed_depts = 0
        
        for dept in departments:
            original_name = dept.name
            original_faculty = dept.faculty
            
            fixed_name = fix_encoding_text(original_name) or original_name
            fixed_faculty = fix_encoding_text(original_faculty) if original_faculty else None
            
            if fixed_name != original_name or (fixed_faculty and fixed_faculty != original_faculty):
                dept.name = fixed_name
                dept.normalized_name = fixed_name  # Normalize edilmiş ismi de güncelle
                if fixed_faculty:
                    dept.faculty = fixed_faculty
                fixed_depts += 1
        
        # ✅ Commit
        db.commit()
        
        print_success(f"\n✅ {fixed_unis} üniversite düzeltildi")
        print_success(f"✅ {fixed_depts} bölüm düzeltildi")
        print_success("\n✅ Veritabanı encoding düzeltmesi tamamlandı!")
        
        return 0
        
    except Exception as e:
        print_error(f"❌ HATA: {e}")
        import traceback
        print_error(traceback.format_exc())
        db.rollback()
        return 1
    finally:
        db.close()


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)

