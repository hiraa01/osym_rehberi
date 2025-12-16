"""
Migration Script: Mevcut bölümleri normalize et
Eski verileri normalize edilmiş isimlerle güncelle
"""
import sys
import os
import re
import json
sys.path.append('/app')

from sqlalchemy.orm import Session
from database import SessionLocal
from models.university import Department


def normalize_department_name(dept_name: str) -> tuple[str, list[str]]:
    """
    Bölüm ismini normalize et ve parantez içi detayları ayır
    """
    if not dept_name or dept_name == 'nan':
        return ("", [])
    
    dept_str = str(dept_name).strip()
    
    # Parantez içindeki tüm ifadeleri bul
    pattern = r'\(([^)]+)\)'
    matches = re.findall(pattern, dept_str)
    
    # Parantez içi içerikleri attributes olarak topla
    attributes = [match.strip() for match in matches if match.strip()]
    
    # Normalize edilmiş isim: Tüm parantezleri ve içeriklerini kaldır
    normalized = re.sub(pattern, '', dept_str).strip()
    
    # Fazla boşlukları temizle
    normalized = re.sub(r'\s+', ' ', normalized).strip()
    
    return (normalized, attributes)


def normalize_existing_departments():
    """Mevcut bölümleri normalize et"""
    print("=" * 70)
    print("MEVCUT BÖLÜMLERİ NORMALİZE ET")
    print("=" * 70)
    
    db = SessionLocal()
    
    try:
        # Normalize edilmemiş bölümleri bul
        departments = db.query(Department).filter(
            Department.normalized_name.is_(None)
        ).all()
        
        total = len(departments)
        print(f"📊 {total} normalize edilmemiş bölüm bulundu")
        
        updated = 0
        skipped = 0
        
        for idx, dept in enumerate(departments):
            try:
                # Normalize et
                normalized_name, attributes = normalize_department_name(dept.name)
                
                if not normalized_name:
                    skipped += 1
                    continue
                
                # Güncelle
                dept.normalized_name = normalized_name
                if attributes:
                    dept.attributes = json.dumps(attributes, ensure_ascii=False)
                
                updated += 1
                
                # Her 500 bölümde bir commit (deadlock riskini azaltmak için daha sık)
                if (idx + 1) % 500 == 0:
                    try:
                        db.commit()
                        print(f"   ⏳ {idx + 1}/{total} bölüm işlendi... ({updated} güncellendi)", flush=True)
                    except Exception as commit_error:
                        error_msg = str(commit_error)
                        if "DeadlockDetected" in error_msg or "deadlock" in error_msg.lower():
                            # Deadlock durumunda rollback yap ve tekrar dene
                            db.rollback()
                            print(f"   ⚠️  Deadlock tespit edildi (satır {idx + 1}), rollback yapıldı, devam ediliyor...", flush=True)
                            # Bu batch'i atla, bir sonraki batch'te devam et
                            continue
                        else:
                            db.rollback()
                            print(f"   ⚠️  Commit hatası (satır {idx + 1}): {error_msg[:100]}", flush=True)
            
            except Exception as e:
                error_msg = str(e)
                # Deadlock veya rollback hatası ise rollback yap ve devam et
                if "DeadlockDetected" in error_msg or "deadlock" in error_msg.lower() or "PendingRollbackError" in error_msg:
                    try:
                        db.rollback()
                    except:
                        pass
                    continue
                else:
                    try:
                        db.rollback()
                    except:
                        pass
                    # Sadece önemli hataları göster
                    if "Traceback" not in error_msg:
                        print(f"   ⚠️  Bölüm hatası: {error_msg[:100]}", flush=True)
                    continue
        
        # Son commit (deadlock riskine karşı retry mekanizması)
        max_retries = 3
        for retry in range(max_retries):
            try:
                db.commit()
                break
            except Exception as commit_error:
                error_msg = str(commit_error)
                if "DeadlockDetected" in error_msg or "deadlock" in error_msg.lower():
                    db.rollback()
                    if retry < max_retries - 1:
                        import time
                        time.sleep(1)  # 1 saniye bekle
                        print(f"   ⚠️  Deadlock, tekrar deneniyor ({retry + 1}/{max_retries})...", flush=True)
                        continue
                    else:
                        print(f"   ⚠️  Deadlock, son commit atlandı", flush=True)
                        break
                else:
                    db.rollback()
                    print(f"   ⚠️  Son commit hatası: {error_msg[:100]}", flush=True)
                    break
        
        print("\n" + "=" * 70)
        print("✅ NORMALİZASYON TAMAMLANDI!")
        print("=" * 70)
        print(f"📊 {updated} bölüm güncellendi")
        print(f"⏭️  {skipped} bölüm atlandı (boş isim)")
        
        # İstatistikler
        total_depts = db.query(Department).count()
        normalized_depts = db.query(Department).filter(
            Department.normalized_name.isnot(None)
        ).count()
        print(f"💾 Toplam: {total_depts} bölüm, {normalized_depts} normalize edilmiş")
        print("=" * 70)
        
    except Exception as e:
        print(f"\n❌ HATA: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    normalize_existing_departments()

