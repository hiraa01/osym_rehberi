"""
✅ Kapsamlı Veritabanı Tutarlılık ve Sequence Düzeltme Scripti

Bu script şunları yapar:
1. Tüm tabloların ID sequence'lerini düzeltir (SQLite import sonrası)
2. Tablo satır sayılarını kontrol eder ve raporlar
3. Veritabanına yazma iznini test eder
4. Renkli ve okunaklı çıktı verir

KULLANIM:
    # Docker container içinde:
    docker exec -it osym_rehberi_backend python scripts/fix_and_check_db.py
    
    # Veya local'de:
    python scripts/fix_and_check_db.py
"""

import sys
import os
sys.path.append('/app' if os.path.exists('/app') else os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text, inspect
from sqlalchemy.exc import OperationalError, IntegrityError
from database import engine, SessionLocal
from core.logging_config import api_logger
import logging
from datetime import datetime
from typing import Dict, List, Tuple, Optional

# ✅ Renkli terminal çıktısı için ANSI kodları
class Colors:
    """Terminal renk kodları"""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def print_header(text: str):
    """Başlık yazdır"""
    print(f"\n{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.HEADER}{text.center(70)}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.HEADER}{'=' * 70}{Colors.ENDC}\n")

def print_success(text: str):
    """Başarı mesajı"""
    print(f"{Colors.OKGREEN}✅ {text}{Colors.ENDC}")

def print_warning(text: str):
    """Uyarı mesajı"""
    print(f"{Colors.WARNING}⚠️  {text}{Colors.ENDC}")

def print_error(text: str):
    """Hata mesajı"""
    print(f"{Colors.FAIL}❌ {text}{Colors.ENDC}")

def print_info(text: str):
    """Bilgi mesajı"""
    print(f"{Colors.OKCYAN}ℹ️  {text}{Colors.ENDC}")

def print_section(text: str):
    """Bölüm başlığı"""
    print(f"\n{Colors.BOLD}{Colors.OKBLUE}{'─' * 70}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.OKBLUE}{text}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.OKBLUE}{'─' * 70}{Colors.ENDC}\n")


# ============================================================================
# 1. SEQUENCE RESET (Kritik)
# ============================================================================

def get_all_tables_with_sequences() -> List[Tuple[str, str]]:
    """
    ✅ Tüm tabloları ve ID kolonlarını bulur
    
    Returns:
        list: [(table_name, id_column_name), ...]
    """
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    
    tables_with_ids = []
    
    for table_name in tables:
        try:
            columns = inspector.get_columns(table_name)
            # ID kolonunu bul (primary key ve integer olan)
            for col in columns:
                if col.get('primary_key') and 'int' in str(col.get('type')).lower():
                    tables_with_ids.append((table_name, col['name']))
                    break
        except Exception as e:
            print_warning(f"Tablo {table_name} kontrol edilemedi: {e}")
            continue
    
    return tables_with_ids


def fix_sequence_for_table(table_name: str, id_column: str, db) -> Tuple[bool, Optional[int], Optional[str]]:
    """
    ✅ Bir tablonun sequence'ini düzeltir
    
    Args:
        table_name: Tablo adı
        id_column: ID kolon adı
        db: Database session
    
    Returns:
        Tuple[bool, Optional[int], Optional[str]]: (başarılı mı, max_id, sequence_name)
    """
    try:
        # ✅ Mevcut maksimum ID'yi bul
        max_id_query = text(f"SELECT COALESCE(MAX({id_column}), 0) FROM {table_name}")
        result = db.execute(max_id_query)
        max_id = result.scalar() or 0
        
        # ✅ Sequence adını bul
        sequence_query = text(f"""
            SELECT pg_get_serial_sequence(:table_name, :id_column)
        """)
        result = db.execute(sequence_query, {"table_name": table_name, "id_column": id_column})
        sequence_name = result.scalar()
        
        if not sequence_name:
            # ✅ Sequence yoksa (IDENTITY kullanılıyor olabilir veya sequence yok)
            return False, max_id, None
        
        # ✅ Sequence'i maksimum ID + 1'e ayarla
        # NOT: false = sequence'i max_id + 1'e ayarla (bir sonraki değer max_id + 1 olacak)
        setval_query = text(f"""
            SELECT setval(:sequence_name, :max_id, false)
        """)
        db.execute(setval_query, {"sequence_name": sequence_name, "max_id": max_id})
        db.commit()
        
        return True, max_id, sequence_name
        
    except Exception as e:
        print_error(f"{table_name}.{id_column} sequence düzeltme hatası: {e}")
        db.rollback()
        return False, None, None


def fix_all_sequences() -> Dict[str, int]:
    """
    ✅ Tüm tabloların sequence'lerini düzeltir
    
    Returns:
        dict: {"fixed": count, "failed": count, "skipped": count}
    """
    print_section("1️⃣  SEQUENCE RESET (ID Sayaç Düzeltme)")
    
    db = SessionLocal()
    stats = {"fixed": 0, "failed": 0, "skipped": 0}
    
    try:
        # ✅ Tüm tabloları ve ID kolonlarını bul
        tables_with_ids = get_all_tables_with_sequences()
        
        if not tables_with_ids:
            print_warning("Hiç tablo bulunamadı!")
            return stats
        
        print_info(f"{len(tables_with_ids)} tablo bulundu\n")
        
        # ✅ Her tablo için sequence'i düzelt
        for table_name, id_column in tables_with_ids:
            print(f"🔧 {table_name}.{id_column} düzeltiliyor...", end=" ")
            
            success, max_id, sequence_name = fix_sequence_for_table(table_name, id_column, db)
            
            if success:
                print_success(f"Sequence '{sequence_name}' → {max_id + 1} (max_id={max_id})")
                stats["fixed"] += 1
            elif sequence_name is None:
                print_warning(f"Sequence bulunamadı (IDENTITY kullanılıyor olabilir, max_id={max_id})")
                stats["skipped"] += 1
            else:
                print_error(f"Düzeltme başarısız")
                stats["failed"] += 1
        
        print(f"\n{Colors.BOLD}📊 Özet:{Colors.ENDC}")
        print_success(f"Başarılı: {stats['fixed']}")
        if stats["skipped"] > 0:
            print_warning(f"Atlandı: {stats['skipped']}")
        if stats["failed"] > 0:
            print_error(f"Başarısız: {stats['failed']}")
        
        return stats
        
    except Exception as e:
        print_error(f"CRITICAL: Sequence düzeltme hatası: {e}")
        import traceback
        print_error(traceback.format_exc())
        db.rollback()
        return stats
    finally:
        db.close()


# ============================================================================
# 2. VERİ KONTROLÜ (Data Integrity Check)
# ============================================================================

def check_table_counts() -> Dict[str, int]:
    """
    ✅ Tüm tablolardaki satır sayılarını kontrol eder
    
    Returns:
        dict: {"table_name": row_count, ...}
    """
    print_section("2️⃣  VERİ KONTROLÜ (Tablo Satır Sayıları)")
    
    db = SessionLocal()
    table_counts = {}
    important_tables = ["users", "students", "universities", "departments", "exam_attempts"]
    
    try:
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        
        print_info(f"{len(tables)} tablo kontrol ediliyor...\n")
        
        for table_name in sorted(tables):
            try:
                count_query = text(f"SELECT COUNT(*) FROM {table_name}")
                result = db.execute(count_query)
                count = result.scalar() or 0
                table_counts[table_name] = count
                
                # ✅ Önemli tablolar için özel mesaj
                if table_name in important_tables:
                    if count == 0:
                        print_warning(f"{table_name}: {count} satır (BOŞ!)")
                    else:
                        print_success(f"{table_name}: {count:,} satır")
                else:
                    print(f"   {table_name}: {count:,} satır")
                    
            except Exception as e:
                print_error(f"{table_name}: Hata - {e}")
                table_counts[table_name] = -1
        
        # ✅ Önemli tablolar boş mu kontrol et
        print(f"\n{Colors.BOLD}📋 Önemli Tablolar Kontrolü:{Colors.ENDC}")
        empty_important = []
        for table in important_tables:
            if table in table_counts and table_counts[table] == 0:
                empty_important.append(table)
        
        if empty_important:
            print_warning(f"⚠️  Boş önemli tablolar: {', '.join(empty_important)}")
            print_info("💡 Bu tablolar veri içermiyor. Import scriptlerini çalıştırmanız gerekebilir.")
        else:
            print_success("Tüm önemli tablolar veri içeriyor")
        
        return table_counts
        
    except Exception as e:
        print_error(f"CRITICAL: Veri kontrolü hatası: {e}")
        import traceback
        print_error(traceback.format_exc())
        return table_counts
    finally:
        db.close()


# ============================================================================
# 3. YAZMA TESTİ (Write Permission Test)
# ============================================================================

def test_write_permission() -> bool:
    """
    ✅ Veritabanına yazma iznini test eder
    
    Returns:
        bool: Yazma başarılı ise True
    """
    print_section("3️⃣  YAZMA TESTİ (Write Permission Test)")
    
    db = SessionLocal()
    test_table_name = "db_integrity_test"
    
    try:
        # ✅ Test tablosu oluştur
        print_info("Test tablosu oluşturuluyor...")
        create_table_query = text(f"""
            CREATE TABLE IF NOT EXISTS {test_table_name} (
                id SERIAL PRIMARY KEY,
                test_message TEXT,
                created_at TIMESTAMP DEFAULT NOW()
            )
        """)
        db.execute(create_table_query)
        db.commit()
        print_success("Test tablosu oluşturuldu")
        
        # ✅ Test verisi yaz
        print_info("Test verisi yazılıyor...")
        insert_query = text(f"""
            INSERT INTO {test_table_name} (test_message)
            VALUES (:message)
            RETURNING id
        """)
        result = db.execute(insert_query, {"message": f"Test at {datetime.now()}"})
        inserted_id = result.scalar()
        db.commit()
        print_success(f"Test verisi yazıldı (ID: {inserted_id})")
        
        # ✅ Test verisini oku
        print_info("Test verisi okunuyor...")
        select_query = text(f"SELECT test_message FROM {test_table_name} WHERE id = :id")
        result = db.execute(select_query, {"id": inserted_id})
        message = result.scalar()
        print_success(f"Test verisi okundu: {message[:50]}...")
        
        # ✅ Test verisini sil
        print_info("Test verisi siliniyor...")
        delete_query = text(f"DELETE FROM {test_table_name} WHERE id = :id")
        db.execute(delete_query, {"id": inserted_id})
        db.commit()
        print_success("Test verisi silindi")
        
        # ✅ Test tablosunu sil
        print_info("Test tablosu siliniyor...")
        drop_table_query = text(f"DROP TABLE IF EXISTS {test_table_name}")
        db.execute(drop_table_query)
        db.commit()
        print_success("Test tablosu silindi")
        
        print_success("✅ Yazma testi BAŞARILI - Veritabanına yazma izni var")
        return True
        
    except Exception as e:
        print_error(f"❌ Yazma testi BAŞARISIZ: {e}")
        import traceback
        print_error(traceback.format_exc())
        db.rollback()
        
        # ✅ Test tablosunu temizle (hata olsa bile)
        try:
            drop_table_query = text(f"DROP TABLE IF EXISTS {test_table_name}")
            db.execute(drop_table_query)
            db.commit()
        except:
            pass
        
        return False
    finally:
        db.close()


# ============================================================================
# 4. VERİTABANI BAĞLANTI BİLGİLERİ
# ============================================================================

def print_database_info():
    """✅ Veritabanı bağlantı bilgilerini yazdır"""
    print_section("📊 VERİTABANI BİLGİLERİ")
    
    db = SessionLocal()
    try:
        # ✅ PostgreSQL versiyonu
        version_query = text("SELECT version()")
        result = db.execute(version_query)
        version = result.scalar()
        print_info(f"PostgreSQL Versiyonu: {version.split(',')[0]}")
        
        # ✅ Veritabanı adı
        db_name_query = text("SELECT current_database()")
        result = db.execute(db_name_query)
        db_name = result.scalar()
        print_info(f"Veritabanı Adı: {db_name}")
        
        # ✅ Bağlantı sayısı
        connections_query = text("""
            SELECT count(*) FROM pg_stat_activity 
            WHERE datname = current_database()
        """)
        result = db.execute(connections_query)
        connections = result.scalar()
        print_info(f"Aktif Bağlantı Sayısı: {connections}")
        
        # ✅ Tablo sayısı
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        print_info(f"Toplam Tablo Sayısı: {len(tables)}")
        
    except Exception as e:
        print_error(f"Veritabanı bilgileri alınamadı: {e}")
    finally:
        db.close()


# ============================================================================
# ANA FONKSİYON
# ============================================================================

def main():
    """✅ Ana fonksiyon - Tüm kontrolleri çalıştırır"""
    print_header("VERİTABANI TUTARLILIK VE SEQUENCE DÜZELTME")
    print(f"{Colors.OKCYAN}🕐 Başlangıç Zamanı: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}{Colors.ENDC}\n")
    
    try:
        # ✅ Veritabanı bilgileri
        print_database_info()
        
        # ✅ 1. Sequence Reset
        sequence_stats = fix_all_sequences()
        
        # ✅ 2. Veri Kontrolü
        table_counts = check_table_counts()
        
        # ✅ 3. Yazma Testi
        write_test_success = test_write_permission()
        
        # ✅ ÖZET RAPOR
        print_header("📋 ÖZET RAPOR")
        
        print(f"{Colors.BOLD}Sequence Düzeltme:{Colors.ENDC}")
        print_success(f"Başarılı: {sequence_stats['fixed']}")
        if sequence_stats["skipped"] > 0:
            print_warning(f"Atlandı: {sequence_stats['skipped']}")
        if sequence_stats["failed"] > 0:
            print_error(f"Başarısız: {sequence_stats['failed']}")
        
        print(f"\n{Colors.BOLD}Veri Kontrolü:{Colors.ENDC}")
        total_rows = sum(count for count in table_counts.values() if count > 0)
        print_info(f"Toplam {len(table_counts)} tablo kontrol edildi")
        print_info(f"Toplam {total_rows:,} satır veri bulundu")
        
        print(f"\n{Colors.BOLD}Yazma Testi:{Colors.ENDC}")
        if write_test_success:
            print_success("✅ Veritabanına yazma izni var")
        else:
            print_error("❌ Veritabanına yazma izni YOK - HATA!")
        
        print(f"\n{Colors.OKGREEN}{Colors.BOLD}✅ Tüm kontroller tamamlandı!{Colors.ENDC}")
        print(f"{Colors.OKCYAN}🕐 Bitiş Zamanı: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}{Colors.ENDC}\n")
        
        # ✅ Çıkış kodu (0 = başarılı, 1 = hata)
        if not write_test_success:
            return 1
        return 0
        
    except Exception as e:
        print_error(f"CRITICAL: Script hatası: {e}")
        import traceback
        print_error(traceback.format_exc())
        return 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)

