import sys
sys.path.append('/app')

from database import SessionLocal
from models.university import University

db = SessionLocal()

try:
    universities = db.query(University).all()
    
    for uni in universities:
        if uni.university_type == 'Devlet':
            uni.university_type = 'devlet'
            print(f"✅ {uni.name}: Devlet -> devlet")
        elif uni.university_type == 'Vakıf':
            uni.university_type = 'vakif'
            print(f"✅ {uni.name}: Vakıf -> vakif")
    
    db.commit()
    print(f"\n🎉 {len(universities)} üniversite güncellendi!")
    
except Exception as e:
    print(f"❌ Hata: {e}")
    db.rollback()
finally:
    db.close()

