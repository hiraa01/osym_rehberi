# 🎓 ÖSYM Rehberi - Yapay Zeka Destekli Üniversite Tercih Sistemi

## 📱 Proje Hakkında

ÖSYM Rehberi, YKS'ye hazırlanan öğrenciler için yapay zeka destekli bir üniversite tercih öneri sistemidir. Öğrenciler deneme sonuçlarını girerek, hedefledikleri şehir ve bölümlere göre kendilerine en uygun tercih önerilerini alabilirler.

## ✨ Özellikler

### 🎯 Kullanıcı Özellikleri

- **Onboarding Ekranları**: 4 sayfalık uygulama tanıtımı (Skip ile geçilebilir)
- **Kayıt/Giriş**: Email veya telefon numarası ile kolay kayıt
- **İlk Kurulum Asistanı**:
  - Deneme sayısı seçimi
  - Her deneme için detaylı net girişi (TYT + AYT)
  - Şehir ve bölüm tercihleri
  - Alan türü seçimi (SAY, EA, SÖZ, DİL)
- **Dashboard**: 
  - Genel istatistikler
  - Toplam deneme sayısı
  - Ortalama puan
  - Hedef takibi
- **Deneme Takibi**: Tüm deneme sonuçlarını kaydetme ve izleme
- **Hedefim**: Hedef bölüme ne kadar yakın olduğunuzu görsel olarak takip
- **Profil Yönetimi**: Bilgilerinizi güncelleyin, tercihlerinizi değiştirin
- **Tercih Önerileri**: Yapay zeka destekli kişiselleştirilmiş öneriler

### 🔧 Teknik Özellikler

- **Backend**: FastAPI (Python)
- **Frontend**: Flutter (Cross-platform: Android, iOS, Web)
- **Veritabanı**: SQLite (Development), PostgreSQL (Production ready)
- **State Management**: Riverpod
- **API**: RESTful API with Swagger documentation
- **Containerization**: Docker & Docker Compose

## 🚀 Kurulum

### Gereksinimler

- Docker Desktop (Windows/Mac/Linux)
- WSL 2 (Windows kullanıcıları için)
- Flutter SDK (opsiyonel, Docker ile de çalışır)

### 1. Backend Kurulumu

```bash
# Backend dizinine gidin
cd backend

# Docker image oluşturun
docker build -t osym-backend .

# Container'ı başlatın
docker run -d -p 8002:8002 --name osym-backend osym-backend

# Veya docker-compose ile
cd ../docker
docker-compose up -d backend
```

Backend şu adreste çalışacak:
- API: http://localhost:8002
- Swagger Docs: http://localhost:8002/docs

### 2. Frontend Kurulumu

#### Docker ile (Önerilen)

```bash
cd frontend

# Paketleri yükle
docker run --rm -v ${PWD}:/app -w /app cirrusci/flutter:stable flutter pub get

# Uygulamayı çalıştır
docker run --rm -v ${PWD}:/app -w /app cirrusci/flutter:stable flutter run
```

#### Flutter SDK ile

```bash
cd frontend

# Paketleri yükle
flutter pub get

# Uygulamayı çalıştır
flutter run

# Web için
flutter run -d chrome

# Android için
flutter run -d android

# iOS için (Mac gerekli)
flutter run -d ios
```

## 📚 Kullanım

### İlk Kullanım

1. **Onboarding**: Uygulama açıldığında karşınıza 4 sayfalık tanıtım gelir. "Atla" butonu ile geçebilirsiniz.

2. **Kayıt Olun**: Email veya telefon numaranız ile kayıt olun.

3. **İlk Kurulum**:
   - Kaç deneme gireceğinizi seçin (1-20 arası)
   - Her deneme için TYT ve AYT netlerinizi girin
   - Tercih ettiğiniz şehirleri seçin
   - İlgilendiğiniz bölümleri seçin

4. **Ana Uygulamayı Kullanın**: Bottom navigation ile 5 ana bölüm arasında geçiş yapın.

### Ana Sayfalar

#### 🏠 Ana Sayfa (Dashboard)
- Genel istatistiklerinizi görün
- Hızlı işlem butonları ile deneme ekleyin veya önerileri inceleyin

#### 📝 Denemeler
- Tüm deneme sonuçlarınızı listeleyin
- Yeni deneme ekleyin
- Geçmiş denemeleri düzenleyin veya silin

#### 🎯 Hedefim
- Hedef bölümünüzü belirleyin
- Hedefe ne kadar yakın olduğunuzu görün (circular progress)
- Mevcut puan, hedef puan ve fark bilgilerini takip edin

#### 💡 Tercih Önerileri
- Yapay zeka tarafından üretilen kişiselleştirilmiş öneriler
- Şehir ve bölüm tercihlerinize göre filtreleme
- Üniversite ve bölüm detayları

#### 👤 Profil
- Kişisel bilgilerinizi düzenleyin
- Tercihlerinizi güncelleyin
- Hedef bölümünüzü değiştirin
- Uygulamadan çıkış yapın

## 🔌 API Endpoints

### Auth
- `POST /api/auth/register` - Yeni kullanıcı kaydı
- `POST /api/auth/login` - Kullanıcı girişi
- `GET /api/auth/me/{user_id}` - Kullanıcı bilgisi
- `PUT /api/auth/me/{user_id}` - Kullanıcı güncelleme

### Exam Attempts
- `POST /api/exam-attempts/` - Yeni deneme ekleme
- `GET /api/exam-attempts/student/{student_id}` - Öğrenci denemeleri
- `PUT /api/exam-attempts/{attempt_id}` - Deneme güncelleme
- `DELETE /api/exam-attempts/{attempt_id}` - Deneme silme

### Students
- `POST /api/students/` - Öğrenci profili oluşturma
- `GET /api/students/` - Öğrenci listesi
- `GET /api/students/{id}` - Öğrenci detayı
- `PUT /api/students/{id}` - Öğrenci güncelleme

### Universities
- `GET /api/universities/` - Üniversite listesi
- `GET /api/universities/cities` - Şehir listesi
- `GET /api/universities/departments` - Bölüm listesi

### Recommendations
- `POST /api/recommendations/generate/{student_id}` - Öneri oluşturma
- `GET /api/recommendations/student/{student_id}` - Öğrenci önerileri
- `GET /api/recommendations/stats/{student_id}` - Öneri istatistikleri

## 🗄️ Veritabanı Şeması

### Users
- Kullanıcı bilgileri
- Auth durumu
- Onboarding ve setup tamamlanma bilgisi

### Students
- Öğrenci profil bilgileri
- TYT/AYT netleri
- Hesaplanan puanlar
- Tercih bilgileri

### ExamAttempts
- Deneme sonuçları
- Her deneme için ayrı kayıt
- TYT/AYT netleri
- Hesaplanan puanlar

### Universities
- YÖK Atlas verileri
- Üniversite bilgileri
- Bölüm bilgileri
- Taban puanlar

## 🎨 Ekran Görüntüleri

```
📱 Onboarding → 🔐 Auth → ⚙️ İlk Kurulum → 🏠 Dashboard → 📊 Ana Uygulama
```

## 🐛 Sorun Giderme

### Backend Bağlantı Hatası

```bash
# Backend loglarını kontrol edin
docker logs osym-backend

# Backend'i yeniden başlatın
docker restart osym-backend

# Backend'in çalıştığını kontrol edin
curl http://localhost:8002/health
```

### Flutter Build Hataları

```bash
# Önbelleği temizleyin
flutter clean

# Paketleri yeniden yükleyin
flutter pub get

# Uygulamayı çalıştırın
flutter run
```

### API URL Ayarları

`frontend/lib/core/services/api_service.dart` dosyasında:

```dart
const String baseUrl = kIsWeb 
    ? 'http://localhost:8002/api'  // Web için
    : 'http://10.0.2.2:8002/api';  // Android emülatör için

// Gerçek cihaz için bilgisayarın IP adresini kullanın
// : 'http://192.168.1.100:8002/api';
```

## 📝 Geliştirme Notları

### Kod Stili

- Backend: PEP 8
- Frontend: Flutter/Dart style guide
- Tüm fonksiyonlar ve class'lar dokümante edilmiş
- Type safety (Python type hints + Dart strong typing)

### Logging

- Backend: `logging` modülü
- Frontend: `debugPrint()` ve custom logger
- Tüm API istekleri ve hatalar loglanır

### Test

```bash
# Backend testleri
cd backend
pytest

# Frontend testleri
cd frontend
flutter test
```

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'feat: Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 👨‍💻 Geliştirici

**Hira** - ÖSYM Rehberi

## 🙏 Teşekkürler

- YÖK Atlas verilerini kullandığımız için teşekkürler
- Flutter ve FastAPI topluluklarına teşekkürler

## 📞 İletişim

Sorularınız veya önerileriniz için:
- Issue açın
- Pull request gönderin

---

**Not**: Bu uygulama eğitim amaçlıdır ve resmi ÖSYM/YÖK uygulaması değildir.

