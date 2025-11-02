# Veritabanı Bilgisi

## 🗄️ Veri Saklama Yeri

**Tüm veriler Docker container'ında saklanıyor.**

### Veritabanı Türü
- **Geliştirme ortamı**: SQLite (dosya tabanlı)
- **Production ortamı**: PostgreSQL (container tabanlı)

### Veri Saklama Konumu

1. **SQLite Database** (Şu anki durum):
   - Dosya: `backend/osym_rehber.db`
   - Konum: Docker container içinde `/app/osym_rehber.db`
   - Volume: `backend_data` volume'unda saklanıyor
   - **Kalıcılık**: ✅ Evet, container silinse bile veriler `backend_data` volume'unda kalır

2. **PostgreSQL Database** (docker-compose.yml'de tanımlı):
   - Container: `osym_rehberi_db`
   - Volume: `postgres_data` volume'unda saklanıyor
   - **Kalıcılık**: ✅ Evet, container silinse bile veriler `postgres_data` volume'unda kalır

### Hangi Veriler Saklanıyor?

1. **Users** (Kullanıcılar):
   - Email, telefon, isim
   - Login bilgileri

2. **Students** (Öğrenciler):
   - Profil bilgileri
   - Sınav sonuçları (TYT/AYT netleri)
   - Tercihler (şehir, üniversite türü, vb.)

3. **Exam Attempts** (Denemeler):
   - Her deneme kaydı
   - Tarih, sınav adı, netler

4. **Recommendations** (Öneriler):
   - Hesaplanan tercih önerileri
   - Skorlar ve kategoriler

5. **Universities & Departments** (Üniversiteler & Bölümler):
   - Tüm üniversite ve bölüm bilgileri

### Veri Yedekleme

Volume'ları kontrol etmek için:
```bash
docker volume ls
docker volume inspect osym_rehberi_backend_data
docker volume inspect osym_rehberi_postgres_data
```

### Verileri Görüntüleme

Backend container içinde:
```bash
docker exec -it osym_rehberi_backend sqlite3 /app/osym_rehber.db
# veya
docker exec -it osym_rehberi_db psql -U osym_user -d osym_rehber
```

### Önemli Notlar

- ✅ Veriler **kalıcıdır** - container silinse bile volume'larda durur
- ✅ Yeni kayıtlar **hemen backend'e** kaydedilir
- ✅ Autosave mekanizması 800ms sonra çalışır
- ✅ Exam attempts cache'de tutulur ama backend'de de kalıcıdır

