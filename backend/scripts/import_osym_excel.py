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
from database import SessionLocal
from models.university import University, Department, DepartmentYearlyStats

# Excel dosyalarının bulunduğu klasör
DATA_DIR = Path('/app/data')

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
    """Üniversite tipini normalize et (devlet/vakif)"""
    if pd.isna(value):
        return 'devlet'
    
    value_upper = str(value).upper().strip()
    if 'VAKIF' in value_upper or 'VAKÏF' in value_upper:
        return 'vakif'
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
    """Sayısal değerleri temizle (virgül, nokta, vs.)"""
    if pd.isna(value):
        return 0.0
    
    # String ise temizle
    if isinstance(value, str):
        value = value.replace(',', '.').replace(' ', '').strip()
        try:
            return float(value)
        except:
            return 0.0
    
    return float(value)


def import_excel_file(file_path: Path, year: int, db: Session):
    """✅ GÜNCELLENMİŞ: Tek bir Excel dosyasını import et - normalize edilmiş isimler ve yıllara göre veri saklama"""
    print(f"\n📁 {file_path.name} işleniyor (Yıl: {year})...")
    
    try:
        # Excel'i oku (ÖSYM formatında ilk 2 satır başlık, 3. satır kolon isimleri)
        df = pd.read_excel(file_path, sheet_name=0, header=2)
        
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
                
                uni_type = normalize_university_type(row.get('Üniversite Türü', 'devlet'))
                
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
                
                # ✅ Bölüm bilgilerini al ve normalize et
                dept_name_raw = str(row.get('Program Adı', '')).strip()
                if not dept_name_raw or dept_name_raw == 'nan':
                    continue
                
                # Normalize et
                normalized_name, attributes = normalize_department_name(dept_name_raw)
                if not normalized_name:
                    continue
                
                field_type = normalize_field_type(row.get('Puan Türü', 'SAY'))
                
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
                quota = int(clean_numeric_value(row.get('Kontenjan', 0)))
                placed_students = int(clean_numeric_value(row.get('Yerleşen', 0)))
                min_score = clean_numeric_value(row.get('En Küçük Puan', 0))
                max_score = clean_numeric_value(row.get('En Büyük Puan', 0))
                min_rank = 0  # Excel'de yok (genelde)
                max_rank = 0  # Excel'de yok (genelde)
                
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
                        existing_dept.min_score = min_score if min_score > 0 else existing_dept.min_score
                        existing_dept.min_rank = min_rank if min_rank > 0 else existing_dept.min_rank
                        existing_dept.quota = quota if quota > 0 else existing_dept.quota
                    
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
                        min_score=min_score if min_score > 0 else None,
                        min_rank=min_rank if min_rank > 0 else None,
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
                        if min_score > 0 and (existing_stats.min_score is None or min_score < existing_stats.min_score):
                            existing_stats.min_score = min_score
                        if max_score > 0 and (existing_stats.max_score is None or max_score > existing_stats.max_score):
                            existing_stats.max_score = max_score
                        if min_rank > 0 and (existing_stats.min_rank is None or min_rank < existing_stats.min_rank):
                            existing_stats.min_rank = min_rank
                        if max_rank > 0 and (existing_stats.max_rank is None or max_rank > existing_stats.max_rank):
                            existing_stats.max_rank = max_rank
                        if quota > 0:
                            existing_stats.quota = quota
                        if placed_students > 0:
                            existing_stats.placed_students = placed_students
                    else:
                        # Yeni yıllık istatistik ekle
                        yearly_stats = DepartmentYearlyStats(
                            department_id=department.id,
                            year=year,
                            min_score=min_score if min_score > 0 else None,
                            max_score=max_score if max_score > 0 else None,
                            min_rank=min_rank if min_rank > 0 else None,
                            max_rank=max_rank if max_rank > 0 else None,
                            quota=quota if quota > 0 else None,
                            placed_students=placed_students if placed_students > 0 else None,
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
                                if min_score > 0 and (existing_stats.min_score is None or min_score < existing_stats.min_score):
                                    existing_stats.min_score = min_score
                                if max_score > 0 and (existing_stats.max_score is None or max_score > existing_stats.max_score):
                                    existing_stats.max_score = max_score
                                if quota > 0:
                                    existing_stats.quota = quota
                                if placed_students > 0:
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
                    except Exception as commit_error:
                        db.rollback()
                        print(f"   ⚠️  Commit hatası (satır {idx + 1}): {str(commit_error)[:100]}", flush=True)
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


def main():
    """Ana import fonksiyonu"""
    import sys
    sys.stdout.flush()  # ✅ Buffer'ı temizle
    print("=" * 70, flush=True)
    print("ÖSYM EXCEL DOSYALARINI İÇE AKTAR", flush=True)
    print("✅ Normalize edilmiş bölüm isimleri ve yıllara göre veri saklama", flush=True)
    print("=" * 70, flush=True)
    
    # Data klasörünü kontrol et
    if not DATA_DIR.exists():
        print(f"❌ {DATA_DIR} klasörü bulunamadı!")
        print(f"💡 Lütfen backend/data/ klasörü oluşturun ve Excel dosyalarını oraya koyun")
        return
    
    # Excel dosyalarını bul
    excel_files = list(DATA_DIR.glob('*.xlsx')) + list(DATA_DIR.glob('*.xls'))
    
    if not excel_files:
        print(f"❌ {DATA_DIR} klasöründe Excel dosyası bulunamadı!")
        print(f"💡 ÖSYM'den indirdiğiniz Excel dosyalarını backend/data/ klasörüne koyun")
        print(f"   Örnek: 2024_yerlestirme_l.xlsx, 2025_yerlestirme_l.xlsx")
        return
    
    print(f"📂 {len(excel_files)} Excel dosyası bulundu:")
    for f in excel_files:
        print(f"   - {f.name}")
    
    # Database bağlantısı
    db = SessionLocal()
    
    total_universities = 0
    total_departments = 0
    total_yearly_stats = 0
    
    try:
        # Her dosyayı işle
        for file_path in excel_files:
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
