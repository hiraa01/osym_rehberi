#!/usr/bin/env python3
"""
preferred_departments kolonunu students tablosuna ekle
Bu script mevcut tabloya yeni kolon ekler (veri kaybı olmaz)
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from database import engine
from core.logging_config import api_logger

def add_preferred_departments_column():
    """students tablosuna preferred_departments kolonunu ekle"""
    print("=" * 60)
    print("📋 preferred_departments KOLONU EKLENİYOR...")
    print("=" * 60)
    
    try:
        with engine.connect() as conn:
            # Önce kolonun var olup olmadığını kontrol et
            check_query = text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = 'students' 
                AND column_name = 'preferred_departments';
            """)
            result = conn.execute(check_query)
            column_exists = result.fetchone() is not None
            
            if column_exists:
                print("✅ preferred_departments kolonu zaten mevcut!")
                return True
            
            # Kolonu ekle
            alter_query = text("""
                ALTER TABLE students 
                ADD COLUMN preferred_departments TEXT;
            """)
            conn.execute(alter_query)
            conn.commit()
            
            print("✅ preferred_departments kolonu başarıyla eklendi!")
            return True
            
    except Exception as e:
        print(f"\n❌ HATA: Kolon eklenirken hata oluştu: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = add_preferred_departments_column()
    if success:
        print("\n✅ Migration tamamlandı!")
        sys.exit(0)
    else:
        print("\n❌ Migration başarısız!")
        sys.exit(1)

