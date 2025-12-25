"""
✅ VERİTABANI SEED SCRIPTİ

Bu script, final_cleaned_data.json dosyasındaki temizlenmiş verileri PostgreSQL veritabanına yükler:
- Önce eski verileri temizler (TRUNCATE CASCADE)
- Üniversiteleri yükler ve mapping oluşturur
- Bölümleri yükler (ilişkisel yapı)

KULLANIM:
    python scripts/seed_db.py [--json-file data/final_cleaned_data.json] [--truncate]

PARAMETRELER:
    --json-file: JSON dosyası yolu (varsayılan: data/final_cleaned_data.json)
    --truncate: Eski verileri sil (varsayılan: True)
"""
import sys
import json
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Set
from sqlalchemy import text
from sqlalchemy.orm import Session

sys.path.append('/app')

from database import SessionLocal, engine
from models.university import University, Department


def extract_city_from_university(uni_name: str) -> str:
    """Üniversite adından şehri çıkar (parantez içinde)"""
    if not uni_name:
        return 'Bilinmiyor'
    
    uni_str = str(uni_name).strip()
    # Parantez içindeki şehir adını bul
    if '(' in uni_str and ')' in uni_str:
        start = uni_str.rfind('(')
        end = uni_str.rfind(')')
        city = uni_str[start+1:end].strip()
        # Şehir adını title case yap
        return city.title()
    
    return 'Bilinmiyor'


def normalize_university_type(uni_name: str, uni_type: Optional[str] = None) -> str:
    """Üniversite tipini normalize et (devlet/vakif)"""
    if uni_type:
        uni_type_upper = str(uni_type).upper().strip()
        if 'VAKIF' in uni_type_upper or 'VAKÏF' in uni_type_upper or 'FOUNDATION' in uni_type_upper:
            return 'vakif'
        return 'devlet'
    
    # Üniversite adından tespit et
    if not uni_name:
        return 'devlet'
    
    uni_name_upper = str(uni_name).upper()
    if 'VAKIF' in uni_name_upper or 'FOUNDATION' in uni_name_upper:
        return 'vakif'
    
    return 'devlet'  # Varsayılan


def truncate_tables(db: Session):
    """Eski verileri temizle (TRUNCATE CASCADE)"""
    print("=" * 70)
    print("🗑️  ESKİ VERİLER TEMİZLENİYOR...")
    print("=" * 70)
    
    try:
        # Foreign key constraint'leri geçici olarak devre dışı bırak (PostgreSQL)
        # Önce DepartmentYearlyStats'ı sil (foreign key var)
        db.execute(text("TRUNCATE TABLE department_yearly_stats CASCADE"))
        print("   ✅ department_yearly_stats temizlendi")
        
        # Sonra Department'ı sil
        db.execute(text("TRUNCATE TABLE departments CASCADE"))
        print("   ✅ departments temizlendi")
        
        # Son olarak University'yi sil
        db.execute(text("TRUNCATE TABLE universities CASCADE"))
        print("   ✅ universities temizlendi")
        
        db.commit()
        print("✅ Tüm tablolar başarıyla temizlendi!")
        print()
        
    except Exception as e:
        db.rollback()
        print(f"❌ Temizleme hatası: {e}")
        # Alternatif yöntem: SQLAlchemy ile sil
        try:
            print("   💡 Alternatif yöntem deneniyor...")
            db.query(Department).delete()
            db.query(University).delete()
            db.commit()
            print("   ✅ Alternatif yöntemle temizlendi")
        except Exception as e2:
            db.rollback()
            print(f"   ❌ Alternatif yöntem de başarısız: {e2}")
            raise


def load_universities(db: Session, json_data: List[Dict]) -> Dict[str, int]:
    """
    Üniversiteleri yükle ve mapping oluştur
    
    Returns:
        Dict[str, int]: { 'Üniversite Adı': DB_ID } mapping
    """
    print("=" * 70)
    print("🏛️  ÜNİVERSİTELER YÜKLENİYOR...")
    print("=" * 70)
    
    # Tüm üniversite isimlerini topla ve tekilleştir
    universities_set: Set[str] = set()
    
    for record in json_data:
        uni_name = record.get('university', '')
        if uni_name and str(uni_name).strip():
            universities_set.add(str(uni_name).strip())
    
    print(f"   📊 {len(universities_set)} benzersiz üniversite bulundu")
    
    # Üniversite mapping'i oluştur
    university_mapping: Dict[str, int] = {}
    universities_to_create: List[Dict] = []
    
    for uni_name in sorted(universities_set):
        # Şehri çıkar
        city = extract_city_from_university(uni_name)
        
        # Üniversite adından şehir kısmını temizle
        if '(' in uni_name:
            clean_uni_name = uni_name[:uni_name.rfind('(')].strip()
        else:
            clean_uni_name = uni_name
        
        # Üniversite tipini belirle
        uni_type = normalize_university_type(clean_uni_name)
        
        # Zaten var mı kontrol et
        existing = db.query(University).filter(University.name == clean_uni_name).first()
        
        if existing:
            university_mapping[uni_name] = existing.id
        else:
            universities_to_create.append({
                'name': clean_uni_name,
                'city': city,
                'university_type': uni_type,
                'original_name': uni_name  # Mapping için
            })
    
    # Yeni üniversiteleri ekle
    if universities_to_create:
        print(f"   📝 {len(universities_to_create)} yeni üniversite ekleniyor...")
        
        for uni_data in universities_to_create:
            university = University(
                name=uni_data['name'],
                city=uni_data['city'],
                university_type=uni_data['university_type'],
                website=f"https://{uni_data['name'].lower().replace(' ', '').replace('ü', 'u').replace('ı', 'i').replace('ğ', 'g').replace('ş', 's').replace('ç', 'c').replace('ö', 'o')[:20]}.edu.tr"
            )
            db.add(university)
            db.flush()  # ID almak için
            university_mapping[uni_data['original_name']] = university.id
        
        db.commit()
        print(f"   ✅ {len(universities_to_create)} üniversite eklendi")
    
    # Mevcut üniversitelerin mapping'ini tamamla
    for uni_name in universities_set:
        if uni_name not in university_mapping:
            # Şehir kısmını temizle
            if '(' in uni_name:
                clean_uni_name = uni_name[:uni_name.rfind('(')].strip()
            else:
                clean_uni_name = uni_name
            
            existing = db.query(University).filter(University.name == clean_uni_name).first()
            if existing:
                university_mapping[uni_name] = existing.id
    
    print(f"✅ Toplam {len(university_mapping)} üniversite mapping'i oluşturuldu")
    print()
    
    return university_mapping


def load_departments(db: Session, json_data: List[Dict], university_mapping: Dict[str, int]):
    """
    Bölümleri yükle
    
    Args:
        db: Database session
        json_data: JSON verisi
        university_mapping: Üniversite mapping'i { 'Üniversite Adı': DB_ID }
    """
    print("=" * 70)
    print("📚 BÖLÜMLER YÜKLENİYOR...")
    print("=" * 70)
    
    departments_created = 0
    departments_skipped = 0
    
    total_records = len(json_data)
    
    for idx, record in enumerate(json_data):
        try:
            # Üniversite adını al
            uni_name = record.get('university', '')
            if not uni_name or not str(uni_name).strip():
                departments_skipped += 1
                continue
            
            # University ID'yi mapping'den al
            university_id = university_mapping.get(str(uni_name).strip())
            if not university_id:
                departments_skipped += 1
                continue
            
            # Bölüm bilgilerini al
            clean_name = record.get('clean_name', '')
            original_name = record.get('name', clean_name)
            
            if not clean_name:
                clean_name = original_name
            
            # Normalize edilmiş isim (clean_name kullan)
            normalized_name = clean_name.strip()
            
            # Diğer alanlar
            field_type = record.get('field_type', 'SAY')
            duration = record.get('duration', 4)
            degree_type = record.get('degree_type', 'Bachelor')
            faculty = record.get('faculty', None)
            language = record.get('language', 'Turkish')
            
            # ✅ Sayısal alanlar (YENİ ALANLAR DAHİL)
            min_score = record.get('min_score', None)
            min_rank = record.get('min_rank', None)
            quota = record.get('quota', None)
            
            # Bölüm zaten var mı kontrol et (aynı üniversite, normalize edilmiş isim, aynı field_type)
            existing = db.query(Department).filter(
                Department.university_id == university_id,
                Department.normalized_name == normalized_name,
                Department.field_type == field_type
            ).first()
            
            if existing:
                # Mevcut bölümü güncelle
                existing.duration = duration
                existing.degree_type = degree_type
                if faculty:
                    existing.faculty = faculty
                # ✅ YENİ: Min Score güncelleme
                if min_score is not None:
                    try:
                        existing.min_score = float(min_score) if min_score > 0 else None
                    except (ValueError, TypeError):
                        existing.min_score = None
                # ✅ YENİ: Min Rank güncelleme
                if min_rank is not None:
                    try:
                        existing.min_rank = int(min_rank) if min_rank > 0 else None
                    except (ValueError, TypeError):
                        existing.min_rank = None
                # ✅ YENİ: Quota güncelleme
                if quota is not None:
                    try:
                        existing.quota = int(quota) if quota > 0 else None
                    except (ValueError, TypeError):
                        existing.quota = None
                departments_created += 1  # Güncelleme de sayılır
            else:
                # Yeni bölüm ekle
                # ✅ YENİ: Min Score, Min Rank, Quota alanları eklendi
                department = Department(
                    university_id=university_id,
                    name=original_name if original_name else normalized_name,  # Orijinal isim
                    normalized_name=normalized_name,  # Normalize edilmiş isim
                    field_type=field_type,
                    language=language,
                    duration=int(duration) if duration else 4,
                    degree_type=degree_type,
                    faculty=faculty if faculty else None,
                    min_score=float(min_score) if min_score and min_score > 0 else None,
                    min_rank=int(min_rank) if min_rank and min_rank > 0 else None,
                    quota=int(quota) if quota and quota > 0 else None,
                )
                db.add(department)
                departments_created += 1
            
            # Her 1000 kayıtta bir commit (performans için)
            if (idx + 1) % 1000 == 0:
                db.commit()
                print(f"   ⏳ {idx + 1}/{total_records} kayıt işlendi... ({departments_created} bölüm eklendi/güncellendi)")
        
        except Exception as e:
            # Hata durumunda devam et
            departments_skipped += 1
            if (idx + 1) % 1000 == 0:
                print(f"   ⚠️  Satır {idx + 1} hatası: {str(e)[:100]}")
            continue
    
    # Son commit
    db.commit()
    
    print(f"✅ {departments_created} bölüm eklendi/güncellendi")
    if departments_skipped > 0:
        print(f"⚠️  {departments_skipped} kayıt atlandı (eksik veri veya hata)")
    print()


def main():
    parser = argparse.ArgumentParser(description='JSON verilerini veritabanına yükle')
    parser.add_argument('--json-file', type=str, default='data/final_cleaned_data.json', help='JSON dosyası yolu')
    parser.add_argument('--truncate', action='store_true', default=True, help='Eski verileri sil (varsayılan: True)')
    parser.add_argument('--no-truncate', dest='truncate', action='store_false', help='Eski verileri silme')
    
    args = parser.parse_args()
    
    # Dosya yolu
    script_dir = Path(__file__).parent
    backend_dir = script_dir.parent
    json_path = backend_dir / args.json_file
    
    print("=" * 70)
    print("🌱 VERİTABANI SEED SCRIPTİ")
    print("=" * 70)
    print(f"📂 JSON dosyası: {json_path}")
    print(f"🗑️  Eski verileri temizle: {args.truncate}")
    print()
    
    # Dosya var mı kontrol et
    if not json_path.exists():
        print(f"❌ JSON dosyası bulunamadı: {json_path}")
        print(f"💡 Önce clean_data.py scriptini çalıştırın!")
        return
    
    # JSON dosyasını oku
    print("📖 JSON dosyası okunuyor...")
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            json_data = json.load(f)
        print(f"   ✅ {len(json_data)} kayıt okundu")
        print()
    except Exception as e:
        print(f"❌ JSON okuma hatası: {e}")
        import traceback
        traceback.print_exc()
        return
    
    # Database session aç
    db = SessionLocal()
    
    try:
        # 1. Eski verileri temizle
        if args.truncate:
            truncate_tables(db)
        
        # 2. Üniversiteleri yükle ve mapping oluştur
        university_mapping = load_universities(db, json_data)
        
        # 3. Bölümleri yükle
        load_departments(db, json_data, university_mapping)
        
        # İstatistikler
        uni_count = db.query(University).count()
        dept_count = db.query(Department).count()
        
        print("=" * 70)
        print("✅ VERİTABANI SEED TAMAMLANDI!")
        print("=" * 70)
        print(f"🏛️  Üniversite sayısı: {uni_count}")
        print(f"📚 Bölüm sayısı: {dept_count}")
        print("=" * 70)
        
    except Exception as e:
        print(f"\n❌ HATA: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()

