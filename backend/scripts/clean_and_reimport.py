"""
Database'i temizle ve ÖSYM Excel'lerini tekrar yükle
"""
import sys
sys.path.append('/app')

from database import SessionLocal
from models.university import University, Department, Recommendation

db = SessionLocal()

try:
    print("🗑️  Eski veriler temizleniyor...")
    
    # Tüm verileri sil
    rec_count = db.query(Recommendation).delete()
    dept_count = db.query(Department).delete()
    uni_count = db.query(University).delete()
    
    db.commit()
    
    print(f"✅ Silindi: {uni_count} üniversite, {dept_count} bölüm, {rec_count} öneri")
    print("\n✅ Database temiz! Şimdi import_osym_excel.py çalıştırabilirsiniz.")

except Exception as e:
    print(f"❌ Hata: {e}")
    db.rollback()
finally:
    db.close()

