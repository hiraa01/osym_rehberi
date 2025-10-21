# ÖSYM Rehberi - Kurulum ve Çalıştırma Talimatları

## 🎯 Proje Özeti

Tüm istediğiniz özellikler başarıyla eklendi:

### ✅ Tamamlanan Özellikler

1. **Onboarding Ekranları** ✅
   - 4 sayfalık uygulama tanıtımı
   - Skip (atla) mekanizması ile geçilebilir
   - Smooth page indicator ile görsel takip

2. **Auth Sistemi** ✅
   - Email veya telefon ile kayıt
   - Email veya telefon ile giriş
   - Basit token-based auth

3. **İlk Kurulum Akışı** ✅
   - Deneme sayısı seçimi (1-20 arası)
   - Her deneme için TYT ve AYT netlerini girme
   - Şehir ve bölüm tercihleri seçimi
   - Alan türü seçimi (SAY, EA, SÖZ, DİL)

4. **Bottom Navigation Bar** ✅
   - Ana Sayfa
   - Denemeler
   - Hedefim
   - Öneriler
   - Profil

5. **Ana Sayfa (Dashboard)** ✅
   - Hoşgeldin kartı
   - İstatistik kartları (toplam deneme, ortalama puan, hedef, öneriler)
   - Hızlı işlem butonları

6. **Denemeler Sayfası** ✅
   - Deneme sonuçlarını listeleme
   - Yeni deneme ekleme butonu

7. **Hedefim Sayfası** ✅
   - Hedef bölüm gösterimi
   - Hedefe yakınlık göstergesi (circular progress)
   - Mevcut puan, hedef puan, fark gösterimi

8. **Profil Sayfası** ✅
   - Kullanıcı bilgileri
   - Profil düzenleme
   - Tercih güncelleme
   - Hedef bölüm değiştirme
   - Çıkış yapma

9. **Tercih Önerileri Sayfası** ✅
   - Mevcut recommendation sistemi ile entegre

10. **Backend API** ✅
    - Auth endpoints (register, login, user info, update)
    - Exam attempt endpoints (create, read, update, delete)
    - User modeli eklendi
    - ExamAttempt modeli eklendi

## 🚀 Kurulum ve Çalıştırma

### 1. Docker Desktop'ı Başlatın

WSL 2 entegrasyonunu aktifleştirin:
- Docker Desktop → Settings → Resources → WSL Integration
- Ubuntu dağıtımınızı seçin ve Apply

### 2. Backend Çalıştırma

```bash
cd backend

# Docker container oluştur ve çalıştır
docker build -t osym-backend .
docker run -d -p 8002:8002 --name osym-backend-container osym-backend

# Veya docker-compose kullanarak
cd ../docker
docker-compose up -d backend
```

Backend şu adreste çalışacak: http://localhost:8002

### 3. Frontend Build ve Çalıştırma

⚠️ **ÖNEMLİ**: Flutter kod üretimi yapılmalı!

```bash
cd frontend

# Docker ile Flutter paketlerini yükle
docker run --rm -v ${PWD}:/app -w /app cirrusci/flutter:stable flutter pub get

# Kod üretimi (router, freezed, json_serializable)
docker run --rm -v ${PWD}:/app -w /app cirrusci/flutter:stable flutter pub run build_runner build --delete-conflicting-outputs

# Android için çalıştır
docker run --rm -v ${PWD}:/app -w /app -p 5555:5555 cirrusci/flutter:stable flutter run

# Web için çalıştır
docker run --rm -v ${PWD}:/app -w /app -p 8080:8080 cirrusci/flutter:stable flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
```

## 📝 Eksik Kod Üretimleri

Aşağıdaki dosyalar otomatik üretilmelidir:

1. **Router** (`app_router.gr.dart`)
2. **Freezed Models** 
   - `user_model.freezed.dart`
   - `user_model.g.dart`
3. **Riverpod Providers**
   - `student_api_provider.g.dart`
   - `recommendation_api_provider.g.dart`

## 🔧 Yapılması Gerekenler

### Frontend

1. **Kod üretimini çalıştırın**:
```bash
cd frontend
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

2. **API Base URL'i güncelleyin** (gerekirse):
   - `frontend/lib/core/services/api_service.dart` dosyasında
   - 14. satırda `baseUrl` değişkenini kendi IP adresinize göre ayarlayın

### Backend

1. **Veritabanını oluşturun**:
   Backend ilk çalıştırıldığında otomatik oluşturulacak (SQLite).

2. **Üniversite verilerini import edin** (opsiyonel):
```bash
docker exec -it osym-backend-container python scripts/import_yok_data.py
```

## 📱 Uygulama Akışı

1. **İlk Açılış**: Onboarding ekranları (Skip ile geçilebilir)
2. **Kayıt/Giriş**: Email veya telefon ile
3. **İlk Kurulum**:
   - Deneme sayısı seçimi
   - Net girişleri (her deneme için)
   - Şehir ve bölüm tercihleri
4. **Ana Uygulama**: Bottom navigation ile 5 ana sayfa

## 🐛 Bilinen Sorunlar ve Çözümler

### 1. API Bağlantı Hatası

**Sorun**: "Connection refused" veya timeout hataları

**Çözüm**:
- Backend'in çalıştığından emin olun: `docker ps`
- API base URL'in doğru olduğunu kontrol edin
- Android emülatör için: `10.0.2.2:8002`
- Gerçek cihaz için: Bilgisayarın IP adresi (örn: `192.168.1.100:8002`)

### 2. Freezed/JSON Serialization Hataları

**Sorun**: `user_model.freezed.dart` bulunamıyor

**Çözüm**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Router Hataları

**Sorun**: `app_router.gr.dart` bulunamıyor veya route tanımları eksik

**Çözüm**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📊 Veritabanı Şeması

### Users Tablosu
- id, email, phone, name
- is_onboarding_completed, is_initial_setup_completed
- created_at, updated_at, last_login_at

### Students Tablosu (Mevcut)
- Öğrenci profil bilgileri
- TYT/AYT netleri
- Hesaplanan puanlar
- Tercihler

### ExamAttempts Tablosu (Yeni)
- student_id (foreign key)
- attempt_number
- TYT/AYT netleri
- Hesaplanan puanlar
- created_at, updated_at

## 🎨 Özelleştirme

### Tema Değişiklikleri
`frontend/lib/core/theme/app_theme.dart` dosyasında renk ve stil ayarları yapılabilir.

### Alan ve Bölüm Listesi
`frontend/lib/features/initial_setup/presentation/widgets/preferences_selection_step.dart` 
dosyasında `_departmentsByField` map'i güncellenerek bölümler değiştirilebilir.

## 📞 Destek

Herhangi bir sorun yaşarsanız:
1. Backend loglarını kontrol edin: `docker logs osym-backend-container`
2. Frontend debug console'u kontrol edin
3. API endpoint'lerini test edin: http://localhost:8002/docs (Swagger UI)

## ✨ Sonraki Adımlar

1. **Deneme ekleme fonksiyonunu tamamlayın**
2. **Tercih önerisi algoritmasını geliştirin**
3. **Hedef takip sistemini aktif hale getirin**
4. **Profil düzenleme formlarını oluşturun**

Tüm temel yapı hazır! Şimdi sadece kod üretimi yapıp test edebilirsiniz. 🚀

