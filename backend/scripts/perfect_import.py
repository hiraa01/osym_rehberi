import pandas as pd
import os
import re
import logging
import subprocess
import sys
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
# 🧹 TEMİZLİK FONKSİYONLARI
# ---------------------------------------------------------
def is_na_value(value) -> bool:
    """Güvenli NaN kontrolü."""
    if value is None:
        return True
    try:
        return bool(pd.isna(value))
    except (TypeError, ValueError):
        return False

def clean_program_name(name: str) -> str:
    """Program adını temizler - PARANTEZLERİ KORUR."""
    if is_na_value(name):
        return ""
    
    name = str(name).strip()
    # Sadece gereksiz boşlukları temizle
    name = re.sub(r'\s+', ' ', name)
    return name.strip()

def clean_university_name(university_text: str) -> str:
    """Üniversite adını temizler - parantez içlerini siler."""
    if is_na_value(university_text):
        return ""
    
    name = str(university_text).strip()
    name = re.sub(r'\s*\(.*?\)', '', name)
    return name.strip()

def extract_university_type(university_text: str) -> str:
    """Üniversite metninden türünü çıkarır."""
    if is_na_value(university_text):
        return 'state'
    
    text = str(university_text)
    text_lower = text.lower()
    
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
    """Puan türünü belirler - override kuralları uygulanır."""
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

# ---------------------------------------------------------
# 🔍 AKILLI DOSYA OKUYUCU (Format Dedektifi)
# ---------------------------------------------------------
def smart_read_file(filepath: str) -> Optional[pd.DataFrame]:
    """Dosyayı akıllıca okur - format dedektifi ile."""
    filename = os.path.basename(filepath)
    logger.info(f"  Attempting to read: {filename}")
    
    # 1. Önce CSV olarak dene (tab-separated)
    try:
        df = pd.read_csv(filepath, sep='\t', header=None, dtype=str, encoding='utf-8')
        logger.info(f"  ✅ Successfully read as CSV (tab-separated)")
        return df
    except Exception as e:
        logger.debug(f"  CSV (tab) failed: {e}")
    
    # 2. CSV olarak dene (comma-separated)
    try:
        df = pd.read_csv(filepath, sep=',', header=None, dtype=str, encoding='utf-8')
        logger.info(f"  ✅ Successfully read as CSV (comma-separated)")
        return df
    except Exception as e:
        logger.debug(f"  CSV (comma) failed: {e}")
    
    # 3. Excel olarak dene
    try:
        if filename.endswith('.xlsx'):
            df = pd.read_excel(filepath, header=None, dtype=str, engine='openpyxl')
        elif filename.endswith('.xls'):
            df = pd.read_excel(filepath, header=None, dtype=str, engine='xlrd')
        else:
            df = pd.read_excel(filepath, header=None, dtype=str)
        logger.info(f"  ✅ Successfully read as Excel")
        return df
    except Exception as e:
        logger.debug(f"  Excel failed: {e}")
    
    # 4. TSV olarak dene (UTF-16)
    try:
        df = pd.read_csv(filepath, sep='\t', header=None, dtype=str, encoding='utf-16')
        logger.info(f"  ✅ Successfully read as TSV (UTF-16)")
        return df
    except Exception as e:
        logger.debug(f"  TSV (UTF-16) failed: {e}")
    
    logger.error(f"  ❌ Failed to read file: {filename}")
    return None

# ---------------------------------------------------------
# 🚀 ID BAZLI ÇIKARMA (Birebir Eşleme - Mirroring)
# ---------------------------------------------------------
def process_file_id_based(filepath: str, filename: str) -> tuple[List[Dict], int]:
    """ID bazlı çıkarma - Birebir eşleme (Mirroring)."""
    logger.info(f"Processing file: {filename}")
    
    all_programs: List[Dict] = []
    
    # STATE MACHINE DEĞİŞKENLERİ
    current_university: str = ""
    current_uni_type: str = "state"
    
    # Akıllı dosya okuma
    df = smart_read_file(filepath)
    if df is None:
        return [], 0
    
    # SABİT SÜTUN İNDEKSLERİ
    COL_CODE = 0      # Program Kodu (ID)
    COL_NAME = 1      # Program Adı
    COL_DURATION = 2  # Süre
    COL_FIELD_TYPE = 3  # Puan Türü
    COL_MIN_SCORE = 12  # En Küçük Puan
    
    degree_type = determine_degree_type(filename)
    
    logger.info(f"  Starting ID-based extraction, degree_type: {degree_type}")
    
    # SAYAÇLAR
    total_ids_in_file = 0
    total_saved = 0
    
    # ID BAZLI DÖNGÜ - Satır satır işle
    for idx in range(len(df)):
        row = df.iloc[idx]
        
        # Col 0 ve Col 1 değerlerini al
        col0_value = safe_get_value(row, COL_CODE, "")
        col1_value = safe_get_value(row, COL_NAME, "")
        
        # ÜNİVERSİTE YAKALAMA (State Machine)
        if (not col0_value or not is_numeric_code(col0_value)) and col1_value:
            col1_upper = col1_value.upper()
            if "ÜNİVERSİTESİ" in col1_upper or "YÜKSEK TEKNOLOJİ ENSTİTÜSÜ" in col1_upper:
                current_university = clean_university_name(col1_value)
                current_uni_type = extract_university_type(col1_value)
                logger.info(f"  Found university: {current_university} ({current_uni_type})")
                continue
        
        # Fakülte başlığını atla
        if (not col0_value or not is_numeric_code(col0_value)) and col1_value:
            if 'fakültesi' in col1_value.lower() or 'yüksekokulu' in col1_value.lower():
                continue
        
        # BÖLÜM YAKALAMA (ID Varsa Kaydet)
        if col0_value and is_numeric_code(col0_value):
            total_ids_in_file += 1
            
            # Üniversite bağlamı yoksa uyar ama YİNE DE KAYDET
            if not current_university:
                logger.warning(f"  Row {idx}: ID found but no university context - saving anyway")
                current_university = "Bilinmeyen Üniversite"
                current_uni_type = "state"
            
            # ID: Col 0 (Veritabanı ID'si)
            program_id = col0_value
            
            # Name: Col 1 (Parantezleri SİLME! Olduğu gibi al)
            program_name = clean_program_name(col1_value) if col1_value else f"Bölüm {program_id}"
            
            # Min Score: Col 12 (Boşsa None yap ama satırı silme)
            min_score_raw = safe_get_value(row, COL_MIN_SCORE, None)
            min_score = safe_get_numeric(min_score_raw, None)  # None olabilir
            
            # Field Type: Col 3 (Puan Türü)
            field_type_raw = safe_get_value(row, COL_FIELD_TYPE, None)
            field_type = determine_field_type(program_name, field_type_raw, degree_type, filename)
            
            # Duration
            duration_raw = safe_get_value(row, COL_DURATION, None)
            duration = determine_duration(program_name, duration_raw, field_type, degree_type)
            
            # Normalized name (arama için)
            normalized_name = program_name.lower().strip()
            
            # Kayıt oluştur - HER ID KAYDEDİLİR
            program_data = {
                'id': program_id,  # Veritabanı ID'si
                'code': program_id,  # Eski uyumluluk için
                'name': program_name,  # Orijinal isim (parantezli)
                'normalized_name': normalized_name,
                'university': current_university,
                'university_type': current_uni_type,
                'field_type': field_type,
                'duration': duration,
                'degree_type': degree_type,
                'quota': 0,  # Kontenjan sütunu yoksa 0
                'min_score': min_score  # None olabilir - ASLA ATMA
            }
            
            all_programs.append(program_data)
            total_saved += 1
            
            # Canlı sayaç (her 1000 satırda bir)
            if total_saved % 1000 == 0:
                print(f"   ⏳ {total_saved} ID kaydedildi...")
    
    logger.info(f"  Extracted {len(all_programs)} programs from {filename}")
    return all_programs, total_ids_in_file

# ---------------------------------------------------------
# ✅ OTONOM DENETİM (Verification Report)
# ---------------------------------------------------------
def generate_verification_report(file_stats: Dict[str, int], total_saved: int) -> bool:
    """Otonom denetim raporu oluşturur."""
    print("\n" + "="*60)
    print("🔍 OTONOM DENETİM RAPORU (Verification Report)")
    print("="*60)
    
    total_ids_in_files = sum(file_stats.values())
    
    print(f"\n📊 İSTATİSTİKLER:")
    print(f"   Ham Dosyadaki ID Sayısı: {total_ids_in_files}")
    print(f"   Veritabanına Hazırlanan ID Sayısı: {total_saved}")
    
    # Dosya bazında detay
    print(f"\n📁 Dosya Bazında Detay:")
    for filename, count in file_stats.items():
        print(f"   {filename}: {count} ID")
    
    # KARAR
    print(f"\n{'='*60}")
    if total_ids_in_files == total_saved:
        print("✅ BAŞARILI - Veri Kaybı Yok")
        print(f"   Tüm {total_ids_in_files} ID başarıyla kaydedildi!")
        print(f"{'='*60}")
        return True
    else:
        print("❌ VERİ KAYBI VAR")
        print(f"   {total_ids_in_files - total_saved} ID kayboldu!")
        print(f"   Excel: {total_ids_in_files} | Veritabanı: {total_saved}")
        print(f"{'='*60}")
        return False

# ---------------------------------------------------------
# 🚀 ANA İŞLEM
# ---------------------------------------------------------
def main():
    """Ana işlem fonksiyonu."""
    global BASE_DIR, OUTPUT_FILE, OUTPUT_DIR
    
    print("="*60)
    print("🎯 PERFECT IMPORT - BİREBİR EŞLEME (MIRRORING)")
    print("="*60)
    
    print(f"📂 Looking in directory: {BASE_DIR}")
    
    if not os.path.exists(BASE_DIR):
        print(f"❌ Directory not found: {BASE_DIR}")
        return
    
    all_data: List[Dict] = []
    file_stats: Dict[str, int] = {}  # Dosya bazında ID sayıları
    
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
            programs, ids_in_file = process_file_id_based(filepath, filename)
            all_data.extend(programs)
            file_stats[filename] = ids_in_file
            print(f"   ✅ {len(programs)} programs extracted ({ids_in_file} IDs found)\n")
        except Exception as e:
            logger.error(f"Error processing {filename}: {e}", exc_info=True)
            print(f"   ❌ Error: {e}\n")
    
    # Verileri DataFrame'e çevir
    if not all_data:
        print("❌ No data extracted.")
        return
    
    df_final = pd.DataFrame(all_data)
    total_saved = len(df_final)
    
    # TEKİLLEŞTİRME YOK - Her ID benzersizdir
    # Sadece aynı ID varsa (çok nadir) onları temizle
    initial_count = len(df_final)
    if 'id' in df_final.columns or 'code' in df_final.columns:
        id_col = 'id' if 'id' in df_final.columns else 'code'
        if 'min_score' in df_final.columns:
            df_final = df_final.sort_values(by='min_score', ascending=False, na_position='last')
        df_final = df_final.drop_duplicates(subset=[id_col], keep='first')
        final_count = len(df_final)
        if initial_count != final_count:
            print(f"   ⚠️  {initial_count - final_count} duplicate ID removed")
            total_saved = final_count
    
    # OTONOM DENETİM
    verification_passed = generate_verification_report(file_stats, total_saved)
    
    if not verification_passed:
        print("\n⚠️  Doğrulama başarısız! Veriler kaydedilmeyecek.")
        sys.exit(1)
    
    # İstatistikler
    print("\n" + "-" * 60)
    print(f"📊 FINAL STATISTICS:")
    print(f"   Total programs: {len(df_final)}")
    print(f"   Bachelor: {len(df_final[df_final['degree_type'] == 'Bachelor'])}")
    print(f"   Associate: {len(df_final[df_final['degree_type'] == 'Associate'])}")
    print(f"   TYT: {len(df_final[df_final['field_type'] == 'TYT'])}")
    print(f"   SAY: {len(df_final[df_final['field_type'] == 'SAY'])}")
    print(f"   EA: {len(df_final[df_final['field_type'] == 'EA'])}")
    print(f"   SÖZ: {len(df_final[df_final['field_type'] == 'SÖZ'])}")
    print(f"   DİL: {len(df_final[df_final['field_type'] == 'DİL'])}")
    medicine_count = len(df_final[df_final['name'].str.contains('Tıp', case=False, na=False)]) if 'name' in df_final.columns else 0
    print(f"   Medicine (Tıp): {medicine_count}")
    print("-" * 60)
    
    # JSON'a kaydet
    df_final.to_json(OUTPUT_FILE, orient='records', force_ascii=False, indent=2)
    print(f"\n💾 Saved to: {OUTPUT_FILE}")
    print(f"   Total records: {len(df_final)}")
    
    # DATABASE SEED ÇAĞRISI
    print(f"\n{'='*60}")
    print("🌱 VERİTABANI SEED İŞLEMİ BAŞLATILIYOR...")
    print(f"{'='*60}")
    
    seed_script_path = os.path.join(script_dir, 'seed_db.py')
    json_file_path = OUTPUT_FILE
    
    if not os.path.exists(seed_script_path):
        print(f"⚠️  Seed script not found: {seed_script_path}")
        return
    
    try:
        result = subprocess.run(
            [sys.executable, seed_script_path, '--json-file', json_file_path],
            cwd=backend_dir,
            capture_output=True,
            text=True
        )
        
        print(result.stdout)
        
        if result.returncode == 0:
            print(f"\n✅ VERİTABANI SEED İŞLEMİ TAMAMLANDI!")
        else:
            print(f"\n❌ VERİTABANI SEED İŞLEMİ HATA VERDİ:")
            print(result.stderr)
            sys.exit(1)
            
    except Exception as e:
        logger.error(f"Error running seed script: {e}", exc_info=True)
        print(f"❌ Seed script çalıştırılırken hata: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

