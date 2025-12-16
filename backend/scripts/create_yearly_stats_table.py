"""
Migration Script: DepartmentYearlyStats tablosunu oluştur
"""
import sys
import os
sys.path.append('/app')

from sqlalchemy import text
from database import engine, Base
from models.university import DepartmentYearlyStats  # Import to ensure metadata is loaded


def create_yearly_stats_table():
    print("=" * 60)
    print("📋 'department_yearly_stats' TABLOSU OLUŞTURULUYOR...")
    print("=" * 60)

    with engine.connect() as connection:
        try:
            # Check if table exists
            result = connection.execute(text("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_name = 'department_yearly_stats';
            """))
            if result.fetchone():
                print("✅ 'department_yearly_stats' tablosu zaten mevcut.")
                return
            
            # Create table using SQLAlchemy metadata
            Base.metadata.create_all(bind=engine, tables=[DepartmentYearlyStats.__table__])
            connection.commit()
            print("✅ 'department_yearly_stats' tablosu başarıyla oluşturuldu!")
            
            # Verify table structure
            result = connection.execute(text("""
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_name = 'department_yearly_stats'
                ORDER BY ordinal_position;
            """))
            columns = result.fetchall()
            print(f"\n📊 Tablo yapısı ({len(columns)} kolon):")
            for col in columns:
                print(f"   - {col[0]}: {col[1]}")
            
        except Exception as e:
            connection.rollback()
            print(f"❌ HATA: Tablo oluşturulurken hata oluştu: {e}")
            import traceback
            traceback.print_exc()
            sys.exit(1)


if __name__ == "__main__":
    # Ensure all models are loaded so Base.metadata knows about them
    from models.exam_attempt import ExamAttempt
    from models.student import Student
    from models.user import User
    from models.university import Department, University
    
    create_yearly_stats_table()
    print("\nMigration script tamamlandı.")

