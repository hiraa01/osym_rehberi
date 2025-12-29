"""
✅ ÖSYM 2025 Kılavuz Verilerini İçe Aktar Scripti (YENİLENMİŞ)

Bu script, ÖSYM'nin 2025 kılavuz verilerini (CSV/Excel formatında) veritabanına aktarır.
ÖSYM formatında üniversite ve fakülte adları başlık satırı olarak gelir,
bölümler ise ID ile başlayan satırlardır.

✅ HARDOCRE ENCODING FIX: Mojibake (bozuk karakter) düzeltmeleri ile
Türkçe karakterler doğru şekilde kaydedilir.

KULLANIM:
    # Docker container içinde:
    docker exec -it osym_rehberi_backend python scripts/import_2025_data.py
    
    # Veya local'de:
    python scripts/import_2025_data.py
"""

import sys
import os
import re
from pathlib import Path
from typing import Optional, Tuple
from datetime import datetime

sys.path.append('/app' if os.path.exists('/app') else os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pandas as pd
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError, DataError
from sqlalchemy import text
from database import SessionLocal
from models import University, Department, DepartmentYearlyStats
from utils.postgresql_helpers import (
    safe_to_int, safe_to_float,
    truncate_string_for_postgres, validate_enum_value
)

# ✅ Veri dosyalarının bulunduğu klasör
PROGRAMS_DIR = Path('/app/data/programs')

# ✅ Renkli terminal çıktısı için ANSI kodları
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
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

def print_section(text: str):
    print(f"\n{Colors.BOLD}{Colors.OKBLUE}{'─' * 70}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.OKBLUE}{text}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.OKBLUE}{'─' * 70}{Colors.ENDC}\n")


# ============================================================================
# HARDOCRE MOJIBAKE TEMİZLEYİCİ
# ============================================================================

def clean_text(text) -> Optional[str]:
    """
    ✅ Manuel Düzeltme Fonksiyonu - Mojibake (bozuk karakter) düzeltmeleri
    
    Encoding ne olursa olsun, metin içinde bozuk karakter kalırsa diye
    yaygın mojibake hatalarını düzelten bir harita kullanır.
    Her string alımında (Üniversite adı, şehir, fakülte) bu fonksiyon uygulanmalı.
    
    Args:
        text: Temizlenecek metin (herhangi bir tip olabilir)
    
    Returns:
        Optional[str]: Temizlenmiş metin veya None
    """
    if not text or pd.isna(text):
        return None
    
    text = str(text)
    
    if not text.strip():
        return None
    
    # ✅ Yaygın mojibake hatalarını düzelt
    corrections = {
        # Özel durumlar (önce bunlar - çünkü uzun pattern'ler)
        'GÃL': 'GÜL',
        'KayseriÌ': 'Kayseri',
        'Kayseri??': 'Kayseri',
        'KayseriÃ': 'Kayseri',
        'ÃNÄ°VERSÄ°TESÄ°': 'ÜNİVERSİTESİ',
        'ÃNÄ°VERSÄ°TE': 'ÜNİVERSİTE',
        # Küçük harfler (UTF-8 bozulmaları)
        'Ã¼': 'ü', 'Ã§': 'ç', 'Ä±': 'ı', 'Ä°': 'İ',
        'Ã¶': 'ö', 'ÅŸ': 'ş', 'ÄŸ': 'ğ',
        # Büyük harfler (UTF-8 bozulmaları)
        'Ã‡': 'Ç', 'Åž': 'Ş', 'Ã–': 'Ö', 'Ãœ': 'Ü',
        'Ã—': 'Ö', 'Ã°': 'ğ', 'Ã¨': 'ğ', 'Ã': 'Ğ',
        # Soru işaretleri (veri kaybı ama temizle)
        '??': '',  # Soru işaretlerini sil
    }
    
    # ✅ Önce uzun pattern'leri, sonra kısa pattern'leri uygula
    for bad, good in sorted(corrections.items(), key=lambda x: -len(x[0])):
        text = text.replace(bad, good)
    
    # ✅ Artık karakterleri regex ile temizle
    text = re.sub(r'[ÌÎÂ]', '', text)  # Artık karakterleri sil
    
    # ✅ Satır sonu karakterlerini ve gereksiz boşlukları temizle
    text = text.replace('\n', ' ').replace('\r', ' ').replace('\t', ' ')
    text = ' '.join(text.split())  # Çoklu boşlukları tek boşluğa çevir
    
    return text.strip() if text.strip() else None


def fix_encoding_text(text) -> Optional[str]:
    """
    ✅ Alias for clean_text (geriye dönük uyumluluk için)
    """
    return clean_text(text)


def clean_special_values(value) -> Optional[str]:
    """
    ✅ ÖSYM verilerindeki özel karakterleri temizle ve NULL'a çevir
    
    "Dolmadı", "...", "-", "N/A" gibi değerleri None (PostgreSQL NULL) olarak döndür
    """
    cleaned = clean_text(value)  # ✅ Önce encoding düzeltmesi
    
    if not cleaned:
        return None
    
    # Özel değerler listesi
    null_values = [
        "DOLMADI", "DOLMADı", "Dolmadı", "dolmadı",
        "...", "---", "-", "N/A", "NA", "NULL", "NONE",
        "YOK", "Yok", "yok", "BELİRTİLMEMİŞ", "Belirtilmemiş"
    ]
    
    if cleaned.upper() in null_values:
        return None
    
    return cleaned


def clean_score(value) -> Optional[float]:
    """
    ✅ Puan değerini temizle ve float'a çevir
    
    Virgül ve nokta ondalık ayırıcılarını destekler
    """
    cleaned = clean_special_values(value)
    if cleaned is None:
        return None
    
    # Virgülü noktaya çevir (Türkçe format: 123,45 -> 123.45)
    cleaned = cleaned.replace(',', '.')
    
    # Sadece sayısal karakterleri al
    cleaned = re.sub(r'[^\d.]', '', cleaned)
    
    try:
        return float(cleaned) if cleaned else None
    except (ValueError, TypeError):
        return None


# ============================================================================
# ÜNİVERSİTE AYRIŞTIRMA (AKILLI REGEX)
# ============================================================================

def parse_university_name(uni_name_raw: str) -> Tuple[str, str, str]:
    """
    ✅ ÖSYM formatındaki üniversite adını regex ile ayrıştır
    
    Format: "ABDULLAH GÜL ÜNİVERSİTESİ (KAYSERİ) (Devlet Üniversitesi)"
    
    Args:
        uni_name_raw: Ham üniversite adı
    
    Returns:
        Tuple[str, str, str]: (university_name, city, university_type)
    """
    if not uni_name_raw:
        return ("", "Bilinmiyor", "devlet")
    
    # ✅ Önce encoding düzeltmesi yap
    uni_str = clean_text(uni_name_raw)
    
    if not uni_str:
        return ("", "Bilinmiyor", "devlet")
    
    # ✅ Regex pattern: ^(.*?)\s+\((.*?)\)\s+\((.*?)\)$
    # Grup 1: Üniversite adı
    # Grup 2: Şehir
    # Grup 3: Tür (Devlet Üniversitesi / Vakıf Üniversitesi)
    pattern = r'^(.*?)\s+\((.*?)\)\s+\((.*?)\)$'
    match = re.match(pattern, uni_str)
    
    if match:
        university_name = clean_text(match.group(1)) or ""  # ✅ Encoding düzeltmesi
        city_raw = match.group(2).strip()  # ✅ ZORUNLU: .strip() kullan
        city = clean_text(city_raw) or ""  # ✅ Encoding düzeltmesi
        uni_type_raw = clean_text(match.group(3)) or ""
        
        # ✅ Şehir adındaki artık karakterleri temizle (Ì, Î, vb.) - Ekstra güvenlik
        if city:
            city = re.sub(r'[ÌÎÂ]', '', city).strip()  # ✅ Artık karakterleri sil
            # Tekrar clean_text çağır (güvenlik için)
            city = clean_text(city) or ""
            city = city.strip().title() if city else "Bilinmiyor"  # ✅ ZORUNLU: .strip() kullan
        
        # ✅ Üniversite türünü normalize et
        uni_type_upper = uni_type_raw.upper() if uni_type_raw else ""
        if 'VAKIF' in uni_type_upper or 'VAKÏF' in uni_type_upper or 'FOUNDATION' in uni_type_upper:
            university_type = 'vakif'
        else:
            university_type = 'devlet'  # Varsayılan
        
        return (university_name, city, university_type)
    
    # ✅ Fallback: Eğer regex eşleşmezse eski yöntemi kullan
    # Tek parantez varsa şehir olarak kabul et
    if '(' in uni_str and ')' in uni_str:
        # Son parantez içindeki değeri al
        start = uni_str.rfind('(')
        end = uni_str.rfind(')')
        city_raw = uni_str[start+1:end].strip()  # ✅ ZORUNLU: .strip() kullan
        city = clean_text(city_raw) or ""
        
        # Artık karakterleri temizle
        if city:
            city = re.sub(r'[ÌÎÂ]', '', city).strip()  # ✅ Artık karakterleri sil
            city = clean_text(city) or ""  # ✅ Tekrar encoding düzeltmesi
            city = city.strip().title() if city else "Bilinmiyor"  # ✅ ZORUNLU: .strip() kullan
        
        # Üniversite adından parantezleri temizle
        university_name = re.sub(r'\s*\([^)]+\)\s*', '', uni_str).strip()
        university_name = clean_text(university_name) or ""
        
        # Türü üniversite adından tespit et
        uni_name_upper = university_name.upper() if university_name else ""
        if 'VAKIF' in uni_name_upper or 'FOUNDATION' in uni_name_upper:
            university_type = 'vakif'
        else:
            university_type = 'devlet'
        
        return (university_name, city, university_type)
    
    # ✅ Hiç parantez yoksa
    university_name = clean_text(uni_str) or ""
    return (university_name, "Bilinmiyor", "devlet")


# ============================================================================
# YARDIMCI FONKSİYONLAR
# ============================================================================

def is_program_code(value) -> bool:
    """
    ✅ Satırın başında Program Kodu (ID) var mı kontrol et
    
    Program kodları genellikle 9 haneli sayılardır (örn: 106510090)
    """
    if pd.isna(value) or value is None:
        return False
    
    value_str = str(value).strip()
    
    # Sadece rakamlardan oluşuyorsa ve 6-10 haneli ise program kodu olabilir
    if value_str.isdigit() and 6 <= len(value_str) <= 10:
        return True
    
    return False


def is_university_header(row: pd.Series) -> bool:
    """
    ✅ Satırın üniversite başlığı olup olmadığını kontrol et
    
    Üniversite başlıkları genellikle:
    - İlk sütun boş veya çok kısa
    - İkinci sütunda "ÜNİVERSİTESİ" veya "ÜNİVERSİTE" kelimesi geçer
    """
    if len(row) < 2:
        return False
    
    first_col = str(row.iloc[0]).strip() if not pd.isna(row.iloc[0]) else ""
    second_col = str(row.iloc[1]).strip() if not pd.isna(row.iloc[1]) else ""
    
    # İlk sütun boş veya çok kısa, ikinci sütunda "ÜNİVERSİTE" geçiyorsa
    if (not first_col or len(first_col) < 3) and "ÜNİVERSİTE" in second_col.upper():
        return True
    
    return False


def is_faculty_header(row: pd.Series) -> bool:
    """
    ✅ Satırın fakülte başlığı olup olmadığını kontrol et
    
    Fakülte başlıkları genellikle:
    - İlk sütun boş
    - İkinci sütunda "FAKÜLTE", "YÜKSEKOKUL", "MESLEK YÜKSEKOKULU" gibi kelimeler geçer
    """
    if len(row) < 2:
        return False
    
    first_col = str(row.iloc[0]).strip() if not pd.isna(row.iloc[0]) else ""
    second_col = str(row.iloc[1]).strip() if not pd.isna(row.iloc[1]) else ""
    
    # İlk sütun boş ve ikinci sütunda fakülte/yüksekokul kelimesi geçiyorsa
    if (not first_col or len(first_col) < 3):
        second_upper = second_col.upper()
        if any(keyword in second_upper for keyword in [
            "FAKÜLTE", "YÜKSEKOKUL", "MESLEK YÜKSEKOKULU", 
            "ENSTİTÜ", "KOLEJ", "OKUL"
        ]):
            return True
    
    return False


# ============================================================================
# ANA İMPORT FONKSİYONU
# ============================================================================

def import_data_file(file_path: Path, db: Session, degree_type: str) -> Tuple[int, int]:
    """
    ✅ Veri dosyasını (CSV/Excel) satır satır oku ve veritabanına aktar
    
    Args:
        file_path: Veri dosya yolu (CSV, XLS, XLSX)
        db: Database session
        degree_type: "lisans" veya "tyt" (onlisans için)
    
    Returns:
        Tuple[int, int]: (eklenen_üniversite_sayısı, eklenen_bölüm_sayısı)
    """
    print(f"\n📁 {file_path.name} işleniyor...")
    print_info(f"Bölüm Türü: {degree_type}")
    print_info(f"Dosya formatı: {file_path.suffix}")
    
    # ✅ Stateful parsing için hafıza
    current_university: Optional[str] = None
    current_faculty: Optional[str] = None
    current_university_id: Optional[int] = None
    
    universities_added = 0
    departments_added = 0
    departments_updated = 0
    
    try:
        # ✅ Dosyayı oku (CSV veya Excel)
        file_ext = file_path.suffix.lower()
        
        if file_ext in ['.xlsx', '.xls']:
            # Excel dosyası
            try:
                df = pd.read_excel(
                    file_path,
                    sheet_name=0,
                    header=None,  # Başlık satırı yok, tüm satırları oku
                    engine='openpyxl' if file_ext == '.xlsx' else None
                )
            except Exception as e1:
                print_warning(f"Excel okuma hatası (openpyxl): {e1}")
                try:
                    df = pd.read_excel(
                        file_path,
                        sheet_name=0,
                        header=None,
                        engine=None  # Varsayılan engine
                    )
                except Exception as e2:
                    print_error(f"Excel okuma hatası: {e2}")
                    return 0, 0
        
        elif file_ext == '.csv':
            # ✅ CSV dosyası - ENCODING ÖNCELİĞİ (Kritik)
            # Excel'den çıkan CSV dosyaları genellikle cp1254 (Windows Turkish) kodlamasındadır
            # İlk Sırada: cp1254 (Windows Türkçe) - %99 ihtimalle doğru olan budur
            # İkinci Sırada: utf-8 (BOM'suz standart UTF-8)
            # Üçüncü Sırada: utf-8-sig (Excel UTF-8)
            df = None
            encodings_to_try = [
                ('cp1254', 'Windows Turkish (CP1254) - Öncelikli'),
                ('utf-8', 'UTF-8 (BOM\'suz standart)'),
                ('utf-8-sig', 'UTF-8 (Excel UTF-8)'),
            ]
            
            for encoding, encoding_name in encodings_to_try:
                try:
                    print_info(f"Encoding deneniyor: {encoding_name} ({encoding})...")
                    df = pd.read_csv(
                        file_path,
                        encoding=encoding,
                        delimiter=',',
                        header=None,  # Başlık satırı yok, tüm satırları oku
                        skipinitialspace=True,
                        low_memory=False
                    )
                    # ✅ İlk satırı kontrol et - Türkçe karakterler doğru mu?
                    if len(df) > 0:
                        first_row_sample = str(df.iloc[0, 1] if len(df.columns) > 1 else df.iloc[0, 0])
                        # Mojibake kontrolü - eğer "Ã" veya "Ä" gibi karakterler varsa encoding yanlış
                        if 'Ã' in first_row_sample or 'Ä' in first_row_sample or '??' in first_row_sample:
                            print_warning(f"{encoding_name} encoding mojibake tespit edildi, sonraki encoding deneniyor...")
                            df = None
                            continue
                    
                    print_success(f"✅ Dosya başarıyla okundu: {encoding_name}")
                    break
                except UnicodeDecodeError as e:
                    print_warning(f"{encoding_name} encoding hatası: {str(e)[:50]}...")
                    continue
                except Exception as e:
                    print_warning(f"{encoding_name} okuma hatası: {str(e)[:50]}...")
                    continue
            
            if df is None:
                print_error("❌ Tüm encoding denemeleri başarısız oldu!")
                return 0, 0
        else:
            print_error(f"Desteklenmeyen dosya formatı: {file_ext}")
            return 0, 0
        
        print_success(f"{len(df)} satır okundu")
        
        # ✅ Her satırı işle
        for idx, row in df.iterrows():
            try:
                # Satırı temizle (boş satırları atla)
                if row.isna().all():
                    continue
                
                # ✅ 1. Program Kodu kontrolü (Bölüm satırı mı?)
                first_col = row.iloc[0] if len(row) > 0 else None
                
                if is_program_code(first_col):
                    # ✅ Bu bir BÖLÜM satırı
                    if not current_university:
                        print_warning(f"Satır {idx+1}: Üniversite bilgisi yok, atlanıyor")
                        continue
                    
                    # ✅ Sütun eşleştirmesi
                    program_code = str(first_col).strip()
                    program_name_raw = str(row.iloc[1]).strip() if len(row) > 1 and not pd.isna(row.iloc[1]) else ""
                    program_name = clean_text(program_name_raw)  # ✅ Encoding düzeltmesi
                    
                    if not program_name:
                        continue  # Program adı yoksa atla
                    
                    # ✅ Puan Türü (4. sütun, index 3)
                    field_type_raw = str(row.iloc[3]).strip() if len(row) > 3 and not pd.isna(row.iloc[3]) else "SAY"
                    field_type_raw = clean_text(field_type_raw) or "SAY"  # ✅ Encoding düzeltmesi
                    field_type = validate_enum_value(field_type_raw, ['SAY', 'EA', 'SÖZ', 'DİL', 'TYT'], default='SAY')
                    
                    # ✅ Kontenjan (5. sütun, index 4)
                    quota_raw = clean_special_values(row.iloc[4] if len(row) > 4 else None)
                    quota = safe_to_int(quota_raw, default=None) if quota_raw is not None else None
                    
                    # ✅ Başarı Sırası (12. sütun, index 11)
                    min_rank_raw = clean_special_values(row.iloc[11] if len(row) > 11 else None)
                    min_rank = safe_to_int(min_rank_raw, default=None) if min_rank_raw is not None else None
                    
                    # ✅ Taban Puan (13. sütun, index 12)
                    min_score_raw = clean_special_values(row.iloc[12] if len(row) > 12 else None)
                    min_score = clean_score(min_score_raw)
                    
                    # ✅ Bölüm adını normalize et
                    program_name_clean = truncate_string_for_postgres(program_name, max_length=200, field_name="department.name")
                    if not program_name_clean:
                        continue
                    
                    # ✅ Duration belirleme
                    duration = 2 if degree_type == "tyt" else 4
                    
                    # ✅ Bölümü veritabanına ekle veya güncelle (Upsert)
                    existing_dept = db.query(Department).filter(
                        Department.university_id == current_university_id,
                        Department.normalized_name == program_name_clean,
                        Department.field_type == field_type
                    ).first()
                    
                    if existing_dept:
                        # ✅ Güncelle
                        existing_dept.quota = quota
                        existing_dept.min_score = min_score
                        existing_dept.min_rank = min_rank
                        existing_dept.duration = duration
                        if current_faculty:
                            faculty_clean = clean_text(current_faculty) or None
                            if faculty_clean:
                                existing_dept.faculty = truncate_string_for_postgres(faculty_clean, max_length=200, field_name="department.faculty")
                        departments_updated += 1
                    else:
                        # ✅ Yeni bölüm ekle
                        faculty_clean = None
                        if current_faculty:
                            faculty_clean = clean_text(current_faculty)
                            if faculty_clean:
                                faculty_clean = truncate_string_for_postgres(faculty_clean, max_length=200, field_name="department.faculty")
                        
                        new_dept = Department(
                            university_id=current_university_id,
                            name=program_name_clean,
                            normalized_name=program_name_clean,  # Normalize edilmiş isim aynı
                            field_type=field_type,
                            language='Turkish',  # Varsayılan
                            duration=duration,
                            degree_type='Associate' if degree_type == "tyt" else 'Bachelor',
                            faculty=faculty_clean,
                            quota=quota,
                            min_score=min_score,
                            min_rank=min_rank
                        )
                        db.add(new_dept)
                        departments_added += 1
                    
                    # Her 100 bölümde bir commit (performans için)
                    if (departments_added + departments_updated) % 100 == 0:
                        db.commit()
                        print_info(f"   ⏳ {departments_added + departments_updated} bölüm işlendi...")
                
                # ✅ 2. Üniversite başlığı kontrolü
                elif is_university_header(row):
                    university_name_raw = str(row.iloc[1]).strip() if len(row) > 1 else ""
                    
                    if university_name_raw:
                        # ✅ Regex ile üniversite adını, şehri ve türü ayrıştır
                        university_name, city, uni_type = parse_university_name(university_name_raw)
                        
                        university_name = truncate_string_for_postgres(university_name, max_length=200, field_name="university.name")
                        city = truncate_string_for_postgres(city, max_length=50, field_name="university.city")
                        
                        if university_name:
                            # ✅ Üniversiteyi veritabanında bul veya oluştur
                            existing_uni = db.query(University).filter(
                                University.name == university_name
                            ).first()
                            
                            if existing_uni:
                                current_university_id = existing_uni.id
                                current_university = university_name
                            else:
                                # Yeni üniversite oluştur
                                new_uni = University(
                                    name=university_name,
                                    city=city,
                                    university_type=uni_type,
                                    website=f"https://{university_name.lower().replace(' ', '').replace('ü', 'u').replace('ı', 'i').replace('ğ', 'g').replace('ş', 's').replace('ç', 'c').replace('ö', 'o')[:20]}.edu.tr"
                                )
                                db.add(new_uni)
                                db.flush()  # ID almak için
                                current_university_id = new_uni.id
                                current_university = university_name
                                universities_added += 1
                            
                            print_info(f"📌 Şu an {current_university} ({city}) taranıyor...")
                            current_faculty = None  # Fakülte sıfırla
                
                # ✅ 3. Fakülte başlığı kontrolü
                elif is_faculty_header(row):
                    faculty_name_raw = str(row.iloc[1]).strip() if len(row) > 1 else ""
                    if faculty_name_raw:
                        current_faculty = clean_text(faculty_name_raw) or None  # ✅ Encoding düzeltmesi
                        if current_faculty:
                            print_info(f"   📚 Fakülte: {current_faculty}")
            
            except Exception as e:
                # Hata durumunda devam et
                if (idx + 1) % 1000 == 0:
                    print_warning(f"Satır {idx+1} hatası: {str(e)[:100]}")
                continue
        
        # ✅ Son commit
        db.commit()
        
        print_success(f"✅ İşlem tamamlandı!")
        print_info(f"   Üniversite: {universities_added} eklendi")
        print_info(f"   Bölüm: {departments_added} eklendi, {departments_updated} güncellendi")
        
        return universities_added, departments_added + departments_updated
        
    except Exception as e:
        print_error(f"CRITICAL: Veri import hatası: {e}")
        import traceback
        print_error(traceback.format_exc())
        db.rollback()
        return 0, 0


# ============================================================================
# ANA FONKSİYON
# ============================================================================

def main():
    """✅ Ana fonksiyon - Tüm CSV dosyalarını işle"""
    print_section("ÖSYM 2025 KILAVUZ VERİLERİNİ İÇE AKTAR")
    print(f"{Colors.OKCYAN}🕐 Başlangıç Zamanı: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}{Colors.ENDC}\n")
    
    # ✅ Database bağlantısı (temizleme için)
    db_cleanup = SessionLocal()
    
    try:
        # ✅ Veritabanını temizle (bozuk verileri sil)
        print_section("🗑️  VERİTABANI TEMİZLENİYOR")
        print_warning("Mevcut University ve Department verileri silinecek...")
        
        try:
            # Foreign key sırasına göre temizle
            db_cleanup.execute(text("TRUNCATE TABLE department_yearly_stats CASCADE"))
            print_success("DepartmentYearlyStats tablosu temizlendi")
            db_cleanup.execute(text("TRUNCATE TABLE departments CASCADE"))
            print_success("Departments tablosu temizlendi")
            db_cleanup.execute(text("TRUNCATE TABLE universities CASCADE"))
            print_success("Universities tablosu temizlendi")
            db_cleanup.commit()
            print_success("✅ Veritabanı temizlendi!")
        except Exception as e:
            db_cleanup.rollback()
            print_warning(f"TRUNCATE hatası (alternatif yöntem deneniyor): {e}")
            try:
                # Alternatif: SQLAlchemy ile sil
                db_cleanup.query(DepartmentYearlyStats).delete()
                db_cleanup.query(Department).delete()
                db_cleanup.query(University).delete()
                db_cleanup.commit()
                print_success("✅ Veritabanı temizlendi (alternatif yöntem)!")
            except Exception as e2:
                db_cleanup.rollback()
                print_error(f"Veritabanı temizleme başarısız: {e2}")
                print_warning("⚠️  Mevcut verilerle devam ediliyor...")
    finally:
        db_cleanup.close()
    
    # ✅ Programs klasörünü kontrol et
    if not PROGRAMS_DIR.exists():
        print_error(f"{PROGRAMS_DIR} klasörü bulunamadı!")
        print_info("💡 Lütfen dosyaları backend/data/programs/ klasörüne koyun")
        print_info(f"   Mevcut çalışma dizini: {os.getcwd()}")
        print_info(f"   Script yolu: {Path(__file__).parent}")
        return 1
    
    print_info(f"📂 Klasör taranıyor: {PROGRAMS_DIR}")
    print_info(f"   Klasör var mı: {PROGRAMS_DIR.exists()}")
    if PROGRAMS_DIR.exists():
        all_files = list(PROGRAMS_DIR.iterdir())
        print_info(f"   Klasördeki dosyalar: {[f.name for f in all_files]}")
    
    # ✅ Hem CSV hem de Excel dosyalarını bul (.csv, .xls, .xlsx)
    csv_files = list(PROGRAMS_DIR.glob('*.csv'))
    xls_files = list(PROGRAMS_DIR.glob('*.xls'))
    xlsx_files = list(PROGRAMS_DIR.glob('*.xlsx'))
    
    data_files = csv_files + xls_files + xlsx_files
    
    if not data_files:
        print_error(f"{PROGRAMS_DIR} klasöründe veri dosyası bulunamadı!")
        print_info("💡 ÖSYM kılavuz dosyalarını (CSV, XLS, XLSX) backend/data/programs/ klasörüne koyun")
        print_info(f"   Desteklenen formatlar: .csv, .xls, .xlsx")
        return 1
    
    print_success(f"{len(data_files)} veri dosyası bulundu:")
    for f in data_files:
        print(f"   - {f.name} ({f.suffix})")
    
    # ✅ Database bağlantısı (import için)
    db = SessionLocal()
    
    total_universities = 0
    total_departments = 0
    
    try:
        # ✅ Her dosyayı işle
        for data_file in data_files:
            # ✅ Dosya adından bölüm türünü belirle
            file_name_lower = data_file.name.lower()
            
            if "onlisans" in file_name_lower or "önlisans" in file_name_lower:
                degree_type = "tyt"  # 2 yıllık
            elif "lisans" in file_name_lower:
                degree_type = "lisans"  # 4 yıllık
            else:
                print_warning(f"Dosya adından bölüm türü belirlenemedi: {data_file.name}, varsayılan: lisans")
                degree_type = "lisans"
            
            # ✅ Dosyayı import et
            unis, depts = import_data_file(data_file, db, degree_type)
            total_universities += unis
            total_departments += depts
        
        # ✅ Özet rapor
        print_section("📋 ÖZET RAPOR")
        
        # Database'deki toplam sayılar
        uni_count = db.query(University).count()
        dept_count = db.query(Department).count()
        
        print_success(f"Toplam {total_universities} üniversite eklendi")
        print_success(f"Toplam {total_departments} bölüm işlendi (ekleme + güncelleme)")
        print_info(f"💾 Veritabanında: {uni_count} üniversite, {dept_count} bölüm")
        
        print(f"\n{Colors.OKGREEN}{Colors.BOLD}✅ İMPORT TAMAMLANDI!{Colors.ENDC}")
        print(f"{Colors.OKCYAN}🕐 Bitiş Zamanı: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}{Colors.ENDC}\n")
        
        return 0
        
    except Exception as e:
        print_error(f"CRITICAL: Script hatası: {e}")
        import traceback
        print_error(traceback.format_exc())
        db.rollback()
        return 1
    finally:
        db.close()


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
