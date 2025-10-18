import sys
sys.path.append('/app')

from database import SessionLocal
from models.university import University, Department

db = SessionLocal()

try:
    uni_count = db.query(University).count()
    if uni_count > 0:
        print(f"✅ Zaten {uni_count} üniversite var")
        exit(0)
    
    print("🎓 Veri ekleniyor...")
    
    universities = [
        University(name="İstanbul Teknik Üniversitesi", city="İstanbul", university_type="Devlet"),
        University(name="Boğaziçi Üniversitesi", city="İstanbul", university_type="Devlet"),
        University(name="Orta Doğu Teknik Üniversitesi", city="Ankara", university_type="Devlet"),
        University(name="Hacettepe Üniversitesi", city="Ankara", university_type="Devlet"),
        University(name="Ege Üniversitesi", city="İzmir", university_type="Devlet"),
    ]
    
    for uni in universities:
        db.add(uni)
    db.flush()
    
    departments = [
        Department(university_id=1, name="Bilgisayar Mühendisliği", field_type="SAY", min_score=510.5, quota=150),
        Department(university_id=2, name="Bilgisayar Mühendisliği", field_type="SAY", min_score=525.8, quota=100),
        Department(university_id=3, name="Bilgisayar Mühendisliği", field_type="SAY", min_score=520.3, quota=130),
        Department(university_id=4, name="Tıp", field_type="SAY", min_score=545.9, quota=180),
        Department(university_id=5, name="Tıp", field_type="SAY", min_score=535.2, quota=160),
    ]
    
    for dept in departments:
        db.add(dept)
    
    db.commit()
    print(f"✅ {len(universities)} üniversite ve {len(departments)} bölüm eklendi!")
    
except Exception as e:
    print(f"❌ Hata: {e}")
    import traceback
    traceback.print_exc()
    db.rollback()
finally:
    db.close()

