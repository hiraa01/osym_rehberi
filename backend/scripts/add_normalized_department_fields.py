"""
Migration Script: Department tablosuna normalized_name ve attributes kolonlarını ekle
"""
import sys
import os
sys.path.append('/app')

from sqlalchemy import text
from database import engine, Base
from models.university import Department, DepartmentYearlyStats  # Import to ensure metadata is loaded


def add_normalized_fields():
    print("=" * 60)
    print("📋 'normalized_name' ve 'attributes' KOLONLARI EKLENİYOR...")
    print("=" * 60)

    with engine.connect() as connection:
        try:
            # Check if normalized_name column exists
            result = connection.execute(text("""
                SELECT column_name
                FROM information_schema.columns
                WHERE table_name = 'departments' AND column_name = 'normalized_name';
            """))
            if result.fetchone():
                print("✅ 'normalized_name' kolonu zaten mevcut.")
            else:
                # Add normalized_name column
                connection.execute(text("""
                    ALTER TABLE departments
                    ADD COLUMN normalized_name VARCHAR(200);
                """))
                connection.commit()
                print("✅ 'normalized_name' kolonu başarıyla eklendi!")
            
            # Check if attributes column exists
            result = connection.execute(text("""
                SELECT column_name
                FROM information_schema.columns
                WHERE table_name = 'departments' AND column_name = 'attributes';
            """))
            if result.fetchone():
                print("✅ 'attributes' kolonu zaten mevcut.")
            else:
                # Add attributes column
                connection.execute(text("""
                    ALTER TABLE departments
                    ADD COLUMN attributes TEXT;
                """))
                connection.commit()
                print("✅ 'attributes' kolonu başarıyla eklendi!")
            
            # Add index on normalized_name for performance
            try:
                connection.execute(text("""
                    CREATE INDEX IF NOT EXISTS idx_departments_normalized_name 
                    ON departments(normalized_name);
                """))
                connection.commit()
                print("✅ 'normalized_name' index'i eklendi!")
            except Exception as idx_error:
                print(f"⚠️  Index eklenirken uyarı (zaten mevcut olabilir): {idx_error}")
            
        except Exception as e:
            connection.rollback()
            print(f"❌ HATA: Kolonlar eklenirken hata oluştu: {e}")
            import traceback
            traceback.print_exc()
            sys.exit(1)


if __name__ == "__main__":
    # Ensure all models are loaded so Base.metadata knows about them
    from models.exam_attempt import ExamAttempt
    from models.student import Student
    from models.user import User
    
    add_normalized_fields()
    print("\nMigration script tamamlandı.")

