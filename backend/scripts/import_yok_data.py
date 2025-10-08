#!/usr/bin/env python3
"""
YÖK Atlas verilerini import etmek için script
Bu script örnek veriler oluşturur ve veritabanına ekler
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy.orm import Session
from database import get_db, create_tables
from models.university import University, Department
import json

def create_sample_universities():
    """Örnek üniversite verilerini oluştur"""
    universities = [
        {
            "name": "İstanbul Teknik Üniversitesi",
            "city": "İstanbul",
            "university_type": "Devlet",
            "website": "https://www.itu.edu.tr",
            "description": "Türkiye'nin en köklü teknik üniversitesi",
            "is_active": True
        },
        {
            "name": "Boğaziçi Üniversitesi",
            "city": "İstanbul",
            "university_type": "Devlet",
            "website": "https://www.boun.edu.tr",
            "description": "Türkiye'nin en prestijli üniversitelerinden biri",
            "is_active": True
        },
        {
            "name": "Orta Doğu Teknik Üniversitesi",
            "city": "Ankara",
            "university_type": "Devlet",
            "website": "https://www.metu.edu.tr",
            "description": "Türkiye'nin önde gelen teknik üniversitesi",
            "is_active": True
        },
        {
            "name": "Koç Üniversitesi",
            "city": "İstanbul",
            "university_type": "Vakıf",
            "website": "https://www.ku.edu.tr",
            "description": "Türkiye'nin önde gelen vakıf üniversitesi",
            "is_active": True
        },
        {
            "name": "Sabancı Üniversitesi",
            "city": "İstanbul",
            "university_type": "Vakıf",
            "website": "https://www.sabanciuniv.edu",
            "description": "İnovatif eğitim anlayışı ile öne çıkan üniversite",
            "is_active": True
        },
        {
            "name": "Bilkent Üniversitesi",
            "city": "Ankara",
            "university_type": "Vakıf",
            "website": "https://www.bilkent.edu.tr",
            "description": "Türkiye'nin önde gelen vakıf üniversitesi",
            "is_active": True
        },
        {
            "name": "Hacettepe Üniversitesi",
            "city": "Ankara",
            "university_type": "Devlet",
            "website": "https://www.hacettepe.edu.tr",
            "description": "Türkiye'nin önde gelen devlet üniversitesi",
            "is_active": True
        },
        {
            "name": "Ege Üniversitesi",
            "city": "İzmir",
            "university_type": "Devlet",
            "website": "https://www.ege.edu.tr",
            "description": "İzmir'in köklü devlet üniversitesi",
            "is_active": True
        },
        {
            "name": "Dokuz Eylül Üniversitesi",
            "city": "İzmir",
            "university_type": "Devlet",
            "website": "https://www.deu.edu.tr",
            "description": "İzmir'in büyük devlet üniversitesi",
            "is_active": True
        },
        {
            "name": "Uludağ Üniversitesi",
            "city": "Bursa",
            "university_type": "Devlet",
            "website": "https://www.uludag.edu.tr",
            "description": "Bursa'nın köklü devlet üniversitesi",
            "is_active": True
        }
    ]
    return universities

def create_sample_departments():
    """Örnek bölüm verilerini oluştur"""
    departments = [
        # İTÜ Bölümleri
        {
            "name": "Bilgisayar Mühendisliği",
            "field_type": "SAY",
            "university_id": 1,
            "min_score": 450.0,
            "min_rank": 1500,
            "quota": 120,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "Türkçe",
            "description": "Bilgisayar mühendisliği programı"
        },
        {
            "name": "Elektrik Mühendisliği",
            "field_type": "SAY",
            "university_id": 1,
            "min_score": 440.0,
            "min_rank": 2000,
            "quota": 100,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "Türkçe",
            "description": "Elektrik mühendisliği programı"
        },
        {
            "name": "Makine Mühendisliği",
            "field_type": "SAY",
            "university_id": 1,
            "min_score": 430.0,
            "min_rank": 2500,
            "quota": 150,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "Türkçe",
            "description": "Makine mühendisliği programı"
        },
        
        # Boğaziçi Üniversitesi Bölümleri
        {
            "name": "Bilgisayar Mühendisliği",
            "field_type": "SAY",
            "university_id": 2,
            "min_score": 480.0,
            "min_rank": 800,
            "quota": 80,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "İngilizce",
            "description": "Bilgisayar mühendisliği programı (İngilizce)"
        },
        {
            "name": "Endüstri Mühendisliği",
            "field_type": "EA",
            "university_id": 2,
            "min_score": 470.0,
            "min_rank": 1000,
            "quota": 60,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "İngilizce",
            "description": "Endüstri mühendisliği programı (İngilizce)"
        },
        {
            "name": "İşletme",
            "field_type": "EA",
            "university_id": 2,
            "min_score": 460.0,
            "min_rank": 1200,
            "quota": 100,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "İngilizce",
            "description": "İşletme programı (İngilizce)"
        },
        
        # ODTÜ Bölümleri
        {
            "name": "Bilgisayar Mühendisliği",
            "field_type": "SAY",
            "university_id": 3,
            "min_score": 475.0,
            "min_rank": 900,
            "quota": 100,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "İngilizce",
            "description": "Bilgisayar mühendisliği programı (İngilizce)"
        },
        {
            "name": "Endüstri Mühendisliği",
            "field_type": "EA",
            "university_id": 3,
            "min_score": 465.0,
            "min_rank": 1100,
            "quota": 80,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "İngilizce",
            "description": "Endüstri mühendisliği programı (İngilizce)"
        },
        
        # Koç Üniversitesi Bölümleri
        {
            "name": "Bilgisayar Mühendisliği",
            "field_type": "SAY",
            "university_id": 4,
            "min_score": 420.0,
            "min_rank": 2000,
            "quota": 60,
            "tuition_fee": 85000.0,
            "has_scholarship": True,
            "language": "İngilizce",
            "description": "Bilgisayar mühendisliği programı (İngilizce)"
        },
        {
            "name": "İşletme",
            "field_type": "EA",
            "university_id": 4,
            "min_score": 410.0,
            "min_rank": 2500,
            "quota": 80,
            "tuition_fee": 85000.0,
            "has_scholarship": True,
            "language": "İngilizce",
            "description": "İşletme programı (İngilizce)"
        },
        {
            "name": "Psikoloji",
            "field_type": "EA",
            "university_id": 4,
            "min_score": 400.0,
            "min_rank": 3000,
            "quota": 40,
            "tuition_fee": 85000.0,
            "has_scholarship": True,
            "language": "İngilizce",
            "description": "Psikoloji programı (İngilizce)"
        },
        
        # Sabancı Üniversitesi Bölümleri
        {
            "name": "Bilgisayar Mühendisliği",
            "field_type": "SAY",
            "university_id": 5,
            "min_score": 430.0,
            "min_rank": 1800,
            "quota": 50,
            "tuition_fee": 90000.0,
            "has_scholarship": True,
            "language": "İngilizce",
            "description": "Bilgisayar mühendisliği programı (İngilizce)"
        },
        {
            "name": "Endüstri Mühendisliği",
            "field_type": "EA",
            "university_id": 5,
            "min_score": 420.0,
            "min_rank": 2200,
            "quota": 60,
            "tuition_fee": 90000.0,
            "has_scholarship": True,
            "language": "İngilizce",
            "description": "Endüstri mühendisliği programı (İngilizce)"
        },
        {
            "name": "Psikoloji",
            "field_type": "EA",
            "university_id": 5,
            "min_score": 410.0,
            "min_rank": 2800,
            "quota": 30,
            "tuition_fee": 90000.0,
            "has_scholarship": True,
            "language": "İngilizce",
            "description": "Psikoloji programı (İngilizce)"
        },
        
        # Bilkent Üniversitesi Bölümleri
        {
            "name": "Bilgisayar Mühendisliği",
            "field_type": "SAY",
            "university_id": 6,
            "min_score": 440.0,
            "min_rank": 1600,
            "quota": 70,
            "tuition_fee": 80000.0,
            "has_scholarship": True,
            "language": "İngilizce",
            "description": "Bilgisayar mühendisliği programı (İngilizce)"
        },
        {
            "name": "Elektrik Mühendisliği",
            "field_type": "SAY",
            "university_id": 6,
            "min_score": 430.0,
            "min_rank": 1900,
            "quota": 60,
            "tuition_fee": 80000.0,
            "has_scholarship": True,
            "language": "İngilizce",
            "description": "Elektrik mühendisliği programı (İngilizce)"
        },
        
        # Hacettepe Üniversitesi Bölümleri
        {
            "name": "Tıp",
            "field_type": "SAY",
            "university_id": 7,
            "min_score": 520.0,
            "min_rank": 200,
            "quota": 200,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "Türkçe",
            "description": "Tıp programı"
        },
        {
            "name": "Bilgisayar Mühendisliği",
            "field_type": "SAY",
            "university_id": 7,
            "min_score": 420.0,
            "min_rank": 3000,
            "quota": 100,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "Türkçe",
            "description": "Bilgisayar mühendisliği programı"
        },
        
        # Ege Üniversitesi Bölümleri
        {
            "name": "Tıp",
            "field_type": "SAY",
            "university_id": 8,
            "min_score": 510.0,
            "min_rank": 300,
            "quota": 180,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "Türkçe",
            "description": "Tıp programı"
        },
        {
            "name": "Bilgisayar Mühendisliği",
            "field_type": "SAY",
            "university_id": 8,
            "min_score": 400.0,
            "min_rank": 4000,
            "quota": 120,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "Türkçe",
            "description": "Bilgisayar mühendisliği programı"
        },
        
        # Dokuz Eylül Üniversitesi Bölümleri
        {
            "name": "Tıp",
            "field_type": "SAY",
            "university_id": 9,
            "min_score": 505.0,
            "min_rank": 400,
            "quota": 160,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "Türkçe",
            "description": "Tıp programı"
        },
        {
            "name": "Bilgisayar Mühendisliği",
            "field_type": "SAY",
            "university_id": 9,
            "min_score": 390.0,
            "min_rank": 5000,
            "quota": 100,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "Türkçe",
            "description": "Bilgisayar mühendisliği programı"
        },
        
        # Uludağ Üniversitesi Bölümleri
        {
            "name": "Tıp",
            "field_type": "SAY",
            "university_id": 10,
            "min_score": 500.0,
            "min_rank": 500,
            "quota": 140,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "Türkçe",
            "description": "Tıp programı"
        },
        {
            "name": "Bilgisayar Mühendisliği",
            "field_type": "SAY",
            "university_id": 10,
            "min_score": 380.0,
            "min_rank": 6000,
            "quota": 80,
            "tuition_fee": 0.0,
            "has_scholarship": False,
            "language": "Türkçe",
            "description": "Bilgisayar mühendisliği programı"
        }
    ]
    return departments

def import_data():
    """Verileri veritabanına import et"""
    print("Veritabanı tabloları oluşturuluyor...")
    create_tables()
    
    db = next(get_db())
    
    try:
        print("Üniversite verileri import ediliyor...")
        universities_data = create_sample_universities()
        
        for uni_data in universities_data:
            university = University(**uni_data)
            db.add(university)
        
        db.commit()
        print(f"{len(universities_data)} üniversite eklendi.")
        
        print("Bölüm verileri import ediliyor...")
        departments_data = create_sample_departments()
        
        for dept_data in departments_data:
            department = Department(**dept_data)
            db.add(department)
        
        db.commit()
        print(f"{len(departments_data)} bölüm eklendi.")
        
        print("Veri import işlemi tamamlandı!")
        
    except Exception as e:
        print(f"Hata oluştu: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    import_data()
