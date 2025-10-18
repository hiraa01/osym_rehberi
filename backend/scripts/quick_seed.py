"""
Hızlı seed script - University ve Department modellerine veri ekler
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy.orm import Session
from database import SessionLocal
from models.university import University, Department

def seed_data():
    db = SessionLocal()
    
    try:
        # Var mı kontrol et
        uni_count = db.query(University).count()
        if uni_count > 0:
            print(f"✅ Zaten {uni_count} üniversite var")
            return
        
        print("🎓 Üniversiteler ekleniyor...")
        
        # Üniversiteler
        universities = [
            University(
                name="İstanbul Teknik Üniversitesi",
                city="İstanbul",
                university_type="Devlet",
                website="https://itu.edu.tr"
            ),
            University(
                name="Boğaziçi Üniversitesi",
                city="İstanbul",
                university_type="Devlet",
                website="https://boun.edu.tr"
            ),
            University(
                name="Orta Doğu Teknik Üniversitesi",
                city="Ankara",
                university_type="Devlet",
                website="https://odtu.edu.tr"
            ),
            University(
                name="Hacettepe Üniversitesi",
                city="Ankara",
                university_type="Devlet",
                website="https://hacettepe.edu.tr"
            ),
            University(
                name="Ege Üniversitesi",
                city="İzmir",
                university_type="Devlet",
                website="https://ege.edu.tr"
            ),
        ]
        
        for uni in universities:
            db.add(uni)
        db.flush()
        
        print(f"✅ {len(universities)} üniversite eklendi")
        print("📚 Bölümler ekleniyor...")
        
        # Bölümler
        departments = [
            # İTÜ
            Department(
                university_id=1,
                name="Bilgisayar Mühendisliği",
                field_type="SAY",
                min_score=510.5,
                min_rank=12000,
                quota=150
            ),
            Department(
                university_id=1,
                name="Elektrik-Elektronik Mühendisliği",
                field_type="SAY",
                min_score=505.2,
                min_rank=15000,
                quota=140
            ),
            # Boğaziçi
            Department(
                university_id=2,
                name="Bilgisayar Mühendisliği",
                field_type="SAY",
                min_score=525.8,
                min_rank=5000,
                quota=100
            ),
            Department(
                university_id=2,
                name="İşletme",
                field_type="EA",
                min_score=480.5,
                min_rank=8000,
                quota=120
            ),
            # ODTÜ
            Department(
                university_id=3,
                name="Bilgisayar Mühendisliği",
                field_type="SAY",
                min_score=520.3,
                min_rank=7000,
                quota=130
            ),
            Department(
                university_id=3,
                name="Makine Mühendisliği",
                field_type="SAY",
                min_score=495.1,
                min_rank=20000,
                quota=140
            ),
            # Hacettepe
            Department(
                university_id=4,
                name="Tıp",
                field_type="SAY",
                min_score=545.9,
                min_rank=2000,
                quota=180
            ),
            Department(
                university_id=4,
                name="Hukuk",
                field_type="SÖZ",
                min_score=470.5,
                min_rank=5000,
                quota=100
            ),
            # Ege
            Department(
                university_id=5,
                name="Tıp",
                field_type="SAY",
                min_score=535.2,
                min_rank=3500,
                quota=160
            ),
            Department(
                university_id=5,
                name="Psikoloji",
                field_type="EA",
                min_score=450.8,
                min_rank=12000,
                quota=80
            ),
        ]
        
        for dept in departments:
            db.add(dept)
        
        db.commit()
        print(f"✅ {len(departments)} bölüm eklendi")
        print("\n🎉 Başarıyla tamamlandı!")
        
    except Exception as e:
        print(f"❌ Hata: {e}")
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    seed_data()

