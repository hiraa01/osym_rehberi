"""Hızlı Test İmport - Sadece 1 dosya, 1000 satır"""
import sys
sys.path.append('/app')

import pandas as pd
from database import SessionLocal
from models.university import University, Department

db = SessionLocal()

try:
    print("🧪 Hızlı Test Başlıyor...")
    print("📁 Sadece 2024_yerlestirme_l.xlsx, ilk 1000 satır")
    
    # Excel'i oku
    df = pd.read_excel('/app/data/2024_yerlestirme_l.xlsx', header=2, nrows=1000)
    print(f"✅ {len(df)} satır okundu")
    
    uni_count = 0
    dept_count = 0
    
    for idx, row in df.iterrows():
        # Üniversite
        uni_name_raw = str(row.get('Üniversite Adı', '')).strip()
        if not uni_name_raw or uni_name_raw == 'nan':
            continue
            
        if '(' in uni_name_raw:
            uni_name = uni_name_raw[:uni_name_raw.rfind('(')].strip()
            city = uni_name_raw[uni_name_raw.rfind('(')+1:uni_name_raw.rfind(')')].strip()
        else:
            uni_name = uni_name_raw
            city = 'Bilinmiyor'
        
        uni_type_raw = str(row.get('Üniversite Türü', 'DEVLET')).upper()
        uni_type = 'vakif' if 'VAKIF' in uni_type_raw else 'devlet'
        
        # Üniversite var mı?
        uni = db.query(University).filter(University.name == uni_name).first()
        if not uni:
            uni = University(name=uni_name, city=city, university_type=uni_type, website=f"https://{uni_name[:20].lower()}.edu.tr")
            db.add(uni)
            db.flush()
            uni_count += 1
        
        # Bölüm
        dept_name = str(row.get('Program Adı', '')).strip()
        if not dept_name or dept_name == 'nan':
            continue
        
        field_type_raw = str(row.get('Puan Türü', 'SAY')).upper()
        if 'EA' in field_type_raw:
            field_type = 'EA'
        elif 'SÖZ' in field_type_raw or 'TS' in field_type_raw:
            field_type = 'SÖZ'
        elif 'DİL' in field_type_raw:
            field_type = 'DİL'
        else:
            field_type = 'SAY'
        
        min_score = float(row.get('En Küçük Puan', 0)) if pd.notna(row.get('En Küçük Puan')) else 0
        quota = int(row.get('Kontenjan', 0)) if pd.notna(row.get('Kontenjan')) else 0
        
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
                language='Turkish',
                duration=4,
                degree_type='Bachelor',
                quota=quota,
                min_score=min_score if min_score > 0 else None
            )
            db.add(dept)
            dept_count += 1
        
        if (idx + 1) % 100 == 0:
            db.commit()
            print(f"⏳ {idx + 1} satır işlendi...")
    
    db.commit()
    print(f"\n✅ Tamamlandı!")
    print(f"📊 {uni_count} yeni üniversite, {dept_count} yeni bölüm eklendi")
    
    # Toplam göster
    total_uni = db.query(University).count()
    total_dept = db.query(Department).count()
    print(f"💾 Toplam Database: {total_uni} üniversite, {total_dept} bölüm")

except Exception as e:
    print(f"❌ Hata: {e}")
    import traceback
    traceback.print_exc()
    db.rollback()
finally:
    db.close()

