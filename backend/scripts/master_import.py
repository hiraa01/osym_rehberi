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

# Olası path'leri dene
possible_paths = [
    '/app/data/programs',  # Docker container içinde
    os.path.join(backend_dir, 'data', 'programs'),  # Script'in yanında
]

BASE_DIR: str = os.path.join(backend_dir, 'data', 'programs')  # Varsayılan
for path in possible_paths:
    if os.path.exists(path):
        BASE_DIR = path
        break

OUTPUT_DIR: str = os.path.dirname(BASE_DIR) if BASE_DIR.endswith('programs') else BASE_DIR
OUTPUT_FILE: str = os.path.join(OUTPUT_DIR, 'final_cleaned_data.json')

# Logging setup
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

def clean_program_name(name: str, preserve_parentheses: bool = False) -> str:
    """Program adını temizler. preserve_parentheses=True ise parantez içlerini korur."""
    if is_na_value(name):
        return ""
    
    name = str(name).strip()
    
    # Sadece gereksiz boşlukları temizle
    name = re.sub(r'\s+', ' ', name)  # Çoklu boşlukları tek boşluğa çevir
    
    if not preserve_parentheses:
        # Normalized name için: parantez içlerini sil
        name = re.sub(r'\s*\(.*?\)', '', name)
        name = name.replace('KKTC Uyruklu', '').replace('KKTC', '').replace('Uyruklu', '').strip()
        
        suffixes = [
            ' Fakültesi', ' Yüksekokulu', ' Bölümü', ' Programı', ' Anabilim Dalı',
            ' M.T.O.K.', ' UOLP', ' İkinci Öğretim', ' Uzaktan Öğretim', ' Açıköğretim'
        ]
        for suffix in suffixes:
            name = re.compile(re.escape(suffix), re.IGNORECASE).sub('', name)
    
    return name.strip().strip('.,-')

def get_normalized_name(name: str) -> str:
    """Normalized name oluşturur - parantez içlerini siler."""
    return clean_program_name(name, preserve_parentheses=False)

def clean_university_name(university_text: str) -> str:
    """Üniversite adını temizler."""
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
    
    # Parantez içinden tür bilgisini al
    match = re.search(r'\(([^)]+)\)', text_lower)
    if match:
        parantez_ici = match.group(1)
        if 'vakıf' in parantez_ici:
            return 'foundation'
        if 'devlet' in parantez_ici:
            return 'state'
    
    # Üniversite isminden tür belirleme
    if 'kıbrıs' in text_lower or 'kktc' in text_lower:
        return 'kktc'
    if any(x in text_lower for x in ['vakıf', 'sabancı', 'koç', 'bilkent', 'başkent', 'medipol', 'yeditepe']):
        return 'foundation'
    
    return 'state'

def is_numeric_code(value) -> bool:
    """Değerin sadece rakamlardan oluşup olmadığını kontrol eder."""
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
    
    # 1. Önce CSV olarak dene (virgülle ayrılmış)
    try:
        df = pd.read_csv(filepath, sep=',', header=None, dtype=str, encoding='utf-8')
        logger.info(f"  ✅ Successfully read as CSV (comma-separated)")
        return df
    except Exception as e:
        logger.debug(f"  CSV (comma) failed: {e}")
    
    # 2. Excel olarak dene
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
    
    # 3. TSV olarak dene (tab-separated, UTF-16)
    try:
        df = pd.read_csv(filepath, sep='\t', header=None, dtype=str, encoding='utf-16')
        logger.info(f"  ✅ Successly read as TSV (tab-separated, UTF-16)")
        return df
    except Exception as e:
        logger.debug(f"  TSV (UTF-16) failed: {e}")
    
    # 4. TSV olarak dene (tab-separated, UTF-8)
    try:
        df = pd.read_csv(filepath, sep='\t', header=None, dtype=str, encoding='utf-8')
        logger.info(f"  ✅ Successfully read as TSV (tab-separated, UTF-8)")
        return df
    except Exception as e:
        logger.debug(f"  TSV (UTF-8) failed: {e}")
    
    logger.error(f"  ❌ Failed to read file: {filename}")
    return None

# ---------------------------------------------------------
# 🚀 STATE MACHINE - SABİT SÜTUN İNDEKSLERİ İLE
# ---------------------------------------------------------
def process_hierarchical_file(filepath: str, filename: str) -> List[Dict]:
    """Hiyerarşik Excel dosyasını State Machine ile işler - SABİT SÜTUN İNDEKSLERİ."""
    logger.info(f"Processing file: {filename}")
    
    all_programs: List[Dict] = []
    
    # STATE MACHINE DEĞİŞKENLERİ
    current_university: str = ""
    current_uni_type: str = "state"
    
    # Akıllı dosya okuma
    df = smart_read_file(filepath)
    if df is None:
        return []
    
    # SABİT SÜTUN İNDEKSLERİ (Dosya snippetlarına göre)
    COL_CODE = 0      # Program Kodu
    COL_NAME = 1      # Program Adı / Üniversite Adı
    COL_DURATION = 2  # Süre (opsiyonel)
    COL_FIELD_TYPE = 3  # Puan Türü
    COL_MIN_SCORE = 12  # En Küçük Puan (Lisans için)
    
    # Degree type belirle
    degree_type = determine_degree_type(filename)
    
    logger.info(f"  Starting State Machine processing, degree_type: {degree_type}")
    
    # STATE MACHINE DÖNGÜSÜ - Satır satır işle
    for idx in range(len(df)):
        row = df.iloc[idx]
        
        # Col 0 ve Col 1 değerlerini al
        col0_value = safe_get_value(row, COL_CODE, "")
        col1_value = safe_get_value(row, COL_NAME, "")
        
        # ADIM A: Üniversite Başlığını Yakala
        # Col 0 boş (NaN) ve Col 1 içinde "ÜNİVERSİTESİ" geçiyorsa
        if (not col0_value or not is_numeric_code(col0_value)) and col1_value:
            col1_upper = col1_value.upper()
            if "ÜNİVERSİTESİ" in col1_upper or "YÜKSEK TEKNOLOJİ ENSTİTÜSÜ" in col1_upper:
                current_university = clean_university_name(col1_value)
                current_uni_type = extract_university_type(col1_value)
                logger.info(f"  Found university: {current_university} ({current_uni_type})")
                continue
        
        # ADIM B: Fakülte Başlığını Atla
        if (not col0_value or not is_numeric_code(col0_value)) and col1_value:
            if 'fakültesi' in col1_value.lower() or 'yüksekokulu' in col1_value.lower():
                continue
        
        # ADIM C: Bölüm Verisini Yakala
        # Col 0 sayısal bir değerse -> Bu bir bölümdür
        if col0_value and is_numeric_code(col0_value):
            # Bu bir bölüm satırı!
            if not current_university:
                logger.warning(f"  Row {idx}: Program code found but no university context")
                continue
            
            # Program bilgilerini al
            program_name_raw = col1_value
            if not program_name_raw:
                continue
            
            # Orijinal ismi koru (parantez içleri ile birlikte)
            program_name_original = clean_program_name(program_name_raw, preserve_parentheses=True)
            if not program_name_original:
                continue
            
            # Normalized name oluştur (parantez içlerini silmiş hali - arama için)
            normalized_name = get_normalized_name(program_name_raw)
            
            # Diğer bilgileri al (SABİT SÜTUN İNDEKSLERİ)
            duration_raw = safe_get_value(row, COL_DURATION, None)
            field_type_raw = safe_get_value(row, COL_FIELD_TYPE, None)
            min_score_raw = safe_get_value(row, COL_MIN_SCORE, None)
            
            # Değerleri belirle (override kuralları uygulanır)
            # Normalized name kullan (çünkü "Tıp" kontrolü yapıyoruz)
            field_type = determine_field_type(normalized_name, field_type_raw, degree_type, filename)
            duration = determine_duration(normalized_name, duration_raw, field_type, degree_type)
            
            # Min_score'u sayıya çevir (None olabilir - dolmadı)
            min_score = safe_get_numeric(min_score_raw, None)
            
            # Kayıt oluştur
            program_data = {
                'name': program_name_original,  # Orijinal isim (parantezli)
                'normalized_name': normalized_name,  # Normalize edilmiş isim (arama için)
                'university': current_university,
                'university_type': current_uni_type,
                'field_type': field_type,
                'duration': duration,
                'degree_type': degree_type,
                'quota': 0,  # Kontenjan sütunu yoksa 0
                'min_score': min_score,  # None olabilir
                'code': col0_value  # Her kod benzersizdir
            }
            
            all_programs.append(program_data)
    
    logger.info(f"  Extracted {len(all_programs)} programs from {filename}")
    return all_programs

# ---------------------------------------------------------
# ✅ OTONOM DOĞRULAMA (Verification Step)
# ---------------------------------------------------------
def verify_data(df: pd.DataFrame) -> bool:
    """Verileri doğrular ve rapor basar."""
    print("\n" + "="*60)
    print("🔍 OTONOM VERİ DOĞRULAMA")
    print("="*60)
    
    # İstatistikler
    total_programs = len(df)
    total_medicine = len(df[df['name'].str.contains('Tıp', case=False, na=False)]) if 'name' in df.columns else 0
    total_associate = len(df[df['degree_type'] == 'Associate']) if 'degree_type' in df.columns else 0
    
    print(f"\n📊 İSTATİSTİKLER:")
    print(f"   Toplam Bölüm: {total_programs}")
    print(f"   Tıp Fakültesi: {total_medicine}")
    print(f"   Önlisans: {total_associate}")
    
    # ASSERTION KONTROLLERİ
    print(f"\n✅ DOĞRULAMA KONTROLLERİ:")
    
    assertion_1 = total_medicine > 110
    assertion_2 = total_associate > 6000
    assertion_3 = total_programs > 12000
    
    print(f"   {'✅' if assertion_1 else '❌'} Tıp Fakültesi > 110: {total_medicine} (Beklenen: >110)")
    print(f"   {'✅' if assertion_2 else '❌'} Önlisans > 6000: {total_associate} (Beklenen: >6000)")
    print(f"   {'✅' if assertion_3 else '❌'} Toplam Bölüm > 12000: {total_programs} (Beklenen: >12000)")
    
    # Tüm kontroller başarılı mı?
    all_passed = assertion_1 and assertion_2 and assertion_3
    
    if all_passed:
        print(f"\n{'='*60}")
        print("✅ BÜTÜN VERİLER TAMAM")
        print(f"{'='*60}")
        return True
    else:
        print(f"\n{'='*60}")
        print("❌ VERİ EKSİK: Parsing Yöntemini Değiştirin")
        print(f"{'='*60}")
        return False

# ---------------------------------------------------------
# 🚀 ANA İŞLEM
# ---------------------------------------------------------
def main():
    """Ana işlem fonksiyonu."""
    global BASE_DIR, OUTPUT_FILE, OUTPUT_DIR
    
    print("="*60)
    print("🎯 MASTER IMPORT - OTONOM VERİ İÇE AKTARMA")
    print("="*60)
    
    print(f"📂 Looking in directory: {BASE_DIR}")
    
    # Klasör kontrolü
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
            programs = process_hierarchical_file(filepath, filename)
            all_data.extend(programs)
            print(f"   ✅ {len(programs)} programs extracted\n")
        except Exception as e:
            logger.error(f"Error processing {filename}: {e}", exc_info=True)
            print(f"   ❌ Error: {e}\n")
    
    # Verileri DataFrame'e çevir
    if not all_data:
        print("❌ No data extracted.")
        return
    
    df_final = pd.DataFrame(all_data)
    
    # Tekilleştirme KALDIRILDI - Her Program Kodu benzersizdir
    # Sadece aynı kodlu kayıtlar varsa (çok nadir) onları temizle
    if 'code' in df_final.columns:
        # Aynı kodlu kayıtlar varsa, en yüksek puanlı olanı tut
        if 'min_score' in df_final.columns:
            df_final = df_final.sort_values(by='min_score', ascending=False, na_position='last')
        df_final = df_final.drop_duplicates(subset=['code'], keep='first')
    else:
        # Code yoksa (çok nadir), sadece sırala
        if 'min_score' in df_final.columns:
            df_final = df_final.sort_values(by='min_score', ascending=False, na_position='last')
    
    # OTONOM DOĞRULAMA
    verification_passed = verify_data(df_final)
    
    if not verification_passed:
        print("\n⚠️  Doğrulama başarısız! Veriler kaydedilmeyecek.")
        sys.exit(1)
    
    # JSON'a kaydet
    df_final.to_json(OUTPUT_FILE, orient='records', force_ascii=False, indent=2)
    print(f"\n💾 Saved to: {OUTPUT_FILE}")
    
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
        # seed_db.py scriptini çağır
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

