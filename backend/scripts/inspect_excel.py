"""
✅ EXCEL DOSYASI SÜTUN ANALİZİ (DEBUG SCRIPT)

Bu script, Excel dosyalarındaki gerçek sütun isimlerini ve ilk birkaç satırı gösterir.
Amaç: Sütun eşleştirme (COLUMN_MAPPING) için doğru sütun isimlerini tespit etmek.

KULLANIM:
    python scripts/inspect_excel.py [--file data/raw_files/2022_yerlestirme_l.xlsx]
"""
import sys
import argparse
from pathlib import Path
import pandas as pd

sys.path.append('/app')


def inspect_excel_file(file_path: Path, header_row: int = 2):
    """
    Excel dosyasını incele ve sütun bilgilerini göster
    
    Args:
        file_path: Excel dosyası yolu
        header_row: Header satır numarası (0-indexed, varsayılan: 2)
    """
    print("=" * 70)
    print("📊 EXCEL DOSYASI SÜTUN ANALİZİ")
    print("=" * 70)
    print(f"📂 Dosya: {file_path.name}")
    print(f"📂 Tam Yol: {file_path}")
    print()
    
    if not file_path.exists():
        print(f"❌ Dosya bulunamadı: {file_path}")
        return
    
    try:
        # Önce header=2 ile dene (ÖSYM formatı)
        try:
            df = pd.read_excel(file_path, sheet_name=0, header=header_row)
            print(f"✅ Dosya okundu (header={header_row})")
        except Exception as e:
            print(f"⚠️  header={header_row} ile okunamadı, header=0 deneniyor...")
            try:
                df = pd.read_excel(file_path, sheet_name=0, header=0)
                print(f"✅ Dosya okundu (header=0)")
            except Exception as e2:
                print(f"❌ Dosya okunamadı: {e2}")
                return
        
        # Duplicate sütunları temizle (gösterim için)
        df = df.loc[:, ~df.columns.duplicated()]
        
        print()
        print("=" * 70)
        print("📋 SÜTUN BAŞLIKLARI")
        print("=" * 70)
        
        # Sütun isimlerini listele
        columns = df.columns.tolist()
        print(f"Toplam {len(columns)} sütun bulundu:\n")
        
        for idx, col in enumerate(columns, 1):
            col_str = str(col)
            col_type = type(col).__name__
            print(f"  {idx:2d}. {col_str!r:50s} (tip: {col_type})")
        
        print()
        print("=" * 70)
        print("📄 İLK 3 SATIR (ÖRNEK VERİ)")
        print("=" * 70)
        
        # İlk 3 satırı göster
        if len(df) > 0:
            print("\nİlk 3 satır:\n")
            for row_idx in range(min(3, len(df))):
                print(f"--- Satır {row_idx + 1} ---")
                row = df.iloc[row_idx]
                for col in columns:
                    value = row[col]
                    # NaN kontrolü
                    if pd.isna(value):
                        value_str = "<NaN>"
                    else:
                        value_str = str(value)
                        # Uzun değerleri kısalt
                        if len(value_str) > 50:
                            value_str = value_str[:47] + "..."
                    
                    print(f"  {col!r:30s}: {value_str}")
                print()
        else:
            print("⚠️  Dosyada veri satırı bulunamadı!")
        
        print()
        print("=" * 70)
        print("🔍 ÖNEMLİ SÜTUN TESPİTİ")
        print("=" * 70)
        
        # Üniversite ile ilgili sütunları bul
        uni_keywords = ['üniversite', 'university', 'kurum', 'institution', 'uni']
        uni_columns = []
        for col in columns:
            col_lower = str(col).lower()
            if any(keyword in col_lower for keyword in uni_keywords):
                uni_columns.append(col)
        
        if uni_columns:
            print("\n🏛️  Üniversite ile ilgili sütunlar:")
            for col in uni_columns:
                print(f"  - {col!r}")
        else:
            print("\n⚠️  'Üniversite' ile ilgili sütun bulunamadı!")
        
        # Bölüm ile ilgili sütunları bul
        dept_keywords = ['bölüm', 'bolum', 'program', 'department', 'dept']
        dept_columns = []
        for col in columns:
            col_lower = str(col).lower()
            if any(keyword in col_lower for keyword in dept_keywords):
                dept_columns.append(col)
        
        if dept_columns:
            print("\n📚 Bölüm ile ilgili sütunlar:")
            for col in dept_columns:
                print(f"  - {col!r}")
        else:
            print("\n⚠️  'Bölüm' ile ilgili sütun bulunamadı!")
        
        # Puan türü ile ilgili sütunları bul
        field_keywords = ['puan', 'score', 'field', 'türü', 'turu', 'type']
        field_columns = []
        for col in columns:
            col_lower = str(col).lower()
            if any(keyword in col_lower for keyword in field_keywords):
                field_columns.append(col)
        
        if field_columns:
            print("\n🎯 Puan türü ile ilgili sütunlar:")
            for col in field_columns:
                print(f"  - {col!r}")
        else:
            print("\n⚠️  'Puan türü' ile ilgili sütun bulunamadı!")
        
        # Statü/Tür ile ilgili sütunları bul (YANLIŞ EŞLEŞTİRMEYİ ÖNLEMEK İÇİN)
        status_keywords = ['statü', 'status', 'türü', 'turu', 'tür', 'tur', 'tip', 'type']
        status_columns = []
        for col in columns:
            col_lower = str(col).lower()
            # Üniversite ile ilgili değilse ve statü/tür içeriyorsa
            if not any(uni_kw in col_lower for uni_kw in uni_keywords):
                if any(keyword in col_lower for keyword in status_keywords):
                    status_columns.append(col)
        
        if status_columns:
            print("\n⚠️  Statü/Tür ile ilgili sütunlar (ÜNİVERSİTE OLARAK EŞLEŞTİRİLMEMELİ!):")
            for col in status_columns:
                print(f"  - {col!r}")
        
        print()
        print("=" * 70)
        print("✅ ANALİZ TAMAMLANDI")
        print("=" * 70)
        
    except Exception as e:
        print(f"❌ Hata oluştu: {e}")
        import traceback
        traceback.print_exc()


def main():
    parser = argparse.ArgumentParser(description='Excel dosyasındaki sütunları analiz et')
    parser.add_argument('--file', type=str, help='Analiz edilecek Excel dosyası yolu')
    parser.add_argument('--header', type=int, default=2, help='Header satır numarası (varsayılan: 2)')
    
    args = parser.parse_args()
    
    # Script dizini
    script_dir = Path(__file__).parent
    backend_dir = script_dir.parent
    
    if args.file:
        # Belirtilen dosya
        file_path = backend_dir / args.file
    else:
        # İlk .xlsx dosyasını bul
        data_dir = backend_dir / 'data' / 'raw_files'
        
        if not data_dir.exists():
            # Alternatif: data/ klasöründe ara
            data_dir = backend_dir / 'data'
        
        if not data_dir.exists():
            print(f"❌ Veri klasörü bulunamadı: {data_dir}")
            return
        
        # İlk .xlsx dosyasını bul
        excel_files = list(data_dir.glob('*.xlsx'))
        
        if not excel_files:
            print(f"❌ {data_dir} klasöründe .xlsx dosyası bulunamadı!")
            return
        
        file_path = excel_files[0]
        print(f"📂 İlk bulunan Excel dosyası: {file_path.name}")
        print()
    
    inspect_excel_file(file_path, header_row=args.header)


if __name__ == "__main__":
    main()

