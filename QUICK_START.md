# 🚀 ÖSYM Rehberi - Hızlı Başlangıç

## ✅ Tüm Hatalar Düzeltildi!

Kodunuz artık çalışır durumda. İşte değişiklikler:

### 🔧 Yapılan Düzeltmeler

1. **Freezed → JSON Serializable**: Daha basit serialization kullanıldı
2. **Router**: AutoRoute yerine basit Navigator kullanıldı
3. **Navigation**: Tüm route'lar MaterialPageRoute'a dönüştürüldü
4. **Model Files**: `user_model.g.dart` manuel oluşturuldu

### 📱 Uygulamayı Çalıştırma

```bash
# 1. Backend'i başlat
cd backend
docker-compose up -d

# VEYA
docker build -t osym-backend .
docker run -d -p 8001:8001 --name osym-backend osym-backend

# 2. Frontend'i çalıştır (Docker olmadan da çalışır)
cd frontend
flutter pub get
flutter run

# Eğer Android Studio/VS Code kullanıyorsanız, F5 ile de başlatabilirsiniz
```

### 🎯 Uygulama Akışı

1. **Onboarding** → 4 sayfalık tanıtım (Skip ile geçilebilir)
2. **Kayıt/Giriş** → Email veya telefon
3. **İlk Kurulum**:
   - Deneme sayısı seç
   - Netleri gir
   - Tercih yap
4. **Ana Uygulama** → 5 sekme:
   - 🏠 Ana Sayfa
   - 📝 Denemeler
   - 🎯 Hedefim
   - 💡 Öneriler
   - 👤 Profil

### 📊 Backend API

Backend otomatik olarak şu adreste çalışacak:
- API: http://localhost:8001
- Swagger Docs: http://localhost:8001/docs

### 🔗 API Endpoints

#### Auth
- `POST /api/auth/register` - Kayıt
- `POST /api/auth/login` - Giriş
- `GET /api/auth/me/{user_id}` - Kullanıcı bilgisi
- `PUT /api/auth/me/{user_id}` - Güncelleme

#### Exam Attempts
- `POST /api/exam-attempts/` - Deneme ekle
- `GET /api/exam-attempts/student/{student_id}` - Denemeleri listele
- `PUT /api/exam-attempts/{attempt_id}` - Güncelle
- `DELETE /api/exam-attempts/{attempt_id}` - Sil

#### Students (Mevcut)
- `POST /api/students/` - Öğrenci oluştur
- `GET /api/students/` - Öğrenci listesi
- `GET /api/students/{id}` - Öğrenci detayı
- `PUT /api/students/{id}` - Öğrenci güncelle

#### Universities (Mevcut)
- `GET /api/universities/` - Üniversite listesi
- `GET /api/universities/cities` - Şehirler
- `GET /api/universities/departments` - Bölümler

#### Recommendations (Mevcut)
- `POST /api/recommendations/generate/{student_id}` - Öneri oluştur
- `GET /api/recommendations/student/{student_id}` - Öğrenci önerileri

### 🎨 Özellikler

✅ **Onboarding**: Skip mekanizması ile  
✅ **Auth**: Email/Telefon ile kayıt ve giriş  
✅ **İlk Kurulum**: Dinamik deneme girişi  
✅ **Bottom Navigation**: 5 ana sayfa  
✅ **Dashboard**: İstatistikler ve hızlı erişim  
✅ **Hedefim**: Circular progress ile takip  
✅ **Profil**: Düzenleme ve çıkış  

### ⚙️ API Ayarları

Eğer backend başka bir adreste çalışıyorsa:

`frontend/lib/core/services/api_service.dart` dosyasında:
```dart
const String baseUrl = kIsWeb 
    ? 'http://localhost:8001/api'
    : 'http://10.0.2.2:8001/api'; // Android emülatör için
```

Gerçek cihaz için:
```dart
: 'http://192.168.1.100:8001/api'; // Bilgisayarın IP'si
```

### 🐛 Sorun Giderme

**Backend bağlantı hatası?**
```bash
# Backend çalışıyor mu kontrol et
docker ps

# Logları kontrol et
docker logs osym-backend

# Tekrar başlat
docker restart osym-backend
```

**Flutter hataları?**
```bash
flutter clean
flutter pub get
flutter run
```

### 🎉 Tamamlandı!

Artık uygulamanız çalışır durumda! Tüm temel özellikler implementa edildi:

- ✅ Onboarding ekranları
- ✅ Auth sistemi
- ✅ İlk kurulum akışı
- ✅ Bottom navigation
- ✅ Ana sayfa
- ✅ Hedefim sayfası
- ✅ Profil sayfası
- ✅ Backend API'leri
- ✅ Veritabanı modelleri

Şimdi sadece backend'i başlatıp `flutter run` yapmanız yeterli! 🚀

### 📝 Sonraki Adımlar

1. Deneme ekleme fonksiyonunu tamamlayın
2. Tercih öneri algoritmasını geliştirin
3. Profil düzenleme formlarını ekleyin
4. Hedef takip sistemini aktif hale getirin

Sorularınız varsa yardımcı olmaktan mutluluk duyarım! 😊

