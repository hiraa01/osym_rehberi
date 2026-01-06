# PostgreSQL Volume Düzeltme Rehberi

## 🔍 Durum Analizi

`docker-compose.yml` dosyasında PostgreSQL için kalıcı volume tanımı **zaten mevcut**:
- ✅ `postgres_data:/var/lib/postgresql/data` volume tanımı var (satır 67)
- ✅ `volumes:` bloğunda `postgres_data:` tanımlı (satır 134)

Ancak veriler kayboluyorsa, muhtemelen:
1. `docker-compose down -v` komutu kullanılmış (volume'ları siler)
2. Container'lar yeniden oluşturulurken volume bağlantısı kopmuş
3. Volume başka bir isimle oluşturulmuş

## 🛠️ Çözüm: Volume'u Yeniden Bağlama

### Adım 1: Mevcut Konteynerleri ve Volume'ları Kontrol Et

```powershell
# Mevcut volume'ları listele
docker volume ls

# PostgreSQL volume'unu kontrol et
docker volume inspect osym_rehberi_postgres_data
```

### Adım 2: Eski Konteynerleri Durdur (Volume'ları SİLME!)

```powershell
# ⚠️ ÖNEMLİ: -v parametresi OLMADAN durdur (volume'ları korur)
docker-compose -f docker/docker-compose.yml down
```

### Adım 3: Volume'u Kontrol Et

```powershell
# Volume hala var mı kontrol et (PowerShell için)
docker volume ls | Select-String postgres_data

# Veya daha detaylı:
docker volume ls
```

Eğer volume yoksa, yeni bir tane oluşturulacak (veriler kaybolur).
Eğer volume varsa, veriler korunacak.

### Adım 4: Yeni Ayarlarla Başlat

```powershell
# docker klasörüne git
cd docker

# Yeni ayarlarla başlat (volume otomatik bağlanacak)
docker-compose up -d --build
```

### Adım 5: Veritabanını Kontrol Et ve Gerekirse Yeniden Oluştur

```powershell
# Veritabanı bağlantısını test et
docker exec -it osym_rehberi_backend python -c "from database import engine; print('DB OK' if engine else 'DB FAIL')"

# Eğer veritabanı boşsa, tabloları ve admin kullanıcısını oluştur
docker exec -it osym_rehberi_backend python scripts/init_full_system.py
```

## ⚠️ KRİTİK: Verileri Kaybetmemek İçin

### ❌ YAPMAYIN:
```powershell
# Bu komut volume'ları da siler!
docker-compose down -v
```

### ✅ YAPIN:
```powershell
# Bu komut sadece container'ları durdurur, volume'ları korur
docker-compose down
```

## 🔄 Volume'u Tamamen Sıfırlamak İsterseniz (Tüm Veriler Silinir!)

```powershell
# 1. Container'ları durdur
docker-compose -f docker/docker-compose.yml down

# 2. Volume'u sil
docker volume rm osym_rehberi_postgres_data

# 3. Yeniden başlat (yeni boş volume oluşturulur)
cd docker
docker-compose up -d --build

# 4. Veritabanını yeniden oluştur
docker exec -it osym_rehberi_backend python scripts/init_full_system.py
```

## 📊 Volume Durumunu Kontrol Etme

```powershell
# Volume'ları listele
docker volume ls

# PostgreSQL volume'unu filtrele (PowerShell için)
docker volume ls | Select-String postgres_data

# Volume detaylarını görüntüle
docker volume inspect osym_rehberi_postgres_data

# Volume boyutunu kontrol et
docker system df -v
```

## 🎯 Sonuç

Artık `postgres_data` volume'u kalıcı olarak tanımlı. Container'lar silinse bile veriler korunacak.

**Önemli Not:** Volume'lar Docker'ın kendi dosya sisteminde saklanır. Bilgisayarı kapatsanız bile veriler korunur. Sadece `docker volume rm` komutu ile volume'u silerseniz veriler kaybolur.

