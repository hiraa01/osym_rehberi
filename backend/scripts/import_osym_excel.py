"""
ÖSYM Excel Dosyalarından Yerleştirme Verilerini İçe Aktar

KULLANIM:
1. ÖSYM'den Excel dosyalarını indir (örn: 2024_yerlestirme.xlsx)
2. backend/data/ klasörüne koy
3. Bu scripti çalıştır: python scripts/import_osym_excel.py

NOT: ÖSYM Excel formatı yıllara göre değişebilir, bu yüzden 
kolonları kontrol edip gerekirse ayarla.
"""
import sys
import os
sys.path.append('/app')

import pandas as pd
from pathlib import Path
from sqlalchemy.orm import Session
from database import SessionLocal
from models.university import University, Department

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
    """Alan türünü normalize et (SAY/EA/SÖZ/DİL)"""
    if pd.isna(value):
        return 'SAY'
    
    value = str(value).upper().strip()
    # ÖSYM'de farklı yazılışlar olabilir
    if 'SAY' in value or 'TM' in value:
        return 'SAY'
    elif 'EA' in value:
        return 'EA'
    elif 'SÖZ' in value or 'TS' in value:
        return 'SÖZ'
    elif 'DİL' in value or 'YDİL' in value:
        return 'DİL'
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
    """Tek bir Excel dosyasını import et"""
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
            return 0, 0
        
        # Üniversite ve Bölüm sayaçları
        new_universities = 0
        new_departments = 0
        
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
                
                # Bölüm bilgilerini al
                dept_name = str(row.get('Program Adı', '')).strip()
                field_type = normalize_field_type(row.get('Puan Türü', 'SAY'))
                
                # Dil bilgisini program adından çıkar (İngilizce, %30 İngilizce vs.)
                language = 'Turkish'
                if 'İngilizce' in dept_name or 'English' in dept_name:
                    language = 'English'
                elif '%' in dept_name and ('İngilizce' in dept_name or 'English' in dept_name):
                    language = 'Partial English'
                
                duration = 4  # Varsayılan (Excel'de yok, lisans genelde 4 yıl)
                quota = int(clean_numeric_value(row.get('Kontenjan', 0)))
                placed_students = int(clean_numeric_value(row.get('Yerleşen', 0)))
                min_score = clean_numeric_value(row.get('En Küçük Puan', 0))
                # En Büyük Puan'ı da kullanabiliriz ama şimdilik min_rank için  0 kullanıyoruz
                min_rank = 0  # Excel'de yok
                
                if not dept_name or dept_name == 'nan':
                    continue
                
                # Bölüm var mı kontrol et (aynı üniversite, aynı bölüm adı)
                existing_dept = db.query(Department).filter(
                    Department.university_id == university.id,
                    Department.name == dept_name,
                    Department.field_type == field_type
                ).first()
                
                if existing_dept:
                    # Güncelle (yeni yılın verileri daha güncel olabilir)
                    existing_dept.min_score = min_score if min_score > 0 else existing_dept.min_score
                    existing_dept.min_rank = min_rank if min_rank > 0 else existing_dept.min_rank
                    existing_dept.quota = quota if quota > 0 else existing_dept.quota
                else:
                    # Yeni bölüm ekle
                    department = Department(
                        university_id=university.id,
                        name=dept_name,
                        field_type=field_type,
                        language=language,
                        duration=duration,
                        degree_type='Bachelor',  # Excel'de belirtilmiyorsa varsayılan
                        quota=quota,
                        min_score=min_score if min_score > 0 else None,
                        min_rank=min_rank if min_rank > 0 else None,
                    )
                    db.add(department)
                    new_departments += 1
                
                # Her 1000 satırda bir commit (performans için)
                if (idx + 1) % 1000 == 0:
                    db.commit()
                    print(f"   ⏳ {idx + 1} satır işlendi...")
            
            except Exception as e:
                print(f"   ⚠️  Satır {idx} hatası: {e}")
                continue
        
        # Son commit
        db.commit()
        print(f"   ✅ {new_universities} yeni üniversite, {new_departments} yeni bölüm eklendi!")
        return new_universities, new_departments
        
    except Exception as e:
        print(f"   ❌ Dosya işleme hatası: {e}")
        db.rollback()
        return 0, 0


def main():
    """Ana import fonksiyonu"""
    print("=" * 70)
    print("ÖSYM EXCEL DOSYALARINI İÇE AKTAR")
    print("=" * 70)
    
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
        print(f"   Örnek: 2024_yerlestirme.xlsx")
        return
    
    print(f"📂 {len(excel_files)} Excel dosyası bulundu:")
    for f in excel_files:
        print(f"   - {f.name}")
    
    # Database bağlantısı
    db = SessionLocal()
    
    total_universities = 0
    total_departments = 0
    
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
            
            unis, depts = import_excel_file(file_path, year, db)
            total_universities += unis
            total_departments += depts
        
        print("\n" + "=" * 70)
        print("✅ İMPORT TAMAMLANDI!")
        print("=" * 70)
        print(f"📊 Toplam: {total_universities} üniversite, {total_departments} bölüm eklendi")
        
        # Database istatistikleri
        uni_count = db.query(University).count()
        dept_count = db.query(Department).count()
        print(f"💾 Database'de: {uni_count} üniversite, {dept_count} bölüm")
        print("=" * 70)
        
    except Exception as e:
        print(f"\n❌ HATA: {e}")
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    main()

