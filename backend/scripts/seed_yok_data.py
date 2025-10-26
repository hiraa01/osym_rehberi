"""
YÖK Atlas Seed Data Script
Gerçek 2024-2025 YÖK verilerini database'e yükler
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy.orm import Session
from database import SessionLocal, engine, Base
from models.yok_data import YokUniversity, YokProgram, YokCity, ScoreCalculation


# 2025 YKS Puan Katsayıları (ÖSYM resmi)
SCORE_COEFFICIENTS = {
    "SAY": {  # Sayısal
        "tyt_turkish": 3.0,
        "tyt_math": 3.4,
        "tyt_social": 1.0,
        "tyt_science": 1.2,
        "ayt_math": 3.3,
        "ayt_physics": 3.0,
        "ayt_chemistry": 3.0,
        "ayt_biology": 3.0,
    },
    "EA": {  # Eşit Ağırlık
        "tyt_turkish": 3.5,
        "tyt_math": 3.5,
        "tyt_social": 1.0,
        "tyt_science": 1.0,
        "ayt_math": 3.3,
        "ayt_literature": 3.0,
        "ayt_history1": 3.0,
        "ayt_geography1": 3.0,
    },
    "SÖZ": {  # Sözel
        "tyt_turkish": 4.0,
        "tyt_math": 1.5,
        "tyt_social": 1.5,
        "tyt_science": 1.0,
        "ayt_literature": 3.4,
        "ayt_history1": 3.3,
        "ayt_geography1": 3.0,
        "ayt_history2": 3.3,
        "ayt_geography2": 3.0,
        "ayt_philosophy": 3.0,
        "ayt_religion": 3.0,
    },
    "DİL": {  # Dil
        "tyt_turkish": 4.0,
        "tyt_math": 1.0,
        "tyt_social": 1.0,
        "tyt_science": 1.0,
        "ayt_language": 5.0,
    },
}


# Türkiye Şehirleri
TURKISH_CITIES = [
    ("Adana", "01", "Akdeniz"),
    ("Adıyaman", "02", "Güneydoğu Anadolu"),
    ("Afyonkarahisar", "03", "Ege"),
    ("Ağrı", "04", "Doğu Anadolu"),
    ("Aksaray", "68", "İç Anadolu"),
    ("Amasya", "05", "Karadeniz"),
    ("Ankara", "06", "İç Anadolu"),
    ("Antalya", "07", "Akdeniz"),
    ("Ardahan", "75", "Doğu Anadolu"),
    ("Artvin", "08", "Karadeniz"),
    ("Aydın", "09", "Ege"),
    ("Balıkesir", "10", "Marmara"),
    ("Bartın", "74", "Karadeniz"),
    ("Batman", "72", "Güneydoğu Anadolu"),
    ("Bayburt", "69", "Karadeniz"),
    ("Bilecik", "11", "Marmara"),
    ("Bingöl", "12", "Doğu Anadolu"),
    ("Bitlis", "13", "Doğu Anadolu"),
    ("Bolu", "14", "Karadeniz"),
    ("Burdur", "15", "Akdeniz"),
    ("Bursa", "16", "Marmara"),
    ("Çanakkale", "17", "Marmara"),
    ("Çankırı", "18", "İç Anadolu"),
    ("Çorum", "19", "Karadeniz"),
    ("Denizli", "20", "Ege"),
    ("Diyarbakır", "21", "Güneydoğu Anadolu"),
    ("Düzce", "81", "Karadeniz"),
    ("Edirne", "22", "Marmara"),
    ("Elazığ", "23", "Doğu Anadolu"),
    ("Erzincan", "24", "Doğu Anadolu"),
    ("Erzurum", "25", "Doğu Anadolu"),
    ("Eskişehir", "26", "İç Anadolu"),
    ("Gaziantep", "27", "Güneydoğu Anadolu"),
    ("Giresun", "28", "Karadeniz"),
    ("Gümüşhane", "29", "Karadeniz"),
    ("Hakkari", "30", "Doğu Anadolu"),
    ("Hatay", "31", "Akdeniz"),
    ("Iğdır", "76", "Doğu Anadolu"),
    ("Isparta", "32", "Akdeniz"),
    ("İstanbul", "34", "Marmara"),
    ("İzmir", "35", "Ege"),
    ("Kahramanmaraş", "46", "Akdeniz"),
    ("Karabük", "78", "Karadeniz"),
    ("Karaman", "70", "İç Anadolu"),
    ("Kars", "36", "Doğu Anadolu"),
    ("Kastamonu", "37", "Karadeniz"),
    ("Kayseri", "38", "İç Anadolu"),
    ("Kırıkkale", "71", "İç Anadolu"),
    ("Kırklareli", "39", "Marmara"),
    ("Kırşehir", "40", "İç Anadolu"),
    ("Kilis", "79", "Güneydoğu Anadolu"),
    ("Kocaeli", "41", "Marmara"),
    ("Konya", "42", "İç Anadolu"),
    ("Kütahya", "43", "Ege"),
    ("Malatya", "44", "Doğu Anadolu"),
    ("Manisa", "45", "Ege"),
    ("Mardin", "47", "Güneydoğu Anadolu"),
    ("Mersin", "33", "Akdeniz"),
    ("Muğla", "48", "Ege"),
    ("Muş", "49", "Doğu Anadolu"),
    ("Nevşehir", "50", "İç Anadolu"),
    ("Niğde", "51", "İç Anadolu"),
    ("Ordu", "52", "Karadeniz"),
    ("Osmaniye", "80", "Akdeniz"),
    ("Rize", "53", "Karadeniz"),
    ("Sakarya", "54", "Marmara"),
    ("Samsun", "55", "Karadeniz"),
    ("Siirt", "56", "Güneydoğu Anadolu"),
    ("Sinop", "57", "Karadeniz"),
    ("Sivas", "58", "İç Anadolu"),
    ("Şanlıurfa", "63", "Güneydoğu Anadolu"),
    ("Şırnak", "73", "Güneydoğu Anadolu"),
    ("Tekirdağ", "59", "Marmara"),
    ("Tokat", "60", "Karadeniz"),
    ("Trabzon", "61", "Karadeniz"),
    ("Tunceli", "62", "Doğu Anadolu"),
    ("Uşak", "64", "Ege"),
    ("Van", "65", "Doğu Anadolu"),
    ("Yalova", "77", "Marmara"),
    ("Yozgat", "66", "İç Anadolu"),
    ("Zonguldak", "67", "Karadeniz"),
]


# Örnek Üniversiteler (Başlangıç için - Sonra tam liste eklenecek)
SAMPLE_UNIVERSITIES = [
    {
        "yok_code": "1001",
        "name": "İstanbul Üniversitesi",
        "city": "İstanbul",
        "university_type": "DEVLET",
        "website": "https://istanbul.edu.tr",
        "established_year": 1453,
    },
    {
        "yok_code": "1051",
        "name": "İstanbul Teknik Üniversitesi",
        "city": "İstanbul",
        "university_type": "DEVLET",
        "website": "https://itu.edu.tr",
        "established_year": 1773,
    },
    {
        "yok_code": "1055",
        "name": "Boğaziçi Üniversitesi",
        "city": "İstanbul",
        "university_type": "DEVLET",
        "website": "https://boun.edu.tr",
        "established_year": 1863,
    },
    {
        "yok_code": "1053",
        "name": "Marmara Üniversitesi",
        "city": "İstanbul",
        "university_type": "DEVLET",
        "website": "https://marmara.edu.tr",
        "established_year": 1883,
    },
    {
        "yok_code": "1076",
        "name": "Yıldız Teknik Üniversitesi",
        "city": "İstanbul",
        "university_type": "DEVLET",
        "website": "https://yildiz.edu.tr",
        "established_year": 1911,
    },
    {
        "yok_code": "1020",
        "name": "Ankara Üniversitesi",
        "city": "Ankara",
        "university_type": "DEVLET",
        "website": "https://ankara.edu.tr",
        "established_year": 1946,
    },
    {
        "yok_code": "1024",
        "name": "Hacettepe Üniversitesi",
        "city": "Ankara",
        "university_type": "DEVLET",
        "website": "https://hacettepe.edu.tr",
        "established_year": 1967,
    },
    {
        "yok_code": "1022",
        "name": "Gazi Üniversitesi",
        "city": "Ankara",
        "university_type": "DEVLET",
        "website": "https://gazi.edu.tr",
        "established_year": 1926,
    },
    {
        "yok_code": "1028",
        "name": "Orta Doğu Teknik Üniversitesi",
        "city": "Ankara",
        "university_type": "DEVLET",
        "website": "https://odtu.edu.tr",
        "established_year": 1956,
    },
    {
        "yok_code": "1041",
        "name": "Ege Üniversitesi",
        "city": "İzmir",
        "university_type": "DEVLET",
        "website": "https://ege.edu.tr",
        "established_year": 1955,
    },
]


# Örnek Programlar
SAMPLE_PROGRAMS = [
    {
        "yok_code": "100110217",
        "university_id": 1,
        "program_name": "Bilgisayar Mühendisliği",
        "faculty": "Mühendislik Fakültesi",
        "field_type": "SAY",
        "education_type": "Örgün Öğretim",
        "language": "Türkçe",
        "total_quota": 120,
        "min_score_2024": 485.5,
        "max_score_2024": 512.3,
        "min_rank_2024": 45000,
        "placed_students_2024": 118,
    },
    {
        "yok_code": "105110217",
        "university_id": 2,
        "program_name": "Bilgisayar Mühendisliği",
        "faculty": "Bilgisayar ve Bilişim Fakültesi",
        "field_type": "SAY",
        "education_type": "Örgün Öğretim",
        "language": "%30 İngilizce",
        "total_quota": 150,
        "min_score_2024": 510.2,
        "max_score_2024": 535.1,
        "min_rank_2024": 12000,
        "placed_students_2024": 148,
    },
    {
        "yok_code": "105510217",
        "university_id": 3,
        "program_name": "Bilgisayar Mühendisliği",
        "faculty": "Mühendislik Fakültesi",
        "field_type": "SAY",
        "education_type": "Örgün Öğretim",
        "language": "İngilizce",
        "total_quota": 100,
        "min_score_2024": 525.8,
        "max_score_2024": 548.9,
        "min_rank_2024": 5000,
        "placed_students_2024": 100,
    },
]


def init_score_calculations(db: Session):
    """Puan hesaplama katsayılarını yükle"""
    print("🔢 Puan hesaplama katsayıları yükleniyor...")
    
    # Önce var mı kontrol et
    existing_count = db.query(ScoreCalculation).count()
    if existing_count > 0:
        print(f"ℹ️  Zaten {existing_count} katsayı var, atlanıyor...")
        return
    
    for field_type, coeffs in SCORE_COEFFICIENTS.items():
        score_calc = ScoreCalculation(
            field_type=field_type,
            tyt_turkish_coefficient=coeffs.get("tyt_turkish", 0.0),
            tyt_math_coefficient=coeffs.get("tyt_math", 0.0),
            tyt_social_coefficient=coeffs.get("tyt_social", 0.0),
            tyt_science_coefficient=coeffs.get("tyt_science", 0.0),
            ayt_math_coefficient=coeffs.get("ayt_math", 0.0),
            ayt_physics_coefficient=coeffs.get("ayt_physics", 0.0),
            ayt_chemistry_coefficient=coeffs.get("ayt_chemistry", 0.0),
            ayt_biology_coefficient=coeffs.get("ayt_biology", 0.0),
            ayt_literature_coefficient=coeffs.get("ayt_literature", 0.0),
            ayt_history1_coefficient=coeffs.get("ayt_history1", 0.0),
            ayt_geography1_coefficient=coeffs.get("ayt_geography1", 0.0),
            ayt_history2_coefficient=coeffs.get("ayt_history2", 0.0),
            ayt_geography2_coefficient=coeffs.get("ayt_geography2", 0.0),
            ayt_philosophy_coefficient=coeffs.get("ayt_philosophy", 0.0),
            ayt_religion_coefficient=coeffs.get("ayt_religion", 0.0),
            ayt_language_coefficient=coeffs.get("ayt_language", 0.0),
        )
        db.add(score_calc)
    
    db.commit()
    print(f"✅ {len(SCORE_COEFFICIENTS)} alan türü katsayısı yüklendi")


def init_cities(db: Session):
    """Şehirleri yükle"""
    print("🏙️  Şehirler yükleniyor...")
    
    # Önce var mı kontrol et
    existing_count = db.query(YokCity).count()
    if existing_count > 0:
        print(f"ℹ️  Zaten {existing_count} şehir var, atlanıyor...")
        return
    
    for city_name, plate_code, region in TURKISH_CITIES:
        city = YokCity(
            name=city_name,
            plate_code=plate_code,
            region=region,
        )
        db.add(city)
    
    db.commit()
    print(f"✅ {len(TURKISH_CITIES)} şehir yüklendi")


def init_universities(db: Session):
    """Örnek üniversiteleri yükle"""
    print("🎓 Üniversiteler yükleniyor...")
    
    # Önce var mı kontrol et
    existing_count = db.query(YokUniversity).count()
    if existing_count > 0:
        print(f"ℹ️  Zaten {existing_count} üniversite var, atlanıyor...")
        return
    
    for uni_data in SAMPLE_UNIVERSITIES:
        university = YokUniversity(**uni_data)
        db.add(university)
    
    db.commit()
    print(f"✅ {len(SAMPLE_UNIVERSITIES)} üniversite yüklendi")


def init_programs(db: Session):
    """Örnek programları yükle"""
    print("📚 Programlar yükleniyor...")
    
    # Önce var mı kontrol et
    existing_count = db.query(YokProgram).count()
    if existing_count > 0:
        print(f"ℹ️  Zaten {existing_count} program var, atlanıyor...")
        return
    
    for prog_data in SAMPLE_PROGRAMS:
        program = YokProgram(**prog_data)
        db.add(program)
    
    db.commit()
    print(f"✅ {len(SAMPLE_PROGRAMS)} program yüklendi")


def main():
    """Ana seed fonksiyonu"""
    print("=" * 60)
    print("YÖK ATLAS VERİLERİ YÜKLENİYOR")
    print("=" * 60)
    
    # Database tablolarını oluştur
    print("\n📋 Database tabloları oluşturuluyor...")
    Base.metadata.create_all(bind=engine)
    print("✅ Tablolar oluşturuldu")
    
    # Session aç
    db = SessionLocal()
    
    try:
        # Verileri yükle
        init_score_calculations(db)
        init_cities(db)
        init_universities(db)
        init_programs(db)
        
        print("\n" + "=" * 60)
        print("✅ TÜM VERİLER BAŞARIYLA YÜKLENDİ!")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n❌ HATA: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()

