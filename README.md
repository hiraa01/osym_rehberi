# ÖSYM Rehberi

Yapay zeka destekli üniversite ve bölüm öneri sistemi. Öğrenci profillerini analiz ederek YÖK Atlas verilerini kullanarak en uygun tercih önerilerini sunar.

## 🎯 Proje Amacı

- Öğrenci profilini ve deneme sonuçlarını analiz etme
- YÖK Atlas verilerini kullanarak bölüm ve üniversite önerisi
- Yapay zeka ile en uygun tercih sıralamasını önerme
- Gelecekte KPSS, DGS, ALES gibi sınavlar için modül genişletilebilir

## 🧱 Teknoloji Yığını

### Backend
- **FastAPI** (Python) - REST API
- **SQLAlchemy** - ORM
- **PostgreSQL** - Veritabanı
- **Pydantic** - Veri validasyonu
- **scikit-learn** - Makine öğrenmesi

### Frontendooo
- **Flutter** (Dart) - Mobil uygulama
- **Riverpod** - Durum yönetimi
- **AutoRoute** - Navigasyon
- **Freezed** - Veri sınıfları
- **Dio** - HTTP istemcisi

### DevOps
- **Docker** & **Docker Compose** - Konteynerleştirme
- **PostgreSQL** - Veritabanı

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
- Docker
- Docker Compose

### Adımlar

1. **Projeyi klonlayın:**
```bash
git clone <repository-url>
cd osym_rehberi
```

2. **Docker konteynerlarını başlatın:**
```bash
cd docker
docker-compose up --build
```

3. **Servislere erişim:**
- Backend API: http://localhost:8002
- Frontend Web: http://localhost:3002
- PostgreSQL: localhost:5435

### API Dokümantasyonu
Backend çalıştıktan sonra Swagger UI'ya erişim:
- http://localhost:8002/docs

## 📁 Proje Yapısı

```
osym_rehberi/
├── backend/                 # FastAPI backend
│   ├── models/             # Veritabanı modelleri
│   ├── schemas/            # Pydantic şemaları
│   ├── routers/            # API endpoint'leri
│   ├── services/           # İş mantığı servisleri
│   ├── main.py             # Ana uygulama
│   ├── database.py         # Veritabanı konfigürasyonu
│   └── requirements.txt    # Python bağımlılıkları
├── frontend/               # Flutter frontend
│   ├── lib/
│   │   ├── core/          # Temel yapı
│   │   └── features/      # Özellik modülleri
│   └── pubspec.yaml       # Flutter bağımlılıkları
├── docker/                # Docker konfigürasyonu
│   └── docker-compose.yml
└── README.md
```

## 🔌 API Endpoints

### Öğrenci Yönetimi
- `POST /api/students/` - Yeni öğrenci oluştur
- `GET /api/students/` - Öğrenci listesi
- `GET /api/students/{id}` - Öğrenci detayı
- `PUT /api/students/{id}` - Öğrenci güncelle
- `DELETE /api/students/{id}` - Öğrenci sil

### Üniversite ve Bölümler
- `GET /api/universities/` - Üniversite listesi
- `GET /api/universities/departments/` - Bölüm listesi
- `GET /api/universities/cities/` - Şehir listesi

### Tercih Önerileri
- `POST /api/recommendations/generate/{student_id}` - Öneri oluştur
- `GET /api/recommendations/student/{student_id}` - Öğrenci önerileri
- `GET /api/recommendations/stats/{student_id}` - Öneri istatistikleri

## 🧠 Öneri Sistemi

Sistem aşağıdaki faktörleri analiz ederek öneriler oluşturur:

1. **Uyumluluk Skoru (40%)**
   - Puan uyumluluğu
   - Sıralama uyumluluğu
   - Alan uyumluluğu

2. **Başarı Olasılığı (40%)**
   - Öğrenci puanı vs bölüm taban puanı
   - Geçmiş yıl verileri

3. **Tercih Skoru (20%)**
   - Şehir tercihi
   - Üniversite türü tercihi
   - Burs tercihi
   - İlgi alanları

## 📊 Veri Kaynakları

- **YÖK Atlas** - Üniversite ve bölüm verileri
- **ÖSYM** - Sınav sonuçları ve istatistikler
- **Üniversiteler** - Kontenjan ve taban puan bilgileri

## 🔮 Gelecek Özellikler

- [ ] KPSS modülü
- [ ] DGS modülü
- [ ] ALES modülü
- [ ] Chatbot rehberlik sistemi
- [ ] Mobil uygulama (Android/iOS)
- [ ] Gelişmiş ML algoritmaları
- [ ] Kullanıcı oturumu ve kişiselleştirme

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 📞 İletişim

Proje hakkında sorularınız için issue açabilir veya iletişime geçebilirsiniz.
