#!/usr/bin/env python3
"""
PostgreSQL Veritabanı Başlatma ve YÖK Verilerini Yükleme Script'i
Bu script PostgreSQL'de tabloları oluşturur ve YÖK verilerini yükler.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from database import engine, Base, SessionLocal
from models.student import Student
from models.exam_attempt import ExamAttempt
from models.university import University, Department, Recommendation
from models.user import User
from core.logging_config import api_logger

def create_all_tables():
    """Tüm tabloları oluştur"""
    print("=" * 60)
    print("📋 PostgreSQL TABLOLARI OLUŞTURULUYOR...")
    print("=" * 60)
    
    try:
        # Tüm modelleri import et (Base.metadata'ya kayıt olmaları için)
        # Modeller zaten import edildi, sadece create_all çağır
        Base.metadata.create_all(bind=engine)
        print("✅ Tüm tablolar başarıyla oluşturuldu!")
        
        # Tabloları kontrol et
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
                ORDER BY table_name;
            """))
            tables = [row[0] for row in result]
            print(f"\n📊 Oluşturulan tablolar ({len(tables)} adet):")
            for table in tables:
                print(f"   - {table}")
        
        return True
    except Exception as e:
        print(f"\n❌ HATA: Tablolar oluşturulurken hata oluştu: {e}")
        import traceback
        traceback.print_exc()
        return False


def check_data_exists():
    """Veritabanında veri olup olmadığını kontrol et"""
    print("\n" + "=" * 60)
    print("🔍 VERİ KONTROLÜ YAPILIYOR...")
    print("=" * 60)
    
    db = SessionLocal()
    try:
        # Üniversite sayısı
        university_count = db.query(University).count()
        print(f"📚 Üniversiteler: {university_count} adet")
        
        # Bölüm sayısı
        department_count = db.query(Department).count()
        print(f"📖 Bölümler: {department_count} adet")
        
        # Öğrenci sayısı
        student_count = db.query(Student).count()
        print(f"👤 Öğrenciler: {student_count} adet")
        
        # Deneme sayısı
        attempt_count = db.query(ExamAttempt).count()
        print(f"📝 Denemeler: {attempt_count} adet")
        
        if university_count == 0 or department_count == 0:
            print("\n⚠️  UYARI: YÖK verileri yüklenmemiş!")
            print("   YÖK verilerini yüklemek için şu komutu çalıştırın:")
            print("   python backend/scripts/seed_yok_data.py")
            return False
        
        return True
    except Exception as e:
        print(f"\n❌ HATA: Veri kontrolü sırasında hata oluştu: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        db.close()


def create_indexes():
    """Performans için ekstra index'ler oluştur"""
    print("\n" + "=" * 60)
    print("⚡ PERFORMANS İNDEX'LERİ OLUŞTURULUYOR...")
    print("=" * 60)
    
    try:
        with engine.connect() as conn:
            # Composite index'ler (zaten modellerde tanımlı ama emin olmak için)
            indexes = [
                # ExamAttempt için composite index
                """
                CREATE INDEX IF NOT EXISTS ix_exam_attempts_student_attempt 
                ON exam_attempts(student_id, attempt_number);
                """,
                # Department için composite index (city + field_type)
                """
                CREATE INDEX IF NOT EXISTS ix_departments_city_field 
                ON departments(city, field_type) 
                WHERE city IS NOT NULL AND field_type IS NOT NULL;
                """,
                # University için composite index (city + university_type)
                """
                CREATE INDEX IF NOT EXISTS ix_universities_city_type 
                ON universities(city, university_type) 
                WHERE city IS NOT NULL AND university_type IS NOT NULL;
                """,
            ]
            
            for index_sql in indexes:
                try:
                    conn.execute(text(index_sql))
                    conn.commit()
                except Exception as e:
                    # Index zaten varsa hata vermez, sadece log
                    print(f"   ℹ️  Index oluşturuldu veya zaten mevcut")
            
            print("✅ Tüm performans index'leri oluşturuldu!")
            return True
    except Exception as e:
        print(f"\n⚠️  UYARI: Index oluşturma sırasında hata (kritik değil): {e}")
        return True  # Index hatası kritik değil


def main():
    """Ana fonksiyon"""
    print("\n" + "=" * 60)
    print("🚀 POSTGRESQL VERİTABANI BAŞLATMA")
    print("=" * 60)
    print()
    
    # 1. Tabloları oluştur
    if not create_all_tables():
        print("\n❌ Tablolar oluşturulamadı, işlem durduruldu.")
        return 1
    
    # 2. Index'leri oluştur
    create_indexes()
    
    # 3. Veri kontrolü
    has_data = check_data_exists()
    
    print("\n" + "=" * 60)
    if has_data:
        print("✅ VERİTABANI HAZIR VE VERİLER YÜKLÜ!")
    else:
        print("⚠️  VERİTABANI HAZIR AMA YÖK VERİLERİ YOK!")
        print("\n📝 YÖK verilerini yüklemek için:")
        print("   python backend/scripts/seed_yok_data.py")
    print("=" * 60)
    print()
    
    return 0


if __name__ == "__main__":
    exit(main())

