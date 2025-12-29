"""
✅ PostgreSQL Sequence (Sayaç) Düzeltme Scripti

SQLite'tan PostgreSQL'e geçiş sonrası ID sequence'leri (sayaçlar) senkronize olmayabilir.
Bu script tüm tabloların ID sequence'lerini mevcut maksimum ID'ye eşitler.

KULLANIM:
    python scripts/fix_sequences.py

NOT: Bu script veritabanındaki tüm tabloları tarar ve sequence'leri düzeltir.
"""

import sys
import os
sys.path.append('/app')

from sqlalchemy import text, inspect
from database import engine, SessionLocal
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


def get_all_tables_with_sequences():
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
            logger.warning(f"⚠️ Tablo {table_name} kontrol edilemedi: {e}")
            continue
    
    return tables_with_ids


def fix_sequence_for_table(table_name: str, id_column: str, db):
    """
    ✅ Bir tablonun sequence'ini düzeltir
    
    Args:
        table_name: Tablo adı
        id_column: ID kolon adı
        db: Database session
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
            # ✅ Sequence yoksa oluştur (PostgreSQL 10+ için IDENTITY kullanılıyor olabilir)
            logger.warning(f"⚠️ {table_name}.{id_column} için sequence bulunamadı (IDENTITY kullanılıyor olabilir)")
            return False
        
        # ✅ Sequence'i maksimum ID + 1'e ayarla
        # NOT: false = sequence'i max_id + 1'e ayarla (bir sonraki değer max_id + 1 olacak)
        setval_query = text(f"""
            SELECT setval(:sequence_name, :max_id, false)
        """)
        db.execute(setval_query, {"sequence_name": sequence_name, "max_id": max_id})
        db.commit()
        
        logger.info(f"✅ {table_name}.{id_column}: Sequence '{sequence_name}' → {max_id + 1} olarak ayarlandı (max_id={max_id})")
        return True
        
    except Exception as e:
        logger.error(f"❌ {table_name}.{id_column} sequence düzeltme hatası: {e}")
        db.rollback()
        return False


def fix_all_sequences():
    """
    ✅ Tüm tabloların sequence'lerini düzeltir
    """
    logger.info("=" * 60)
    logger.info("🔄 PostgreSQL Sequence Düzeltme Başlatılıyor...")
    logger.info("=" * 60)
    
    db = SessionLocal()
    try:
        # ✅ Tüm tabloları ve ID kolonlarını bul
        tables_with_ids = get_all_tables_with_sequences()
        
        if not tables_with_ids:
            logger.warning("⚠️ Hiç tablo bulunamadı!")
            return
        
        logger.info(f"📊 {len(tables_with_ids)} tablo bulundu")
        logger.info("")
        
        # ✅ Her tablo için sequence'i düzelt
        fixed_count = 0
        failed_count = 0
        
        for table_name, id_column in tables_with_ids:
            logger.info(f"🔧 {table_name}.{id_column} düzeltiliyor...")
            if fix_sequence_for_table(table_name, id_column, db):
                fixed_count += 1
            else:
                failed_count += 1
            logger.info("")
        
        logger.info("=" * 60)
        logger.info(f"✅ Toplam: {fixed_count} başarılı, {failed_count} başarısız")
        logger.info("=" * 60)
        
    except Exception as e:
        logger.error(f"❌ CRITICAL: Sequence düzeltme hatası: {e}")
        import traceback
        logger.error(traceback.format_exc())
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    fix_all_sequences()

