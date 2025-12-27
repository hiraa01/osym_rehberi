"""
✅ KAYIPSIZ AKTARIM (RAW IMPORT) SCRIPTİ

Bu script Excel'deki TÜM Program Kodu olan satırları veritabanına kayıpsız aktarır.
Tek kural: Program Kodu olan her satır veritabanına girmeli.

KULLANIM:
    python scripts/force_import.py

MANTIK:
    - Col 0: Program Kodu (ID) - Sayısal ise KAYDET
    - Col 1: Program Adı (Name) - Parantezleri silme!
    - Col 3: Puan Türü (Field Type)
    - Col 12: Taban Puan (Min Score)
    - Col 11: Sıralama (Min Rank)
"""
import pandas as pd
import os
import sys
import logging
import subprocess
from typing import Optional, Dict, List

# ---------------------------------------------------------
# 📂 AYARLAR
# ---------------------------------------------------------
script_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.dirname(script_dir)

possible_paths = [
    '/app/data/programs',
    os.path.join(backend_dir, 'data', 'programs'),
]

BASE_DIR: str = os.path.join(backend_dir, 'data', 'programs')
for path in possible_paths:
    if os.path.exists(path):
        BASE_DIR = path
        break

OUTPUT_DIR: str = os.path.dirname(BASE_DIR) if BASE_DIR.endswith('programs') else BASE_DIR
OUTPUT_FILE: str = os.path.join(OUTPUT_DIR, 'final_cleaned_data.json')

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# ---------------------------------------------------------
# 🧹 YARDIMCI FONKSİYONLAR
# ---------------------------------------------------------
def is_na_value(value) -> bool:
    """Güvenli NaN kontrolü."""
    if value is None:
        return True
    try:
        return bool(pd.isna(value))
    except (TypeError, ValueError):
        return False

def is_numeric_code(value) -> bool:
    """Değerin sadece rakamlardan oluşup oluşmadığını kontrol eder."""
    if is_na_value(value):
        return False
    
    value_str = str(value).strip()
    return value_str.isdigit() and len(value_str) > 0

def safe_get_value(row, col_index: int, default=None):
    """Satırdan güvenli şekilde değer alır."""
    try:
        if hasattr(row, 'iloc'):
            if col_index < len(row):
                value = row.iloc[col_index]
                if is_na_value(value):
                    return default
                return str(value).strip()
        else:
            if col_index < len(row):
                value = row[col_index]
                if is_na_value(value):
                    return default
                return str(value).strip()
    except (IndexError, KeyError):
        pass
    
    return default

def safe_get_numeric(value, default=None):
    """Değeri sayıya çevirir."""
    if is_na_value(value):
        return default
    
    try:
        value_str = str(value).replace(',', '.').replace(' ', '').strip()
        if value_str == '--' or value_str == '' or value_str.lower() == 'nan':
            return default
        if '.' in value_str:
            return float(value_str)
        else:
            return int(value_str)
    except (ValueError, TypeError):
        return default

def determine_degree_type(filename: str) -> str:
    """Dosya adına göre degree_type belirler."""
    filename_lower = filename.lower()
    if 'onlisans' in filename_lower or 'önlisans' in filename_lower:
        return 'Associate'
    elif 'lisans' in filename_lower:
        return 'Bachelor'
    return 'Bachelor'

def determine_field_type(program_name: str, field_type_from_file: Optional[str], degree_type: str, filename: str) -> str:
    """Puan türünü belirler."""
    # ZORUNLU OVERRIDE: Önlisans için TYT
    if degree_type == 'Associate':
        return 'TYT'
    
    # Dosyadan gelen puan türü varsa ve geçerliyse onu kullan
    if field_type_from_file and str(field_type_from_file).strip():
        field_type_upper = str(field_type_from_file).strip().upper()
        if field_type_upper in ['SAY', 'EA', 'SÖZ', 'DİL', 'TYT']:
            return field_type_upper
    
    # Tıp kontrolü - isimde "Tıp" varsa SAY
    program_name_lower = str(program_name).lower()
    if 'tıp' in program_name_lower:
        return 'SAY'
    
    # Lisans için varsayılan SAY
    if degree_type == 'Bachelor':
        return 'SAY'
    
    return 'SAY'

def determine_duration(program_name: str, duration_from_file, field_type: str, degree_type: str) -> int:
    """Süreyi belirler."""
    if degree_type == 'Associate':
        return 2
    
    if duration_from_file is not None:
        duration = safe_get_numeric(duration_from_file)
        if duration and duration > 0:
            return int(duration)
    
    program_name_lower = str(program_name).lower()
    if 'tıp' in program_name_lower:
        return 6
    
    if any(x in program_name_lower for x in ['diş hekimliği', 'veteriner', 'eczacılık']):
        return 5
    
    return 4

def extract_university_type(university_text: str) -> str:
    """Üniversite metninden türünü çıkarır."""
    if is_na_value(university_text):
        return 'state'
    
    text = str(university_text)
    text_lower = text.lower()
    
    import re
    match = re.search(r'\(([^)]+)\)', text_lower)
    if match:
        parantez_ici = match.group(1)
        if 'vakıf' in parantez_ici:
            return 'foundation'
        if 'devlet' in parantez_ici:
            return 'state'
    
    if 'kıbrıs' in text_lower or 'kktc' in text_lower:
        return 'kktc'
    if any(x in text_lower for x in ['vakıf', 'sabancı', 'koç', 'bilkent', 'başkent', 'medipol', 'yeditepe']):
        return 'foundation'
    
    return 'state'

def clean_university_name(university_text: str) -> str:
    """Üniversite adını temizler - parantez içlerini siler."""
    if is_na_value(university_text):
        return ""
    
    name = str(university_text).strip()
    import re
    name = re.sub(r'\s*\(.*?\)', '', name)
    return name.strip()

# ---------------------------------------------------------
# 🚀 KAYIPSIZ AKTARIM - HARDCODED SÜTUN İNDEKSLERİ
# ---------------------------------------------------------
def process_file_raw_import(filepath: str, filename: str) -> List[Dict]:
    """Excel dosyasını kayıpsız işler - HARDCODED sütun indeksleri."""
    logger.info(f"Processing file: {filename}")
    
    all_programs: List[Dict] = []
    
    # STATE MACHINE DEĞİŞKENLERİ
    current_university: str = ""
    current_uni_type: str = "state"
    
    # Dosyayı dtype=str ile oku (veri bozulmasını önlemek için)
    try:
        if filename.endswith('.csv'):
            df = pd.read_csv(filepath, header=None, dtype=str)
        elif filename.endswith('.xlsx'):
            df = pd.read_excel(filepath, header=None, dtype=str, engine='openpyxl')
        else:
            df = pd.read_excel(filepath, header=None, dtype=str, engine='xlrd')
    except Exception as e:
        logger.error(f"Error reading file {filename}: {e}")
        return []
    
    # HARDCODED SÜTUN İNDEKSLERİ
    COL_CODE = 0      # Program Kodu
    COL_NAME = 1      # Program Adı
    COL_FIELD_TYPE = 3  # Puan Türü
    COL_MIN_RANK = 11   # Sıralama
    COL_MIN_SCORE = 12  # Taban Puan
    
    degree_type = determine_degree_type(filename)
    
    logger.info(f"  Starting processing, degree_type: {degree_type}")
    
    # SAYAÇLAR
    total_rows_with_code = 0
    total_saved = 0
    
    # STATE MACHINE DÖNGÜSÜ - Satır satır işle
    for idx in range(len(df)):
        row = df.iloc[idx]
        
        # Col 0 ve Col 1 değerlerini al
        col0_value = safe_get_value(row, COL_CODE, "")
        col1_value = safe_get_value(row, COL_NAME, "")
        
        # ADIM A: Üniversite Tespiti
        if (not col0_value or not is_numeric_code(col0_value)) and col1_value:
            col1_upper = col1_value.upper()
            if "ÜNİVERSİTESİ" in col1_upper or "YÜKSEK TEKNOLOJİ ENSTİTÜSÜ" in col1_upper:
                current_university = clean_university_name(col1_value)
                current_uni_type = extract_university_type(col1_value)
                logger.info(f"  Found university: {current_university} ({current_uni_type})")
                continue
        
        # ADIM B: Bölüm Kaydı - PROGRAM KODU ESASLI
        # Eğer Program Kodu varsa ve sayısal ise -> MUTLAKA KAYDET
        if col0_value and is_numeric_code(col0_value):
            total_rows_with_code += 1
            
            # Üniversite bağlamı yoksa uyar ama YİNE DE KAYDET
            if not current_university:
                logger.warning(f"  Row {idx}: Program code found but no university context - saving anyway")
                current_university = "Bilinmeyen Üniversite"
                current_uni_type = "state"
            
            # Program bilgilerini al
            program_name_raw = col1_value if col1_value else f"Bölüm {col0_value}"
            
            # Orijinal ismi koru (parantez içleri ile birlikte)
            program_name_original = str(program_name_raw).strip()
            
            # Normalized name oluştur (arama için)
            normalized_name = program_name_original.lower().strip()
            
            # Diğer bilgileri al (HARDCODED indeksler)
            field_type_raw = safe_get_value(row, COL_FIELD_TYPE, None)
            min_score_raw = safe_get_value(row, COL_MIN_SCORE, None)
            min_rank_raw = safe_get_value(row, COL_MIN_RANK, None)
            
            # Değerleri belirle (override kuralları)
            field_type = determine_field_type(program_name_original, field_type_raw, degree_type, filename)
            duration = determine_duration(program_name_original, None, field_type, degree_type)
            
            # Sayısal değerleri çevir
            min_score = safe_get_numeric(min_score_raw, None)  # None olabilir - ASLA ATMA
            min_rank = safe_get_numeric(min_rank_raw, None)  # None olabilir
            
            # Kayıt oluştur - HER PROGRAM KODU KAYDEDİLİR
            program_data = {
                'name': program_name_original,  # Orijinal isim (parantezli)
                'normalized_name': normalized_name,
                'university': current_university,
                'university_type': current_uni_type,
                'field_type': field_type,
                'duration': duration,
                'degree_type': degree_type,
                'quota': 0,  # Varsayılan
                'min_score': min_score,  # None olabilir
                'min_rank': min_rank,  # None olabilir
                'code': col0_value  # Her kod benzersizdir
            }
            
            all_programs.append(program_data)
            total_saved += 1
            
            # Canlı sayaç (her 1000 satırda bir)
            if total_saved % 1000 == 0:
                print(f"   ⏳ {total_saved} bölüm kaydedildi...")
    
    # RAPORLAMA
    print(f"\n   📊 Excel'de Bulunan Satır (Program Kodu olan): {total_rows_with_code}")
    print(f"   ✅ Veritabanına Eklenen: {total_saved}")
    
    if total_rows_with_code != total_saved:
        print(f"   ⚠️  UYARI: Veri kaybı tespit edildi! ({total_rows_with_code - total_saved} satır kayboldu)")
    else:
        print(f"   ✅ Tüm satırlar başarıyla kaydedildi!")
    
    logger.info(f"  Extracted {len(all_programs)} programs from {filename}")
    return all_programs

def main():
    """Ana işlem fonksiyonu."""
    global BASE_DIR, OUTPUT_FILE, OUTPUT_DIR
    
    print("="*60)
    print("📊 KAYIPSIZ AKTARIM (RAW IMPORT) - FORCE IMPORT")
    print("="*60)
    
    print(f"📂 Looking in directory: {BASE_DIR}")
    
    if not os.path.exists(BASE_DIR):
        print(f"❌ Directory not found: {BASE_DIR}")
        return
    
    all_data: List[Dict] = []
    
    # Dosyaları bul
    files: List[str] = []
    if os.path.isdir(BASE_DIR):
        for f in os.listdir(BASE_DIR):
            if (f.endswith(".xls") or f.endswith(".xlsx") or f.endswith(".csv")) and not f.startswith("~$"):
                filename_lower = f.lower()
                if ('2025_lisans' in filename_lower or '2025_onlisans' in filename_lower or 
                    '2025-önlisans' in filename_lower):
                    files.append(os.path.join(BASE_DIR, f))
    
    if not files:
        print(f"⚠️  No matching files found in {BASE_DIR}")
        return
    
    print(f"📁 Found {len(files)} file(s) to process\n")
    
    # Her dosyayı işle
    for filepath in files:
        filename = os.path.basename(filepath)
        print(f"📖 Processing: {filename}...")
        
        try:
            programs = process_file_raw_import(filepath, filename)
            all_data.extend(programs)
            print(f"   ✅ {len(programs)} programs extracted\n")
        except Exception as e:
            logger.error(f"Error processing {filename}: {e}", exc_info=True)
            print(f"   ❌ Error: {e}\n")
    
    # Kaydetme
    if not all_data:
        print("❌ No data extracted.")
        return
    
    import json
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(all_data, f, ensure_ascii=False, indent=2)
    
    print(f"\n💾 Saved to: {OUTPUT_FILE}")
    print(f"   Total records: {len(all_data)}")
    
    # İstatistikler
    df_final = pd.DataFrame(all_data)
    print("-" * 60)
    print(f"📊 FINAL STATISTICS:")
    print(f"   Total programs: {len(df_final)}")
    if 'degree_type' in df_final.columns:
        print(f"   Bachelor: {len(df_final[df_final['degree_type'] == 'Bachelor'])}")
        print(f"   Associate: {len(df_final[df_final['degree_type'] == 'Associate'])}")
    if 'field_type' in df_final.columns:
        print(f"   TYT: {len(df_final[df_final['field_type'] == 'TYT'])}")
        print(f"   SAY: {len(df_final[df_final['field_type'] == 'SAY'])}")
        print(f"   EA: {len(df_final[df_final['field_type'] == 'EA'])}")
        print(f"   SÖZ: {len(df_final[df_final['field_type'] == 'SÖZ'])}")
        print(f"   DİL: {len(df_final[df_final['field_type'] == 'DİL'])}")
    if 'name' in df_final.columns:
        medicine_count = len(df_final[df_final['name'].str.contains('Tıp', case=False, na=False)])
        print(f"   Medicine (Tıp): {medicine_count}")
    print("-" * 60)
    
    # seed_db.py'yi çağır
    print("\n🚀 Veritabanına yükleniyor...")
    seed_script = os.path.join(script_dir, 'seed_db.py')
    if os.path.exists(seed_script):
        try:
            result = subprocess.run(
                [sys.executable, seed_script, '--json-file', OUTPUT_FILE],
                cwd=backend_dir,
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                print("✅ Veritabanı başarıyla dolduruldu!")
                print(result.stdout)
            else:
                print(f"⚠️  Veritabanı yükleme hatası:")
                print(result.stderr)
        except Exception as e:
            print(f"❌ seed_db.py çalıştırılırken hata: {e}")
    else:
        print(f"⚠️  seed_db.py bulunamadı: {seed_script}")
    
    print(f"\n✅ Toplam İşlenen Satır Sayısı: {len(all_data)}")

if __name__ == "__main__":
    main()

