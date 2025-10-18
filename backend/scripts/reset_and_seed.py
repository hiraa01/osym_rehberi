"""
Database'i temizle ve gerçekçi verilerle doldur
"""
import sys
sys.path.append('/app')

from database import SessionLocal
from models.university import University, Department
from models.university import Recommendation

db = SessionLocal()

try:
    # Önce tüm verileri sil
    print("🗑️  Eski veriler temizleniyor...")
    db.query(Recommendation).delete()
    db.query(Department).delete()
    db.query(University).delete()
    db.commit()
    print("✅ Eski veriler temizlendi")
    
except Exception as e:
    print(f"❌ Temizleme hatası: {e}")
    db.rollback()
finally:
    db.close()

# Şimdi yeni verileri yükle
print("\n🔄 Yeni veriler yükleniyor...")
import subprocess
subprocess.run([sys.executable, "scripts/seed_real_universities.py"])

