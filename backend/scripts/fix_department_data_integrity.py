"""
✅ VERİ BÜTÜNLÜĞÜ DÜZELTME SCRIPTİ

Bu script, veritabanındaki hatalı bölüm verilerini tespit eder ve düzeltir:
- TYT bölümlerinin duration=2 olması gerektiğini kontrol eder
- Associate bölümlerinin duration=2 olması gerektiğini kontrol eder
- Bachelor bölümlerinin duration>=4 olması gerektiğini kontrol eder
- TYT + Bachelor çelişkilerini düzeltir

KULLANIM:
    python scripts/fix_department_data_integrity.py [--dry-run] [--fix-all] [--delete-invalid]

PARAMETRELER:
    --dry-run: Sadece hataları göster, düzeltme yapma
    --fix-all: Tüm hataları otomatik düzelt
    --delete-invalid: Düzeltilemeyen kayıtları sil
"""
import sys
import argparse
sys.path.append('/app')

from sqlalchemy.orm import Session
from database import SessionLocal
from models.university import Department, University

def detect_and_fix_issues(db: Session, dry_run: bool = True, fix_all: bool = False, delete_invalid: bool = False):
    """Hatalı bölüm verilerini tespit et ve düzelt"""
    
    print("=" * 70)
    print("🔍 VERİ BÜTÜNLÜĞÜ KONTROLÜ BAŞLATILIYOR...")
    print("=" * 70)
    
    all_departments = db.query(Department).all()
    total_count = len(all_departments)
    
    print(f"📊 Toplam bölüm sayısı: {total_count}")
    print()
    
    issues_found = []
    fixed_count = 0
    deleted_count = 0
    
    # 1. TYT bölümleri kontrolü
    print("🔍 TYT bölümleri kontrol ediliyor...")
    tyt_departments = db.query(Department).filter(Department.field_type == 'TYT').all()
    
    for dept in tyt_departments:
        issues = []
        
        # TYT ise duration 2 olmalı
        if dept.duration != 2:
            issues.append(f"duration={dept.duration} (2 olmalı)")
        
        # TYT ise degree_type Associate olmalı
        if dept.degree_type != 'Associate':
            issues.append(f"degree_type={dept.degree_type} (Associate olmalı)")
        
        if issues:
            issue_str = ", ".join(issues)
            issues_found.append({
                "id": dept.id,
                "name": dept.name,
                "normalized_name": dept.normalized_name,
                "field_type": dept.field_type,
                "duration": dept.duration,
                "degree_type": dept.degree_type,
                "issues": issue_str,
                "fixable": True
            })
            
            if not dry_run and fix_all:
                # Düzelt
                dept.duration = 2
                dept.degree_type = 'Associate'
                fixed_count += 1
                print(f"   ✅ Düzeltildi: {dept.name} (ID: {dept.id})")
    
    print(f"   ⚠️  {len(issues_found)} TYT bölümünde sorun bulundu")
    print()
    
    # 2. Associate bölümleri kontrolü
    print("🔍 Associate (Önlisans) bölümleri kontrol ediliyor...")
    associate_departments = db.query(Department).filter(Department.degree_type == 'Associate').all()
    
    for dept in associate_departments:
        issues = []
        
        # Associate ise duration 2 olmalı
        if dept.duration != 2:
            issues.append(f"duration={dept.duration} (2 olmalı)")
        
        # Associate ise field_type TYT olmalı (genelde)
        if dept.field_type != 'TYT':
            issues.append(f"field_type={dept.field_type} (TYT olmalı)")
        
        if issues:
            issue_str = ", ".join(issues)
            # Zaten listeye eklenmiş mi kontrol et
            existing = next((x for x in issues_found if x["id"] == dept.id), None)
            if not existing:
                issues_found.append({
                    "id": dept.id,
                    "name": dept.name,
                    "normalized_name": dept.normalized_name,
                    "field_type": dept.field_type,
                    "duration": dept.duration,
                    "degree_type": dept.degree_type,
                    "issues": issue_str,
                    "fixable": True
                })
                
                if not dry_run and fix_all:
                    # Düzelt
                    dept.duration = 2
                    if dept.field_type != 'TYT':
                        dept.field_type = 'TYT'
                    fixed_count += 1
                    print(f"   ✅ Düzeltildi: {dept.name} (ID: {dept.id})")
    
    print(f"   ⚠️  Associate bölümlerinde ek sorunlar kontrol edildi")
    print()
    
    # 3. Bachelor bölümleri kontrolü
    print("🔍 Bachelor (Lisans) bölümleri kontrol ediliyor...")
    bachelor_departments = db.query(Department).filter(Department.degree_type == 'Bachelor').all()
    
    for dept in bachelor_departments:
        issues = []
        
        # Bachelor ise duration 4+ olmalı
        if dept.duration and dept.duration < 4:
            issues.append(f"duration={dept.duration} (4+ olmalı)")
        
        # Bachelor ise field_type TYT olmamalı
        if dept.field_type == 'TYT':
            issues.append(f"field_type=TYT (SAY/EA/SÖZ/DİL olmalı)")
        
        if issues:
            issue_str = ", ".join(issues)
            existing = next((x for x in issues_found if x["id"] == dept.id), None)
            if not existing:
                issues_found.append({
                    "id": dept.id,
                    "name": dept.name,
                    "normalized_name": dept.normalized_name,
                    "field_type": dept.field_type,
                    "duration": dept.duration,
                    "degree_type": dept.degree_type,
                    "issues": issue_str,
                    "fixable": True
                })
                
                if not dry_run and fix_all:
                    # Düzelt
                    if dept.duration and dept.duration < 4:
                        dept.duration = 4  # Varsayılan lisans süresi
                    if dept.field_type == 'TYT':
                        # TYT ise SAY yap (varsayılan)
                        dept.field_type = 'SAY'
                    fixed_count += 1
                    print(f"   ✅ Düzeltildi: {dept.name} (ID: {dept.id})")
    
    print(f"   ⚠️  Bachelor bölümlerinde ek sorunlar kontrol edildi")
    print()
    
    # 4. Null duration kontrolü
    print("🔍 Null duration kontrol ediliyor...")
    null_duration = db.query(Department).filter(Department.duration.is_(None)).all()
    
    for dept in null_duration:
        # Field type'a göre varsayılan değer ata
        if dept.field_type == 'TYT':
            default_duration = 2
            default_degree = 'Associate'
        else:
            default_duration = 4
            default_degree = 'Bachelor'
        
        issues_found.append({
            "id": dept.id,
            "name": dept.name,
            "normalized_name": dept.normalized_name,
            "field_type": dept.field_type,
            "duration": None,
            "degree_type": dept.degree_type,
            "issues": f"duration=null (varsayılan: {default_duration})",
            "fixable": True
        })
        
        if not dry_run and fix_all:
            dept.duration = default_duration
            if not dept.degree_type:
                dept.degree_type = default_degree
            fixed_count += 1
            print(f"   ✅ Düzeltildi: {dept.name} (ID: {dept.id}) - duration={default_duration}")
    
    print(f"   ⚠️  {len(null_duration)} null duration bulundu")
    print()
    
    # Özet
    print("=" * 70)
    print("📊 ÖZET")
    print("=" * 70)
    print(f"Toplam bölüm: {total_count}")
    print(f"Hatalı bölüm: {len(issues_found)}")
    print(f"Düzeltilen: {fixed_count}")
    print(f"Silinen: {deleted_count}")
    print()
    
    if issues_found:
        print("⚠️  HATALI BÖLÜMLER:")
        print("-" * 70)
        for issue in issues_found[:20]:  # İlk 20'sini göster
            print(f"ID: {issue['id']}")
            print(f"  İsim: {issue['name']}")
            print(f"  Normalize: {issue['normalized_name']}")
            print(f"  Field Type: {issue['field_type']}")
            print(f"  Duration: {issue['duration']}")
            print(f"  Degree Type: {issue['degree_type']}")
            print(f"  Sorunlar: {issue['issues']}")
            print()
        
        if len(issues_found) > 20:
            print(f"... ve {len(issues_found) - 20} bölüm daha")
        print()
    
    # Commit
    if not dry_run and fix_all:
        try:
            db.commit()
            print("✅ Değişiklikler veritabanına kaydedildi!")
        except Exception as e:
            db.rollback()
            print(f"❌ Hata: {e}")
            import traceback
            traceback.print_exc()
    
    return issues_found, fixed_count, deleted_count


def main():
    parser = argparse.ArgumentParser(description='Veri bütünlüğü kontrolü ve düzeltme')
    parser.add_argument('--dry-run', action='store_true', help='Sadece hataları göster, düzeltme yapma')
    parser.add_argument('--fix-all', action='store_true', help='Tüm hataları otomatik düzelt')
    parser.add_argument('--delete-invalid', action='store_true', help='Düzeltilemeyen kayıtları sil')
    
    args = parser.parse_args()
    
    if not args.dry_run and not args.fix_all:
        print("⚠️  UYARI: --dry-run veya --fix-all parametresi gerekli!")
        print("   Örnek: python scripts/fix_department_data_integrity.py --dry-run")
        print("   Örnek: python scripts/fix_department_data_integrity.py --fix-all")
        return
    
    db = SessionLocal()
    try:
        issues, fixed, deleted = detect_and_fix_issues(
            db, 
            dry_run=args.dry_run,
            fix_all=args.fix_all,
            delete_invalid=args.delete_invalid
        )
    except Exception as e:
        print(f"❌ Hata: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    main()

