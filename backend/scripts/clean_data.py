import pandas as pd
import os
import re
import logging
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

def clean_program_name(name: str, preserve_parentheses: bool = True) -> str:
    """Program adını temizler. preserve_parentheses=True ise parantez içlerini KORUR."""
    if is_na_value(name):
        return ""
    
    name = str(name).strip()
    # Sadece gereksiz boşlukları temizle
    name = re.sub(r'\s+', ' ', name)
    
    # Parantez içlerini KORU (Burslu, Ücretli, İngilizce vb. için)
    # Sadece çok gereksiz karakterleri temizle
    return name.strip()

def get_normalized_name(name: str) -> str:
    """Normalized name oluşturur - basit lowercase."""
    if is_na_value(name):
        return ""
    return str(name).lower().strip()

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
# 🔍 SÜTUN İNDEKS TESPİTİ
# ---------------------------------------------------------
def find_column_indices(df: pd.DataFrame) -> Dict[str, Optional[int]]:
    """İlk 20 satırda sütun başlıklarını bulur."""
    indices: Dict[str, Optional[int]] = {
        'code': 0,  # Program Kodu - varsayılan 0
        'name': 1,  # Program Adı - varsayılan 1
        'duration': 2,
        'field_type': 3,
        'quota': 4,
        'min_score': 12,  # En Küçük Puan - varsayılan 12
        'header_row': -1
    }
    
    for i in range(min(20, len(df))):
        row_values = [str(x).lower() if not is_na_value(x) else "" for x in df.iloc[i].values]
        row_str = " ".join(row_values)
        
        if 'program kodu' in row_str or 'program adı' in row_str or 'puan türü' in row_str:
            indices['header_row'] = i
            
            for j, val in enumerate(row_values):
                val_lower = str(val).lower().strip()
                
                if 'program kodu' in val_lower:
                    indices['code'] = j
                elif 'program adı' in val_lower or 'bölüm adı' in val_lower:
                    indices['name'] = j
                elif 'süre' in val_lower:
                    indices['duration'] = j
                elif 'puan türü' in val_lower or 'puan tür' in val_lower:
                    indices['field_type'] = j
                elif 'kontenjan' in val_lower:
                    indices['quota'] = j
                elif 'en küçük puan' in val_lower or 'taban puan' in val_lower or 'min puan' in val_lower:
                    indices['min_score'] = j
            
            logger.info(f"  Header row found at line {i}")
            break
    
    return indices

# ---------------------------------------------------------
# 🚀 STATE MACHINE - HİYERARŞİK OKUMA (VERİ KAYBI YOK)
# ---------------------------------------------------------
def process_hierarchical_file(filepath: str, filename: str) -> List[Dict]:
    """Hiyerarşik Excel dosyasını işler - VERİ KAYBI YOK."""
    logger.info(f"Processing file: {filename}")
    
    all_programs: List[Dict] = []
    
    # STATE MACHINE DEĞİŞKENLERİ
    current_university: str = ""
    current_uni_type: str = "state"
    
    # Dosyayı header olmadan oku
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
    
    # Sütun indekslerini bul
    col_indices = find_column_indices(df)
    
    # Sütun indekslerini güvenli şekilde al
    col_code_idx = col_indices.get('code', 0) or 0
    col_name_idx = col_indices.get('name', 1) or 1
    col_duration_idx = col_indices.get('duration', 2) or 2
    col_field_type_idx = col_indices.get('field_type', 3) or 3
    col_quota_idx = col_indices.get('quota', 4) or 4
    col_min_score_idx = col_indices.get('min_score', 12) or 12
    
    header_row = col_indices.get('header_row', -1)
    start_row = (header_row + 1) if header_row is not None and header_row >= 0 else 0
    
    degree_type = determine_degree_type(filename)
    
    logger.info(f"  Starting from row {start_row}, degree_type: {degree_type}")
    
    # SAYAÇLAR (Eğitim Modu)
    total_rows_with_code = 0
    total_saved = 0
    
    # STATE MACHINE DÖNGÜSÜ - Satır satır işle
    for idx in range(start_row, len(df)):
        row = df.iloc[idx]
        
        # Col 0 ve Col 1 değerlerini al
        col0_value = safe_get_value(row, col_code_idx, "")
        col1_value = safe_get_value(row, col_name_idx, "")
        
        # ADIM A: Üniversite Başlığını Yakala
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
        
        # ADIM C: Bölüm Verisini Yakala - PROGRAM KODU ESASLI
        # Eğer Program Kodu varsa -> MUTLAKA KAYDET
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
            program_name_original = clean_program_name(program_name_raw, preserve_parentheses=True)
            
            # Normalized name oluştur (arama için)
            normalized_name = program_name_original.lower().strip()
            
            # Diğer bilgileri al
            duration_raw = safe_get_value(row, col_duration_idx, None)
            field_type_raw = safe_get_value(row, col_field_type_idx, None)
            quota_raw = safe_get_value(row, col_quota_idx, "0")
            min_score_raw = safe_get_value(row, col_min_score_idx, None)
            
            # Değerleri belirle (override kuralları)
            field_type = determine_field_type(program_name_original, field_type_raw, degree_type, filename)
            duration = determine_duration(program_name_original, duration_raw, field_type, degree_type)
            
            # Sayısal değerleri çevir
            quota = safe_get_numeric(quota_raw, 0)
            min_score = safe_get_numeric(min_score_raw, None)  # None olabilir - ASLA ATMA
            
            # Kayıt oluştur - HER PROGRAM KODU KAYDEDİLİR
            program_data = {
                'name': program_name_original,  # Orijinal isim (parantezli)
                'normalized_name': normalized_name,
                'university': current_university,
                'university_type': current_uni_type,
                'field_type': field_type,
                'duration': duration,
                'degree_type': degree_type,
                'quota': quota,
                'min_score': min_score,  # None olabilir
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
    print("📊 HİYERARŞİK EXCEL İŞLEME (VERİ KAYBI YOK - MIRRORING)")
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
            programs = process_hierarchical_file(filepath, filename)
            all_data.extend(programs)
            print(f"   ✅ {len(programs)} programs extracted\n")
        except Exception as e:
            logger.error(f"Error processing {filename}: {e}", exc_info=True)
            print(f"   ❌ Error: {e}\n")
    
    # Kaydetme
    if not all_data:
        print("❌ No data extracted.")
        return
    
    df_final = pd.DataFrame(all_data)
    
    # TEKİLLEŞTİRME YOK - Her Program Kodu benzersizdir
    # Sadece aynı kodlu kayıtlar varsa (çok nadir) onları temizle
    initial_count = len(df_final)
    if 'code' in df_final.columns:
        if 'min_score' in df_final.columns:
            df_final = df_final.sort_values(by='min_score', ascending=False, na_position='last')
        df_final = df_final.drop_duplicates(subset=['code'], keep='first')
        final_count = len(df_final)
        if initial_count != final_count:
            print(f"   ⚠️  {initial_count - final_count} duplicate code removed")
    
    # İstatistikler
    print("-" * 60)
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

if __name__ == "__main__":
    main()
