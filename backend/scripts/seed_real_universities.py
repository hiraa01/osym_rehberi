"""
Gerçekçi Üniversite ve Bölüm Verilerini Database'e Yükle
2024 YKS Taban Puanları (Örnek)
"""
import sys
sys.path.append('/app')

from database import SessionLocal
from models.university import University, Department

db = SessionLocal()

# Gerçek 2024 Türkiye Üniversiteleri
UNIVERSITIES = [
    # İstanbul
    {"name": "İstanbul Üniversitesi", "city": "İstanbul", "university_type": "devlet", "website": "https://istanbul.edu.tr"},
    {"name": "İstanbul Teknik Üniversitesi", "city": "İstanbul", "university_type": "devlet", "website": "https://itu.edu.tr"},
    {"name": "Boğaziçi Üniversitesi", "city": "İstanbul", "university_type": "devlet", "website": "https://boun.edu.tr"},
    {"name": "Marmara Üniversitesi", "city": "İstanbul", "university_type": "devlet", "website": "https://marmara.edu.tr"},
    {"name": "Yıldız Teknik Üniversitesi", "city": "İstanbul", "university_type": "devlet", "website": "https://yildiz.edu.tr"},
    {"name": "Galatasaray Üniversitesi", "city": "İstanbul", "university_type": "devlet", "website": "https://gsu.edu.tr"},
    {"name": "Koç Üniversitesi", "city": "İstanbul", "university_type": "vakif", "website": "https://ku.edu.tr"},
    {"name": "Sabancı Üniversitesi", "city": "İstanbul", "university_type": "vakif", "website": "https://sabanciuniv.edu"},
    
    # Ankara
    {"name": "Ankara Üniversitesi", "city": "Ankara", "university_type": "devlet", "website": "https://ankara.edu.tr"},
    {"name": "Hacettepe Üniversitesi", "city": "Ankara", "university_type": "devlet", "website": "https://hacettepe.edu.tr"},
    {"name": "Orta Doğu Teknik Üniversitesi", "city": "Ankara", "university_type": "devlet", "website": "https://odtu.edu.tr"},
    {"name": "Gazi Üniversitesi", "city": "Ankara", "university_type": "devlet", "website": "https://gazi.edu.tr"},
    {"name": "Bilkent Üniversitesi", "city": "Ankara", "university_type": "vakif", "website": "https://bilkent.edu.tr"},
    
    # İzmir
    {"name": "Ege Üniversitesi", "city": "İzmir", "university_type": "devlet", "website": "https://ege.edu.tr"},
    {"name": "Dokuz Eylül Üniversitesi", "city": "İzmir", "university_type": "devlet", "website": "https://deu.edu.tr"},
    {"name": "İzmir Yüksek Teknoloji Enstitüsü", "city": "İzmir", "university_type": "devlet", "website": "https://iyte.edu.tr"},
    
    # Diğer Şehirler
    {"name": "Erciyes Üniversitesi", "city": "Kayseri", "university_type": "devlet", "website": "https://erciyes.edu.tr"},
    {"name": "Selçuk Üniversitesi", "city": "Konya", "university_type": "devlet", "website": "https://selcuk.edu.tr"},
    {"name": "Atatürk Üniversitesi", "city": "Erzurum", "university_type": "devlet", "website": "https://atauni.edu.tr"},
    {"name": "Çukurova Üniversitesi", "city": "Adana", "university_type": "devlet", "website": "https://cu.edu.tr"},
    {"name": "Akdeniz Üniversitesi", "city": "Antalya", "university_type": "devlet", "website": "https://akdeniz.edu.tr"},
    {"name": "Pamukkale Üniversitesi", "city": "Denizli", "university_type": "devlet", "website": "https://pau.edu.tr"},
    {"name": "Sakarya Üniversitesi", "city": "Sakarya", "university_type": "devlet", "website": "https://sakarya.edu.tr"},
    {"name": "Bursa Uludağ Üniversitesi", "city": "Bursa", "university_type": "devlet", "website": "https://uludag.edu.tr"},
    {"name": "Kocaeli Üniversitesi", "city": "Kocaeli", "university_type": "devlet", "website": "https://kocaeli.edu.tr"},
]

# 2024 Gerçek Bölüm Taban Puanları (Örnekler)
DEPARTMENTS_TEMPLATE = [
    # Bilgisayar Mühendisliği (SAY)
    {"name": "Bilgisayar Mühendisliği", "field_type": "SAY", "language": "Turkish", "duration": 4, "degree_type": "Bachelor",
     "scores": {"devlet_top": (520, 5000), "devlet_mid": (480, 25000), "devlet_low": (420, 80000), "vakif": (400, 100000)}},
    
    # Elektrik-Elektronik Mühendisliği (SAY)
    {"name": "Elektrik-Elektronik Mühendisliği", "field_type": "SAY", "language": "Turkish", "duration": 4, "degree_type": "Bachelor",
     "scores": {"devlet_top": (510, 8000), "devlet_mid": (465, 35000), "devlet_low": (410, 90000), "vakif": (390, 110000)}},
    
    # Makine Mühendisliği (SAY)
    {"name": "Makine Mühendisliği", "field_type": "SAY", "language": "Turkish", "duration": 4, "degree_type": "Bachelor",
     "scores": {"devlet_top": (505, 10000), "devlet_mid": (460, 40000), "devlet_low": (405, 95000), "vakif": (385, 115000)}},
    
    # Tıp (SAY)
    {"name": "Tıp", "field_type": "SAY", "language": "Turkish", "duration": 6, "degree_type": "Bachelor",
     "scores": {"devlet_top": (550, 1000), "devlet_mid": (520, 5000), "devlet_low": (480, 20000), "vakif": (450, 40000)}},
    
    # Hukuk (EA)
    {"name": "Hukuk", "field_type": "EA", "language": "Turkish", "duration": 4, "degree_type": "Bachelor",
     "scores": {"devlet_top": (510, 3000), "devlet_mid": (470, 15000), "devlet_low": (420, 60000), "vakif": (390, 90000)}},
    
    # İşletme (EA)
    {"name": "İşletme", "field_type": "EA", "language": "Turkish", "duration": 4, "degree_type": "Bachelor",
     "scores": {"devlet_top": (495, 8000), "devlet_mid": (450, 30000), "devlet_low": (390, 100000), "vakif": (360, 130000)}},
    
    # İktisat (EA)
    {"name": "İktisat", "field_type": "EA", "language": "Turkish", "duration": 4, "degree_type": "Bachelor",
     "scores": {"devlet_top": (485, 12000), "devlet_mid": (440, 40000), "devlet_low": (380, 110000), "vakif": (350, 140000)}},
    
    # Psikoloji (EA)
    {"name": "Psikoloji", "field_type": "EA", "language": "Turkish", "duration": 4, "degree_type": "Bachelor",
     "scores": {"devlet_top": (500, 7000), "devlet_mid": (460, 25000), "devlet_low": (410, 70000), "vakif": (380, 100000)}},
    
    # Türk Dili ve Edebiyatı (SÖZ)
    {"name": "Türk Dili ve Edebiyatı", "field_type": "SÖZ", "language": "Turkish", "duration": 4, "degree_type": "Bachelor",
     "scores": {"devlet_top": (470, 10000), "devlet_mid": (420, 40000), "devlet_low": (360, 100000), "vakif": (330, 130000)}},
    
    # Tarih (SÖZ)
    {"name": "Tarih", "field_type": "SÖZ", "language": "Turkish", "duration": 4, "degree_type": "Bachelor",
     "scores": {"devlet_top": (460, 15000), "devlet_mid": (410, 50000), "devlet_low": (350, 110000), "vakif": (320, 140000)}},
    
    # İngiliz Dili ve Edebiyatı (DİL)
    {"name": "İngiliz Dili ve Edebiyatı", "field_type": "DİL", "language": "English", "duration": 4, "degree_type": "Bachelor",
     "scores": {"devlet_top": (480, 8000), "devlet_mid": (430, 30000), "devlet_low": (370, 80000), "vakif": (340, 110000)}},
    
    # Mütercim Tercümanlık (DİL)
    {"name": "Mütercim Tercümanlık (İngilizce)", "field_type": "DİL", "language": "English", "duration": 4, "degree_type": "Bachelor",
     "scores": {"devlet_top": (475, 10000), "devlet_mid": (425, 35000), "devlet_low": (365, 85000), "vakif": (335, 115000)}},
]

def get_score_and_rank(dept_template, uni_type, uni_rank):
    """Üniversite tipine göre gerçekçi taban puanı ve sıralama belirle"""
    scores_info = dept_template["scores"]
    
    if uni_type == "vakif":
        return scores_info["vakif"]
    
    # Devlet üniversiteleri için üç seviye
    if uni_rank <= 5:  # Top tier (Boğaziçi, ODTU, vb)
        return scores_info["devlet_top"]
    elif uni_rank <= 15:  # Mid tier
        return scores_info["devlet_mid"]
    else:  # Lower tier
        return scores_info["devlet_low"]

try:
    # Kontrol et
    uni_count = db.query(University).count()
    if uni_count >= 20:
        print(f"✅ Zaten {uni_count} üniversite var, atlanıyor...")
        exit(0)

    print("🎓 Gerçekçi üniversite ve bölüm verileri yükleniyor...")
    print(f"📊 {len(UNIVERSITIES)} üniversite ve her birine {len(DEPARTMENTS_TEMPLATE)} bölüm eklenecek")
    
    # Üniversiteleri ekle
    universities_db = []
    for uni_data in UNIVERSITIES:
        uni = University(**uni_data)
        db.add(uni)
        db.flush()  # ID almak için
        universities_db.append(uni)
    
    db.commit()
    print(f"✅ {len(universities_db)} üniversite eklendi")
    
    # Her üniversiteye bölümler ekle
    dept_count = 0
    for idx, uni in enumerate(universities_db):
        for dept_template in DEPARTMENTS_TEMPLATE:
            min_score, min_rank = get_score_and_rank(dept_template, uni.university_type, idx)
            
            # Kontenjan hesapla (vakıf daha az)
            quota = 80 if uni.university_type == "vakif" else 120
            
            dept = Department(
                university_id=uni.id,
                name=dept_template["name"],
                field_type=dept_template["field_type"],
                language=dept_template["language"],
                duration=dept_template["duration"],
                degree_type=dept_template["degree_type"],
                min_score=min_score,
                min_rank=min_rank,
                quota=quota
            )
            db.add(dept)
            dept_count += 1
    
    db.commit()
    print(f"✅ {dept_count} bölüm eklendi!")
    print(f"🎉 Toplam: {len(universities_db)} üniversite × {len(DEPARTMENTS_TEMPLATE)} bölüm = {dept_count} kayıt")

except Exception as e:
    print(f"❌ Hata: {e}")
    db.rollback()
    raise
finally:
    db.close()

