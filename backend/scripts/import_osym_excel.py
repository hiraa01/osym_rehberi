"""
ÖSYM Excel Dosyalarından Yerleştirme Verilerini İçe Aktar
✅ GÜNCELLENMİŞ: Normalize edilmiş bölüm isimleri ve yıllara göre veri saklama

KULLANIM:
1. ÖSYM'den Excel dosyalarını indir (örn: 2024_yerlestirme_l.xlsx, 2025_yerlestirme_l.xlsx)
2. backend/data/ klasörüne koy
3. Bu scripti çalıştır: python scripts/import_osym_excel.py

NOT: ÖSYM Excel formatı yıllara göre değişebilir, bu yüzden 
kolonları kontrol edip gerekirse ayarla.
"""
import sys
import os
import re
import json
sys.path.append('/app')

import pandas as pd
from pathlib import Path
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError, DataError
from database import SessionLocal
from models import University, Department, DepartmentYearlyStats
# ✅ PostgreSQL uyumlu veri temizleme fonksiyonları
from utils.postgresql_helpers import (
    safe_to_int, safe_to_float, safe_to_string,
    clean_excel_numeric, truncate_string_for_postgres,
    validate_enum_value, is_na_value
)

# ✅ Veri dosyalarının bulunduğu klasörler (hem /app/data hem de /app/data/raw_files)
DATA_DIRS = [
    Path('/app/data'),
    Path('/app/data/raw_files'),
]

# ÖSYM Excel kolonları (2024-2025 formatına göre)
COLUMN_MAPPING = {
    # Orjinal Kolon Adı -> Bizim Model Field Adı
    'Program Adı': 'name',
    'Üniversite Adı': 'university_name',
    'Üniversite Türü': 'university_type',  # DEVLET/VAKIF
    'Fakülte/Yüksekokul Adı': 'faculty',
    'Puan Türü': 'field_type',  # SAY/EA/SÖZ/DİL
    'Kontenjan': 'quota',
    'Yerleşen': 'placed_students',
    'En Küçük Puan': 'min_score',
    'En Büyük Puan': 'max_score',
}


def normalize_department_name(dept_name: str) -> tuple[str, list[str]]:
    """
    ✅ Bölüm ismini normalize et ve parantez içi detayları ayır
    
    Örnek:
    - "Bilgisayar Mühendisliği (İngilizce) (%50 İndirimli)" 
      -> ("Bilgisayar Mühendisliği", ["İngilizce", "%50 İndirimli"])
    - "Tıp (Burslu)"
      -> ("Tıp", ["Burslu"])
    - "Psikoloji"
      -> ("Psikoloji", [])
    
    Returns:
        tuple: (normalized_name, attributes_list)
    """
    if not dept_name or pd.isna(dept_name):
        return ("", [])
    
    dept_str = str(dept_name).strip()
    
    # Parantez içindeki tüm ifadeleri bul
    # Regex: (.*?) ile tüm parantez içi içerikleri yakala
    pattern = r'\(([^)]+)\)'
    matches = re.findall(pattern, dept_str)
    
    # Parantez içi içerikleri attributes olarak topla
    attributes = [match.strip() for match in matches if match.strip()]
    
    # Normalize edilmiş isim: Tüm parantezleri ve içeriklerini kaldır
    normalized = re.sub(pattern, '', dept_str).strip()
    
    # Fazla boşlukları temizle
    normalized = re.sub(r'\s+', ' ', normalized).strip()
    
    return (normalized, attributes)


def extract_city_from_university(uni_name):
    """Üniversite adından şehri çıkar (parantez içinde)"""
    if pd.isna(uni_name):
        return 'Bilinmiyor'
    
    uni_str = str(uni_name).strip()
    # Parantez içindeki şehir adını bul
    if '(' in uni_str and ')' in uni_str:
        start = uni_str.rfind('(')
        end = uni_str.rfind(')')
        city = uni_str[start+1:end].strip()
        # Şehir adını title case yap
        return city.title()
    
    return 'Bilinmiyor'


def normalize_university_type(value):
    """
    ✅ Üniversite tipini normalize et (devlet/vakif/kktc)
    
    Kapsamlı eşleştirme:
    - 'VAKIF MYO', 'VAKIF', 'VAKIF ÜNİVERSİTESİ' -> 'vakif'
    - 'DEVLET', 'DEVLET ÜNİVERSİTESİ' -> 'devlet'
    - 'KKTC', 'KIBRIS' -> 'kktc'
    - Diğerleri -> 'devlet' (default)
    """
    if pd.isna(value):
        return 'devlet'
    
    value_upper = str(value).upper().strip()
    
    # ✅ Vakıf üniversiteleri (kapsamlı kontrol)
    if any(keyword in value_upper for keyword in ['VAKIF', 'VAKÏF', 'VAKIF MYO', 'VAKIF ÜNİVERSİTESİ', 'VAKIF ÜNİVERSİTE']):
        return 'vakif'
    
    # ✅ KKTC üniversiteleri
    if any(keyword in value_upper for keyword in ['KKTC', 'KIBRIS', 'KIBRIS TÜRK', 'CYPRUS']):
        return 'kktc'
    
    # ✅ Devlet üniversiteleri (açıkça belirtilmişse)
    if any(keyword in value_upper for keyword in ['DEVLET', 'DEVLET ÜNİVERSİTESİ', 'DEVLET ÜNİVERSİTE']):
        return 'devlet'
    
    # ✅ Default: devlet (çoğu üniversite devlet)
    return 'devlet'


def normalize_field_type(value):
    """Alan türünü normalize et (SAY/EA/SÖZ/DİL/TYT)"""
    if pd.isna(value):
        return 'SAY'
    
    value = str(value).upper().strip()
    # ÖSYM'de farklı yazılışlar olabilir
    # ✅ CRITICAL: TYT kontrolü önce yapılmalı (çünkü TYT önlisans demektir)
    if 'TYT' in value:
        return 'TYT'
    elif 'EA' in value:
        return 'EA'
    elif 'SÖZ' in value or 'TS' in value:
        return 'SÖZ'
    elif 'DİL' in value or 'YDİL' in value:
        return 'DİL'
    elif 'SAY' in value or 'TM' in value:
        return 'SAY'
    return 'SAY'


def clean_numeric_value(value):
    """
    ✅ PostgreSQL uyumlu: Sayısal değerleri temizle (virgül, nokta, vs.)
    
    PostgreSQL için NULL değerler 0.0 yerine None döndürülmeli (nullable=True alanlar için).
    """
    # ✅ PostgreSQL helper kullan
    result = clean_excel_numeric(value, default=None)
    # Eğer None ise ve nullable=False ise 0.0 döndür
    return result if result is not None else 0.0


def clean_special_values(value):
    """
    ✅ ÖSYM verilerindeki özel karakterleri temizle ve NULL'a çevir
    
    "Dolmadı", "...", "-", "N/A" gibi değerleri None (PostgreSQL NULL) olarak döndür
    """
    if pd.isna(value):
        return None
    
    value_str = str(value).strip().upper()
    
    # Özel değerler listesi
    null_values = [
        "DOLMADI", "DOLMADı", "Dolmadı", "dolmadı",
        "...", "---", "-", "N/A", "NA", "NULL", "NONE",
        "YOK", "Yok", "yok", "BELİRTİLMEMİŞ", "Belirtilmemiş"
    ]
    
    if value_str in null_values or not value_str:
        return None
    
    return value


def read_data_file(file_path: Path):
    """
    ✅ Hem Excel hem de CSV dosyalarını oku
    
    Returns:
        pd.DataFrame: Okunan veri
    """
    file_ext = file_path.suffix.lower()
    
    if file_ext in ['.xlsx', '.xls']:
        # Excel dosyası - ÖSYM formatında ilk 2 satır başlık, 3. satır kolon isimleri
        try:
            df = pd.read_excel(file_path, sheet_name=0, header=2)
            return df
        except Exception as e:
            print(f"   ⚠️  Excel okuma hatası (header=2): {e}")
            # Alternatif: header=0 ile dene
            try:
                df = pd.read_excel(file_path, sheet_name=0, header=0)
                return df
            except Exception as e2:
                print(f"   ❌ Excel okuma hatası (header=0): {e2}")
                raise
    
    elif file_ext == '.csv':
        # CSV dosyası - ÖSYM formatında delimiter ve encoding kontrolü
        try:
            # Önce UTF-8 ile dene
            df = pd.read_csv(
                file_path,
                encoding='utf-8',
                delimiter=',',
                decimal='.',
                header=2,  # ÖSYM formatında 3. satır kolon isimleri
                skipinitialspace=True,
                na_values=['Dolmadı', '...', '-', 'N/A', 'NA', 'NULL', 'Yok', ''],
                low_memory=False
            )
            return df
        except Exception as e1:
            print(f"   ⚠️  CSV okuma hatası (UTF-8, delimiter=','): {e1}")
            try:
                # Alternatif: noktalı virgül delimiter
                df = pd.read_csv(
                    file_path,
                    encoding='utf-8',
                    delimiter=';',
                    decimal=',',
                    header=2,
                    skipinitialspace=True,
                    na_values=['Dolmadı', '...', '-', 'N/A', 'NA', 'NULL', 'Yok', ''],
                    low_memory=False
                )
                return df
            except Exception as e2:
                print(f"   ⚠️  CSV okuma hatası (delimiter=';'): {e2}")
                try:
                    # Alternatif: ISO-8859-9 encoding (Türkçe karakterler için)
                    df = pd.read_csv(
                        file_path,
                        encoding='iso-8859-9',
                        delimiter=',',
                        decimal='.',
                        header=2,
                        skipinitialspace=True,
                        na_values=['Dolmadı', '...', '-', 'N/A', 'NA', 'NULL', 'Yok', ''],
                        low_memory=False
                    )
                    return df
                except Exception as e3:
                    print(f"   ❌ CSV okuma hatası (tüm denemeler başarısız): {e3}")
                    raise
    
    else:
        raise ValueError(f"Desteklenmeyen dosya formatı: {file_ext}")


def import_excel_file(file_path: Path, year: int, db: Session):
    """✅ GÜNCELLENMİŞ: Tek bir Excel/CSV dosyasını import et - normalize edilmiş isimler ve yıllara göre veri saklama"""
    print(f"\n📁 {file_path.name} işleniyor (Yıl: {year})...")
    
    try:
        # ✅ Hem Excel hem de CSV dosyalarını oku
        df = read_data_file(file_path)
        
        print(f"   📊 {len(df)} satır bulundu")
        print(f"   🔍 Kolonlar: {df.columns.tolist()[:5]}...")
        
        # Kolonları kontrol et ve typo'ları düzelt
        # ÖSYM Excel'lerinde "Üniversites Türü" gibi typo'lar olabiliyor
        if 'Üniversites Türü' in df.columns and 'Üniversite Türü' not in df.columns:
            df.rename(columns={'Üniversites Türü': 'Üniversite Türü'}, inplace=True)
            print(f"   🔧 Typo düzeltildi: 'Üniversites Türü' → 'Üniversite Türü'")
        
        required_cols = ['Program Adı', 'Üniversite Adı', 'Üniversite Türü']
        missing_cols = [col for col in required_cols if col not in df.columns]
        
        if missing_cols:
            print(f"   ⚠️  Eksik kolonlar: {missing_cols}")
            print(f"   💡 Mevcut kolonlar: {df.columns.tolist()}")
            print(f"   ℹ️  Script'teki COLUMN_MAPPING'i güncelleyin!")
            return 0, 0, 0
        
        # Üniversite, Bölüm ve Yıllık İstatistik sayaçları
        new_universities = 0
        new_departments = 0
        new_yearly_stats = 0
        
        # Her satırı işle
        for idx, row in df.iterrows():
            try:
                # Üniversite bilgilerini al
                uni_name_raw = str(row.get('Üniversite Adı', '')).strip()
                if not uni_name_raw or uni_name_raw == 'nan':
                    continue
                
                # Şehri üniversite adından çıkar
                city = extract_city_from_university(uni_name_raw)
                
                # Üniversite adından şehir kısmını temizle
                if '(' in uni_name_raw:
                    uni_name = uni_name_raw[:uni_name_raw.rfind('(')].strip()
                else:
                    uni_name = uni_name_raw
                
                # ✅ PostgreSQL uyumlu: String uzunluk kontrolü
                uni_name = truncate_string_for_postgres(uni_name, max_length=200, field_name="university.name")
                if not uni_name:
                    continue  # Üniversite adı yoksa atla
                
                # ✅ PostgreSQL uyumlu: Enum doğrulama
                # Önce normalize et (kapsamlı eşleştirme), sonra validate et (sessiz mod)
                uni_type_raw = row.get('Üniversite Türü', 'devlet')
                uni_type_normalized = normalize_university_type(uni_type_raw)
                # Normalize edilmiş değer zaten geçerli enum değeri olmalı, sessiz mod ile validate et
                uni_type = validate_enum_value(uni_type_normalized, ['devlet', 'vakif', 'kktc'], default=uni_type_normalized, silent=True)
                
                # Üniversite var mı kontrol et
                university = db.query(University).filter(
                    University.name == uni_name
                ).first()
                
                if not university:
                    # Yeni üniversite ekle
                    university = University(
                        name=uni_name,
                        city=city,
                        university_type=uni_type,
                        website=f"https://{uni_name.lower().replace(' ', '').replace('ü', 'u').replace('ı', 'i').replace('ğ', 'g').replace('ş', 's').replace('ç', 'c').replace('ö', 'o')[:20]}.edu.tr"
                    )
                    db.add(university)
                    db.flush()  # ID almak için
                    new_universities += 1
                else:
                    # ✅ Mevcut üniversite varsa, türünü güncelle (yanlışsa düzelt)
                    if university.university_type != uni_type:
                        print(f"   🔧 Üniversite türü güncelleniyor: {uni_name} ({university.university_type} → {uni_type})")
                        university.university_type = uni_type
                        db.flush()  # Değişikliği kaydet
                
                # ✅ Bölüm bilgilerini al ve normalize et
                dept_name_raw = str(row.get('Program Adı', '')).strip()
                if not dept_name_raw or dept_name_raw == 'nan':
                    continue
                
                # Normalize et
                normalized_name, attributes = normalize_department_name(dept_name_raw)
                if not normalized_name:
                    continue
                
                # ✅ PostgreSQL uyumlu: String uzunluk kontrolü
                dept_name_raw = truncate_string_for_postgres(dept_name_raw, max_length=200, field_name="department.name")
                normalized_name = truncate_string_for_postgres(normalized_name, max_length=200, field_name="department.normalized_name")
                
                # ✅ PostgreSQL uyumlu: Enum doğrulama
                field_type_raw = row.get('Puan Türü', 'SAY')
                field_type = validate_enum_value(field_type_raw, ['SAY', 'EA', 'SÖZ', 'DİL', 'TYT'], default='SAY')
                
                # Dil bilgisini program adından çıkar (İngilizce, %30 İngilizce vs.)
                language = 'Turkish'
                if 'İngilizce' in dept_name_raw or 'English' in dept_name_raw:
                    language = 'English'
                elif '%' in dept_name_raw and ('İngilizce' in dept_name_raw or 'English' in dept_name_raw):
                    language = 'Partial English'
                
                # ✅ CRITICAL FIX: Duration ve degree_type mantığı
                # Bölüm adından veya field_type'dan önlisans/lisans ayrımı yap
                dept_name_upper = dept_name_raw.upper()
                is_onlisans = False
                
                # 1. Field type kontrolü: TYT = Önlisans
                if field_type == 'TYT':
                    is_onlisans = True
                
                # 2. Bölüm adı kontrolü: "Önlisans", "2 Yıllık", "MYO" gibi kelimeler
                onlisans_keywords = ['ÖNLİSANS', 'ÖN LİSANS', '2 YILLIK', '2 YIL', 'MYO', 
                                     'MESLEK YÜKSEKOKULU', 'MESLEK YÜKSEK OKULU', 'AÖF', 'AÇIKÖĞRETİM']
                if any(keyword in dept_name_upper for keyword in onlisans_keywords):
                    is_onlisans = True
                    # Eğer field_type TYT değilse, TYT yap
                    if field_type != 'TYT':
                        field_type = 'TYT'
                
                # 3. Lisans bölümleri kontrolü: "Tıp", "Mühendislik", "Hukuk" gibi
                # Bu bölümler kesinlikle lisans olmalı
                lisans_keywords = ['TIP', 'MÜHENDİSLİK', 'HUKUK', 'MİMARLIK', 'DİŞ HEKİMLİĞİ',
                                   'ECZACILIK', 'VETERİNER', 'ZİRAAT', 'ORMAN']
                if any(keyword in dept_name_upper for keyword in lisans_keywords):
                    is_onlisans = False
                    # Eğer field_type TYT ise, SAY yap (çünkü lisans bölümü)
                    if field_type == 'TYT':
                        field_type = 'SAY'
                
                # Duration ve degree_type belirleme
                if is_onlisans:
                    duration = 2
                    degree_type = 'Associate'
                else:
                    # Lisans bölümleri: genelde 4 yıl, bazıları 5-6 yıl
                    # Tıp: 6 yıl, Diş Hekimliği: 5 yıl, Veteriner: 5 yıl
                    if 'TIP' in dept_name_upper:
                        duration = 6
                    elif 'DİŞ HEKİMLİĞİ' in dept_name_upper or 'DİŞHEKİMLİĞİ' in dept_name_upper:
                        duration = 5
                    elif 'VETERİNER' in dept_name_upper:
                        duration = 5
                    elif 'MİMARLIK' in dept_name_upper:
                        duration = 5
                    else:
                        duration = 4  # Varsayılan lisans süresi
                    degree_type = 'Bachelor'
                # ✅ PostgreSQL uyumlu: Sayısal değerleri temizle ve doğrula
                # ✅ ÖSYM verilerindeki özel karakterleri temizle ("Dolmadı", "...", vb.)
                quota_raw = clean_special_values(row.get('Kontenjan', None))
                quota = safe_to_int(quota_raw, default=0) if quota_raw is not None else 0
                
                placed_students_raw = clean_special_values(row.get('Yerleşen', None))
                placed_students = safe_to_int(placed_students_raw, default=0) if placed_students_raw is not None else 0
                
                min_score_raw = clean_special_values(row.get('En Küçük Puan', None))
                min_score = safe_to_float(min_score_raw, default=None) if min_score_raw is not None else None  # ✅ NULL olabilir
                
                max_score_raw = clean_special_values(row.get('En Büyük Puan', None))
                max_score = safe_to_float(max_score_raw, default=None) if max_score_raw is not None else None  # ✅ NULL olabilir
                
                min_rank_raw = clean_special_values(row.get('En Küçük Sıralama', None))
                min_rank = safe_to_int(min_rank_raw, default=None) if min_rank_raw is not None else None  # ✅ NULL olabilir
                
                max_rank_raw = clean_special_values(row.get('En Büyük Sıralama', None))
                max_rank = safe_to_int(max_rank_raw, default=None) if max_rank_raw is not None else None  # ✅ NULL olabilir
                
                # ✅ Bölüm var mı kontrol et (aynı üniversite, normalize edilmiş isim, aynı field_type)
                # NOT: Orijinal isim farklı olabilir (örn: "Tıp (Burslu)" vs "Tıp (%50 İndirimli)")
                # ama normalize edilmiş isim aynı olacak ("Tıp")
                existing_dept = db.query(Department).filter(
                    Department.university_id == university.id,
                    Department.normalized_name == normalized_name,
                    Department.field_type == field_type
                ).first()
                
                if existing_dept:
                    # ✅ Mevcut bölümü güncelle (en güncel yılın verileri)
                    # Attributes'ı birleştir (yeni attributes varsa ekle)
                    existing_attrs = json.loads(existing_dept.attributes) if existing_dept.attributes else []
                    combined_attrs = list(set(existing_attrs + attributes))  # Unique attributes
                    existing_dept.attributes = json.dumps(combined_attrs, ensure_ascii=False) if combined_attrs else None
                    
                    # En güncel yılın verilerini güncelle (sadece daha yeni yıl ise)
                    if year >= (existing_dept.updated_at.year if existing_dept.updated_at else 0):
                        existing_dept.min_score = min_score if (min_score is not None and min_score > 0) else existing_dept.min_score
                        existing_dept.min_rank = min_rank if (min_rank is not None and min_rank > 0) else existing_dept.min_rank
                        existing_dept.quota = quota if (quota is not None and quota > 0) else existing_dept.quota
                    
                    department = existing_dept
                else:
                    # ✅ Yeni bölüm ekle (normalize edilmiş isim ile)
                    department = Department(
                        university_id=university.id,
                        name=dept_name_raw,  # Orijinal isim
                        normalized_name=normalized_name,  # ✅ Normalize edilmiş isim
                        attributes=json.dumps(attributes, ensure_ascii=False) if attributes else None,  # ✅ JSON string
                        field_type=field_type,
                        language=language,
                        duration=duration,  # ✅ Artık doğru hesaplanıyor (2 veya 4+)
                        degree_type=degree_type,  # ✅ Associate veya Bachelor
                        quota=quota,
                        min_score=min_score if (min_score is not None and min_score > 0) else None,
                        min_rank=min_rank if (min_rank is not None and min_rank > 0) else None,
                    )
                    db.add(department)
                    db.flush()  # ID almak için
                    new_departments += 1
                
                # ✅ Yıllık istatistikleri kaydet (DepartmentYearlyStats)
                # Aynı bölüm için aynı yıl zaten varsa güncelle, yoksa yeni ekle
                # NOT: Aynı bölümün farklı varyasyonları (Burslu, %50 İndirimli) aynı Department'ı kullanır
                # Bu yüzden her varyasyon için ayrı YearlyStats eklenmemeli
                try:
                    # Önce mevcut kaydı kontrol et
                    existing_stats = db.query(DepartmentYearlyStats).filter(
                        DepartmentYearlyStats.department_id == department.id,
                        DepartmentYearlyStats.year == year
                    ).first()
                    
                    if existing_stats:
                        # Güncelle (daha iyi veriler varsa - min_score için en düşük, max_score için en yüksek)
                        if (min_score is not None and min_score > 0) and (existing_stats.min_score is None or min_score < existing_stats.min_score):
                            existing_stats.min_score = min_score
                        if (max_score is not None and max_score > 0) and (existing_stats.max_score is None or max_score > existing_stats.max_score):
                            existing_stats.max_score = max_score
                        if (min_rank is not None and min_rank > 0) and (existing_stats.min_rank is None or min_rank < existing_stats.min_rank):
                            existing_stats.min_rank = min_rank
                        if (max_rank is not None and max_rank > 0) and (existing_stats.max_rank is None or max_rank > existing_stats.max_rank):
                            existing_stats.max_rank = max_rank
                        if quota is not None and quota > 0:
                            existing_stats.quota = quota
                        if placed_students is not None and placed_students > 0:
                            existing_stats.placed_students = placed_students
                    else:
                        # Yeni yıllık istatistik ekle
                        yearly_stats = DepartmentYearlyStats(
                            department_id=department.id,
                            year=year,
                            min_score=min_score if (min_score is not None and min_score > 0) else None,
                            max_score=max_score if (max_score is not None and max_score > 0) else None,
                            min_rank=min_rank if (min_rank is not None and min_rank > 0) else None,
                            max_rank=max_rank if (max_rank is not None and max_rank > 0) else None,
                            quota=quota if (quota is not None and quota > 0) else None,
                            placed_students=placed_students if (placed_students is not None and placed_students > 0) else None,
                        )
                        db.add(yearly_stats)
                        db.flush()  # Flush yap ve hata varsa yakala
                        new_yearly_stats += 1
                except Exception as stats_error:
                    # ✅ Duplicate key hatası olabilir (aynı yıl için birden fazla kayıt eklendi)
                    # Bu durumda rollback yap ve mevcut kaydı güncelle
                    error_msg = str(stats_error)
                    if "UniqueViolation" in error_msg or "uq_department_year" in error_msg:
                        try:
                            db.rollback()  # Rollback yap
                            # Tekrar mevcut kaydı bul ve güncelle
                            existing_stats = db.query(DepartmentYearlyStats).filter(
                                DepartmentYearlyStats.department_id == department.id,
                                DepartmentYearlyStats.year == year
                            ).first()
                            if existing_stats:
                                # Mevcut kaydı güncelle
                                if (min_score is not None and min_score > 0) and (existing_stats.min_score is None or min_score < existing_stats.min_score):
                                    existing_stats.min_score = min_score
                                if (max_score is not None and max_score > 0) and (existing_stats.max_score is None or max_score > existing_stats.max_score):
                                    existing_stats.max_score = max_score
                                if quota is not None and quota > 0:
                                    existing_stats.quota = quota
                                if placed_students is not None and placed_students > 0:
                                    existing_stats.placed_students = placed_students
                        except Exception as retry_error:
                            # Eğer hala hata varsa, bu satırı atla (zaten kayıt var)
                            pass
                    else:
                        # Diğer hatalar için rollback yap
                        try:
                            db.rollback()
                        except:
                            pass
                
                # Her 500 satırda bir commit ve progress göster (daha sık feedback için)
                if (idx + 1) % 500 == 0:
                    try:
                        db.commit()
                        print(f"   ⏳ {idx + 1}/{len(df)} satır işlendi... (Uni: {new_universities}, Dept: {new_departments}, Stats: {new_yearly_stats})", flush=True)
                    except (IntegrityError, DataError) as db_error:
                        # ✅ PostgreSQL uyumlu hata yakalama
                        db.rollback()
                        error_msg = str(db_error)
                        
                        # ✅ PostgreSQL özel hata mesajları
                        if "duplicate key" in error_msg.lower() or "unique constraint" in error_msg.lower():
                            print(f"   ⚠️  Duplicate key hatası (satır {idx + 1}): Zaten mevcut kayıt, atlanıyor...", flush=True)
                        elif "value too long" in error_msg.lower() or "character varying" in error_msg.lower():
                            print(f"   ⚠️  String uzunluk hatası (satır {idx + 1}): {error_msg[:100]}", flush=True)
                            # String'i kes ve tekrar dene (opsiyonel)
                        elif "invalid input syntax" in error_msg.lower():
                            print(f"   ⚠️  Veri tipi hatası (satır {idx + 1}): {error_msg[:100]}", flush=True)
                        else:
                            print(f"   ⚠️  PostgreSQL hatası (satır {idx + 1}): {error_msg[:100]}", flush=True)
                        # Devam et, bir sonraki satırda düzelir
                    except Exception as commit_error:
                        db.rollback()
                        print(f"   ⚠️  Genel commit hatası (satır {idx + 1}): {str(commit_error)[:100]}", flush=True)
                        # Devam et, bir sonraki commit'te düzelir
            
            except Exception as e:
                # ✅ Hata durumunda rollback yap ve devam et
                try:
                    db.rollback()
                except:
                    pass
                
                error_msg = str(e)
                if "UniqueViolation" in error_msg or "uq_department_year" in error_msg or "PendingRollbackError" in error_msg:
                    # Duplicate key hatası veya rollback hatası - normal, atla
                    continue
                else:
                    print(f"   ⚠️  Satır {idx} hatası: {error_msg[:100]}")
                    # Sadece önemli hataları göster
                    if "Traceback" not in error_msg:  # Traceback zaten print edilmiş
                        import traceback
                        traceback.print_exc()
                    continue
        
        # Son commit
        db.commit()
        print(f"   ✅ {new_universities} yeni üniversite, {new_departments} yeni bölüm, {new_yearly_stats} yıllık istatistik eklendi!")
        return new_universities, new_departments, new_yearly_stats
        
    except Exception as e:
        print(f"   ❌ Dosya işleme hatası: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
        return 0, 0, 0


def find_data_files():
    """
    ✅ Tüm veri dosyalarını bul (hem Excel hem CSV, hem /app/data hem de /app/data/raw_files)
    
    Returns:
        list[Path]: Bulunan dosya yolları
    """
    all_files = []
    
    for data_dir in DATA_DIRS:
        if not data_dir.exists():
            print(f"⚠️  Klasör bulunamadı: {data_dir}")
            continue
        
        print(f"📂 Klasör taranıyor: {data_dir}")
        
        # Excel dosyaları
        xlsx_files = list(data_dir.glob('*.xlsx'))
        xls_files = list(data_dir.glob('*.xls'))
        # CSV dosyaları
        csv_files = list(data_dir.glob('*.csv'))
        
        found_in_dir = xlsx_files + xls_files + csv_files
        
        if found_in_dir:
            print(f"   ✅ {len(found_in_dir)} dosya bulundu:")
            for f in found_in_dir:
                print(f"      - {f.name} ({f.suffix})")
            all_files.extend(found_in_dir)
        else:
            print(f"   ⚠️  Bu klasörde dosya bulunamadı")
    
    return all_files


def main():
    """Ana import fonksiyonu"""
    import sys
    sys.stdout.flush()  # ✅ Buffer'ı temizle
    print("=" * 70, flush=True)
    print("ÖSYM VERİ DOSYALARINI İÇE AKTAR", flush=True)
    print("✅ Excel (.xlsx, .xls) ve CSV (.csv) desteği", flush=True)
    print("✅ Normalize edilmiş bölüm isimleri ve yıllara göre veri saklama", flush=True)
    print("=" * 70, flush=True)
    
    # ✅ Tüm veri dosyalarını bul (hem Excel hem CSV, hem /app/data hem de /app/data/raw_files)
    print("\n🔍 Veri dosyaları aranıyor...")
    data_files = find_data_files()
    
    if not data_files:
        print(f"\n❌ Hiçbir veri dosyası bulunamadı!")
        print(f"💡 ÖSYM'den indirdiğiniz dosyaları şu klasörlerden birine koyun:")
        for data_dir in DATA_DIRS:
            print(f"   - {data_dir}")
        print(f"   Desteklenen formatlar: .xlsx, .xls, .csv")
        print(f"   Örnek: 2024_yerlestirme_l.xlsx, 2025_yerlestirme_l.csv")
        return
    
    print(f"\n📊 Toplam {len(data_files)} dosya bulundu ve işlenecek")
    
    # Database bağlantısı
    db = SessionLocal()
    
    total_universities = 0
    total_departments = 0
    total_yearly_stats = 0
    
    try:
        # Her dosyayı işle
        for file_path in data_files:
            # Dosya adından yılı çıkarmaya çalış
            year = 2024  # Varsayılan
            try:
                year_str = ''.join(filter(str.isdigit, file_path.stem))[:4]
                if year_str:
                    year = int(year_str)
            except:
                pass
            
            unis, depts, stats = import_excel_file(file_path, year, db)
            total_universities += unis
            total_departments += depts
            total_yearly_stats += stats
        
        print("\n" + "=" * 70)
        print("✅ İMPORT TAMAMLANDI!")
        print("=" * 70)
        print(f"📊 Toplam: {total_universities} üniversite, {total_departments} bölüm, {total_yearly_stats} yıllık istatistik eklendi")
        
        # Database istatistikleri
        uni_count = db.query(University).count()
        dept_count = db.query(Department).count()
        stats_count = db.query(DepartmentYearlyStats).count()
        print(f"💾 Database'de: {uni_count} üniversite, {dept_count} bölüm, {stats_count} yıllık istatistik")
        
        # ✅ Normalize edilmiş bölüm sayısı (unique)
        unique_normalized = db.query(Department.normalized_name).distinct().count()
        print(f"🔍 Normalize edilmiş unique bölüm sayısı: {unique_normalized}")
        print("=" * 70)
        
    except Exception as e:
        print(f"\n❌ HATA: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    main()
