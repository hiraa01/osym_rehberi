# ML Model Eğitimi

## Durum
Coach chat Gemini API kullanıyor (hazır model, eğitim gerektirmez).  
ML Recommendation Engine modelleri henüz eğitilmedi.

## Eğitim Adımları

### 1. Docker Container'da Çalıştırma

```bash
# PowerShell veya CMD'de:
docker exec osym_rehberi_backend python scripts/train_ml_models.py
```

### 2. Manuel Eğitim

Eğer Docker container içinde değilseniz, backend dizininde:

```bash
cd backend
python scripts/train_ml_models.py
```

### 3. API Endpoint ile Eğitim

Backend çalışıyorken:

```bash
# HTTP POST request ile:
curl -X POST http://localhost:8002/api/ml-recommendations/train
```

veya Swagger UI'dan:
- http://localhost:8002/docs
- `/api/ml-recommendations/train` endpoint'ine POST request atın

## Eğitim Sonrası

Model dosyaları şu konumda kaydedilir:
- `backend/ml_models/compatibility_model.pkl`
- `backend/ml_models/compatibility_scaler.pkl`
- `backend/ml_models/success_model.pkl`
- `backend/ml_models/success_scaler.pkl`
- `backend/ml_models/preference_model.pkl`
- `backend/ml_models/preference_scaler.pkl`

Docker volume `ml_models` ile persist edilir.

## Model Durumu Kontrolü

```bash
# API endpoint ile kontrol:
curl http://localhost:8002/api/ml-recommendations/status
```

## Notlar

- İlk eğitim simüle edilmiş veri ile yapılır (25 örnek)
- Gerçek veri toplandıkça model otomatik güncellenecek
- Eğitim periyodik olarak arka planda çalışır (günde 1 kez)
