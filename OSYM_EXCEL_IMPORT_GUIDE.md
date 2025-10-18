# ÖSYM Excel Verilerini İçe Aktarma Rehberi

## 📥 Adım 1: Excel Dosyalarını İndir

### ÖSYM'den İndirme:
1. **ÖSYM Atlas** sitesine git: https://yokatlas.yok.gov.tr/
2. **"Geçmiş Yıllar"** bölümüne tıkla
3. İstediğin yılları seç (örn: 2024, 2023, 2022, 2021)
4. **Excel formatında** indir

### Alternatif Kaynaklar:
- ÖSYM resmi sitesi: https://www.osym.gov.tr/
- "Yerleştirme Sonuçları" veya "İstatistikler" bölümü
- **Önlisans** ve **Lisans** için ayrı dosyalar olabilir

## 📂 Adım 2: Dosyaları Yerleştir

```bash
# Docker kullanıyorsanız:
mkdir -p backend/data
cp ~/Downloads/2024_yerlestirme.xlsx backend/data/
cp ~/Downloads/2023_yerlestirme.xlsx backend/data/
cp ~/Downloads/2022_yerlestirme.xlsx backend/data/
cp ~/Downloads/2021_yerlestirme.xlsx backend/data/
```

## 🔧 Adım 3: Pandas Kütüphanesini Ekle

```bash
# requirements.txt'e ekle
echo "pandas==2.1.3" >> backend/requirements.txt
echo "openpyxl==3.1.2" >> backend/requirements.txt  # Excel okumak için
```

**VEYA** hızlıca Docker container'da:
```bash
docker exec osym_rehberi_backend pip install pandas openpyxl
```

## ▶️ Adım 4: Import Scriptini Çalıştır

```bash
# Docker ile:
docker exec osym_rehberi_backend python scripts/import_osym_excel.py

# Lokal Python ile:
cd backend
python scripts/import_osym_excel.py
```

## 📊 Beklenen Çıktı

```
======================================================================
ÖSYM EXCEL DOSYALARINI İÇE AKTAR
======================================================================
📂 4 Excel dosyası bulundu:
   - 2024_yerlestirme.xlsx
   - 2023_yerlestirme.xlsx
   - 2022_yerlestirme.xlsx
   - 2021_yerlestirme.xlsx

📁 2024_yerlestirme.xlsx işleniyor (Yıl: 2024)...
   📊 42,583 satır bulundu
   ⏳ 1000 satır işlendi...
   ⏳ 2000 satır işlendi...
   ...
   ✅ 185 yeni üniversite, 42,583 yeni bölüm eklendi!

📁 2023_yerlestirme.xlsx işleniyor (Yıl: 2023)...
   📊 41,204 satır bulundu
   ...

======================================================================
✅ İMPORT TAMAMLANDI!
======================================================================
📊 Toplam: 195 üniversite, 165,821 bölüm eklendi
💾 Database'de: 195 üniversite, 165,821 bölüm
======================================================================
```

## ⚠️ Sık Karşılaşılan Sorunlar

### 1. Excel Formatı Farklı
**Hata**: `Eksik kolonlar: ['PROGRAM ADI']`

**Çözüm**: 
- Excel'i aç ve kolon adlarını kontrol et
- `import_osym_excel.py` dosyasındaki `COLUMN_MAPPING` sözlüğünü güncelle
- Örnek:
  ```python
  COLUMN_MAPPING = {
      'Program Adı': 'name',  # ÖSYM'de böyle yazıyorsa
      'Üniversite Adı': 'university_name',
      # ...
  }
  ```

### 2. Türkçe Karakter Problemi
**Çözüm**: Excel'i UTF-8 olarak kaydet veya script'te encoding belirt:
```python
df = pd.read_excel(file_path, sheet_name=0, encoding='utf-8')
```

### 3. Çok Yavaş Çalışıyor
**Çözüm**: Batch size'ı artır (script'te `1000` olan değeri `5000` yap)

## 📈 Performans ve Yer Kullanımı

| Yıl Sayısı | Kayıt Sayısı | Database Boyutu | RAM Kullanımı |
|------------|--------------|-----------------|---------------|
| 1 yıl      | ~40,000      | ~30 MB          | ~100 MB       |
| 4 yıl      | ~160,000     | ~120 MB         | ~300 MB       |
| 10 yıl     | ~400,000     | ~280 MB         | ~700 MB       |

**Sonuç**: ✅ Mobil uygulamalar için tamamen uygun!

## 🔍 Veri Kalitesi Kontrolü

Import sonrası kontrol et:
```bash
# Database'deki üniversiteleri listele
docker exec osym_rehberi_backend python -c "
from database import SessionLocal
from models.university import University
db = SessionLocal()
unis = db.query(University).limit(10).all()
for u in unis:
    print(f'{u.name} - {u.city}')
db.close()
"
```

## 💡 İpuçları

1. **İlk test için 1 yıl kullan** (hızlı test için)
2. **Sonra 4 yıl ekle** (gerçek uygulama için)
3. **Excel'i önce manuel kontrol et** (kolonlar doğru mu?)
4. **Duplicate kayıtları temizle** (script otomatik yapıyor)
5. **Güncellemelerde eski verileri korur** (üzerine yazar)

## 🚀 Bonus: Otomatik Güncelleme

Her yıl ÖSYM verileri yayınlandığında:
```bash
# 1. Yeni Excel'i indir
cp ~/Downloads/2025_yerlestirme.xlsx backend/data/

# 2. Sadece yeni veriyi ekle (eski veriler korunur)
docker exec osym_rehberi_backend python scripts/import_osym_excel.py
```

## 📞 Destek

Sorun yaşarsan:
1. Excel dosyasının ilk 5 satırını incele
2. Kolon adlarını kontrol et
3. Script'teki `COLUMN_MAPPING`'i güncelle
4. Test et!

