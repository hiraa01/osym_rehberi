"""
Sadece 2024 ve 2025 verilerini yükle (hızlı test için)
"""
import sys
sys.path.append('/app')

import pandas as pd
from pathlib import Path
from sqlalchemy.orm import Session
from database import SessionLocal
from models.university import University, Department

DATA_DIR = Path('/app/data')

def clean_numeric(value):
    if pd.isna(value):
        return 0.0
    if isinstance(value, str):
        value = value.replace(',', '.').replace(' ', '').strip()
        try:
            return float(value)
        except:
            return 0.0
    return float(value)

db = SessionLocal()

try:
    print("🚀 2022-2025 Verileri Yükleniyor (4 Yıl Lisans)...")
    
    files = [
        '2022_yerlestirme_l.xlsx',
        '2023_yerlestirme_l.xlsx', 
        '2024_yerlestirme_l.xlsx',
        '2025_yerlestirme_l.xlsx'
    ]
    
    total_uni = 0
    total_dept = 0
    
    for filename in files:
        file_path = DATA_DIR / filename
        if not file_path.exists():
            print(f"⚠️  {filename} bulunamadı, atlanıyor")
            continue
            
        print(f"\n📁 {filename} işleniyor...")
        
        df = pd.read_excel(file_path, header=2)
        
        # Typo düzelt
        if 'Üniversites Türü' in df.columns:
            df.rename(columns={'Üniversites Türü': 'Üniversite Türü'}, inplace=True)
        
        print(f"   📊 {len(df)} satır okundu")
        
        for idx, row in df.iterrows():
            try:
                # Üniversite
                uni_name_raw = str(row.get('Üniversite Adı', '')).strip()
                if not uni_name_raw or uni_name_raw == 'nan':
                    continue
                
                # Şehir çıkar
                if '(' in uni_name_raw:
                    uni_name = uni_name_raw[:uni_name_raw.rfind('(')].strip()
                    city = uni_name_raw[uni_name_raw.rfind('(')+1:uni_name_raw.rfind(')')].strip().title()
                else:
                    uni_name = uni_name_raw
                    city = 'Bilinmiyor'
                
                uni_type_raw = str(row.get('Üniversite Türü', 'DEVLET')).upper()
                uni_type = 'vakif' if 'VAKIF' in uni_type_raw else 'devlet'
                
                # Üniversite var mı?
                uni = db.query(University).filter(University.name == uni_name).first()
                if not uni:
                    uni = University(
                        name=uni_name,
                        city=city,
                        university_type=uni_type,
                        website=f"https://{uni_name[:20].lower().replace(' ','')}.edu.tr"
                    )
                    db.add(uni)
                    db.flush()
                    total_uni += 1
                
                # Bölüm
                dept_name = str(row.get('Program Adı', '')).strip()
                if not dept_name or dept_name == 'nan':
                    continue
                
                field_type_raw = str(row.get('Puan Türü', 'SAY')).upper()
                # ✅ CRITICAL FIX: TYT kontrolü önce yapılmalı
                if 'TYT' in field_type_raw:
                    field_type = 'TYT'
                elif 'EA' in field_type_raw:
                    field_type = 'EA'
                elif 'SÖZ' in field_type_raw or 'TS' in field_type_raw:
                    field_type = 'SÖZ'
                elif 'DİL' in field_type_raw:
                    field_type = 'DİL'
                else:
                    field_type = 'SAY'
                
                language = 'Turkish'
                if 'İngilizce' in dept_name or 'English' in dept_name:
                    language = 'English'
                
                # ✅ CRITICAL FIX: Duration ve degree_type mantığı
                dept_name_upper = dept_name.upper()
                is_onlisans = False
                
                # 1. Field type kontrolü: TYT = Önlisans
                if field_type == 'TYT':
                    is_onlisans = True
                
                # 2. Bölüm adı kontrolü
                onlisans_keywords = ['ÖNLİSANS', 'ÖN LİSANS', '2 YILLIK', '2 YIL', 'MYO', 
                                     'MESLEK YÜKSEKOKULU', 'MESLEK YÜKSEK OKULU', 'AÖF', 'AÇIKÖĞRETİM']
                if any(keyword in dept_name_upper for keyword in onlisans_keywords):
                    is_onlisans = True
                    if field_type != 'TYT':
                        field_type = 'TYT'
                
                # 3. Lisans bölümleri kontrolü
                lisans_keywords = ['TIP', 'MÜHENDİSLİK', 'HUKUK', 'MİMARLIK', 'DİŞ HEKİMLİĞİ',
                                   'ECZACILIK', 'VETERİNER', 'ZİRAAT', 'ORMAN']
                if any(keyword in dept_name_upper for keyword in lisans_keywords):
                    is_onlisans = False
                    if field_type == 'TYT':
                        field_type = 'SAY'
                
                # Duration ve degree_type belirleme
                if is_onlisans:
                    duration = 2
                    degree_type = 'Associate'
                else:
                    if 'TIP' in dept_name_upper:
                        duration = 6
                    elif 'DİŞ HEKİMLİĞİ' in dept_name_upper or 'DİŞHEKİMLİĞİ' in dept_name_upper:
                        duration = 5
                    elif 'VETERİNER' in dept_name_upper:
                        duration = 5
                    elif 'MİMARLIK' in dept_name_upper:
                        duration = 5
                    else:
                        duration = 4
                    degree_type = 'Bachelor'
                
                min_score = clean_numeric(row.get('En Küçük Puan', 0))
                quota = int(clean_numeric(row.get('Kontenjan', 0)))
                
                # Bölüm var mı?
                existing = db.query(Department).filter(
                    Department.university_id == uni.id,
                    Department.name == dept_name,
                    Department.field_type == field_type
                ).first()
                
                if not existing:
                    dept = Department(
                        university_id=uni.id,
                        name=dept_name,
                        field_type=field_type,
                        language=language,
                        duration=duration,  # ✅ Artık doğru hesaplanıyor
                        degree_type=degree_type,  # ✅ Associate veya Bachelor
                        quota=quota,
                        min_score=min_score if min_score > 0 else None
                    )
                    db.add(dept)
                    total_dept += 1
                
                if (idx + 1) % 500 == 0:
                    db.commit()
                    print(f"   ⏳ {idx + 1} satır işlendi...")
            
            except Exception as e:
                continue
        
        db.commit()
        print(f"   ✅ Tamamlandı!")
    
    print(f"\n{'='*70}")
    print(f"✅ BAŞARILI!")
    print(f"{'='*70}")
    print(f"📊 {total_uni} üniversite, {total_dept} bölüm eklendi")
    
    # Toplam
    final_uni = db.query(University).count()
    final_dept = db.query(Department).count()
    print(f"💾 Toplam Database: {final_uni} üniversite, {final_dept} bölüm")

except Exception as e:
    print(f"❌ Hata: {e}")
    import traceback
    traceback.print_exc()
    db.rollback()
finally:
    db.close()

