# ML Model Sıfırlama ve XGBoost'a Geçiş Rehberi

## 🎯 Amaç

XGBoost'a geçiş yaptığımız için eski GradientBoosting modellerini silip yeni XGBoost modellerini eğitmemiz gerekiyor.

## ⚠️ Neden Eski Modelleri Silmeliyiz?

1. **Uyumsuzluk**: Eski modeller sklearn GradientBoosting ile eğitilmiş
2. **Yeni Kod**: Yeni kod XGBoost bekliyor
3. **Hata Riski**: Eski modeller yüklendiğinde hata verebilir
4. **Temiz Başlangıç**: Daha sağlıklı ve güvenilir

## 🛠️ Adım Adım İşlem

### ⚠️ ÖNCE YAPILMASI GEREKENLER

**XGBoost paketini yüklemek için container'ı yeniden build edin:**

```powershell
# docker klasörüne git
cd docker

# Backend container'ı yeniden build et (requirements.txt güncellendi)
docker-compose build backend

# Container'ı yeniden başlat
docker-compose up -d backend

# Container'ın çalıştığını kontrol et
docker-compose ps
```

**XGBoost'un yüklendiğini kontrol edin:**

```powershell
docker exec -it osym_rehberi_backend python -c "import xgboost; print('XGBoost version:', xgboost.__version__)"
```

### Yöntem 1: Otomatik Script (Önerilen)

Tek komutla hem silme hem eğitme:

```powershell
# Docker container içinde
docker exec -it osym_rehberi_backend python scripts/reset_and_retrain_ml_models.py
```

### Yöntem 2: Manuel Adımlar

#### Adım 1: Eski Modelleri Sil

```powershell
# Docker container içinde
docker exec -it osym_rehberi_backend python scripts/clean_ml_models.py
```

#### Adım 2: Yeni XGBoost Modellerini Eğit

```powershell
# Docker container içinde
docker exec -it osym_rehberi_backend python scripts/train_ml_models.py
```

### Yöntem 3: Manuel Dosya Silme (Docker Volume)

Eğer script çalışmazsa, dosyaları manuel silebilirsiniz:

```powershell
# Docker container içinde
docker exec -it osym_rehberi_backend bash

# Container içinde:
rm -f /app/ml_models/*_model.pkl
rm -f /app/ml_models/*_scaler.pkl
# veya
rm -f models/*_model.pkl
rm -f models/*_scaler.pkl

# Çıkış
exit
```

## 📋 Silinecek Dosyalar

- `compatibility_model.pkl` (eski GradientBoosting)
- `compatibility_scaler.pkl`
- `success_model.pkl` (eski GradientBoosting)
- `success_scaler.pkl`
- `preference_model.pkl` (eski GradientBoosting)
- `preference_scaler.pkl`

## ✅ Yeni Modeller Eğitildikten Sonra

Yeni XGBoost modelleri aynı isimlerle kaydedilecek:
- `compatibility_model.pkl` (yeni XGBoost)
- `compatibility_scaler.pkl`
- `success_model.pkl` (yeni XGBoost)
- `success_scaler.pkl`
- `preference_model.pkl` (yeni XGBoost)
- `preference_scaler.pkl`

## 🔍 Model Durumunu Kontrol Etme

```powershell
# Docker container içinde dosyaları listele
docker exec -it osym_rehberi_backend ls -la /app/ml_models/

# veya
docker exec -it osym_rehberi_backend ls -la models/
```

## 🚀 Hızlı Başlangıç (Tek Komut)

```powershell
# Tüm işlemi tek seferde yap
docker exec -it osym_rehberi_backend python scripts/reset_and_retrain_ml_models.py
```

## 📝 Notlar

- Eski modeller silinmeden yeni modeller eğitilirse, eski modeller üzerine yazılır
- Docker volume `ml_models` kullanılıyorsa, veriler kalıcı olarak saklanır
- Eğitim sırasında simüle edilmiş veri kullanılır (25 örnek)
- Gerçek veri toplandıkça modeller otomatik güncellenecek

## ⚡ Performans İyileştirmeleri

XGBoost'un avantajları:
- ✅ Daha hızlı eğitim
- ✅ Daha iyi tahmin performansı
- ✅ Paralel işleme desteği
- ✅ Gelişmiş regularization

