# Gemini API Key Kurulumu

## ⚠️ ÖNEMLİ
Gemini API key'inizi `docker/.env` dosyasına eklemeniz gerekiyor!

## Sorun
`docker-compose.yml` dosyasında `GOOGLE_API_KEY` environment variable'ı `.env` dosyasından okunuyor, ancak bu dosya henüz oluşturulmamış olabilir.

## Çözüm

### 1. `.env` Dosyası Oluşturun

`docker/` klasöründe `.env` adında bir dosya oluşturun:

**Windows (PowerShell veya CMD):**
```bash
cd docker
echo GOOGLE_API_KEY=AIzaSyAWeAMxuFbtC_vbMeUaKFNKu0SvO9X7njg > .env
```

**Windows (Manuel):**
1. `docker/` klasörüne gidin
2. Yeni bir metin dosyası oluşturun ve adını `.env` yapın (tırnak işaretleri olmadan)
3. İçine şunu yazın:
```
GOOGLE_API_KEY=AIzaSyAWeAMxuFbtC_vbMeUaKFNKu0SvO9X7njg
```

**Linux/Mac:**
```bash
cd docker
cat > .env << EOF
GOOGLE_API_KEY=AIzaSyAWeAMxuFbtC_vbMeUaKFNKu0SvO9X7njg
EOF
```

### 2. Container'ı Yeniden Başlatın

`.env` dosyasını oluşturduktan sonra, backend container'ını yeniden başlatın:

```bash
cd docker
docker-compose down
docker-compose up -d backend
```

### 3. Doğrulama

**API Key'in yüklendiğini kontrol edin:**
```bash
docker exec osym_rehberi_backend printenv | grep GOOGLE_API_KEY
```

Bu komut API key'in container içinde olup olmadığını gösterir. Çıktıda `GOOGLE_API_KEY=AIzaSyAWeAMxuFbtC_vbMeUaKFNKu0SvO9X7njg` gibi bir satır görüyorsanız, API key başarıyla yüklendi.

**Backend loglarını kontrol edin:**
```bash
docker logs osym_rehberi_backend --tail 20
```

**Chatbot'u test edin:**
Flutter uygulamasında chatbot'a bir soru sorun. Eğer hala `"LLM API anahtarı tanımlı değil"` hatası alıyorsanız, container'ı tamamen yeniden başlatın:

```bash
cd docker
docker-compose restart backend
```

### 4. Model Bilgisi

Backend'de kullanılan Gemini model adı: **`gemini-1.5-flash`**

Bu model adı `backend/routers/coach_chat.py` dosyasında tanımlıdır. 

**Mevcut Model Seçenekleri:**
- `gemini-1.5-flash` - Hızlı ve ekonomik (önerilen, şu anda kullanılıyor)
- `gemini-1.5-pro` - Daha güçlü ama yavaş (alternatif)

**Önemli:** `gemini-pro` artık mevcut değil! Eğer "404 models/gemini-pro is not found" hatası alıyorsanız, model adını `gemini-1.5-flash` olarak güncelleyin.

## Güvenlik Notu

⚠️ **`.env` dosyasını git'e commit etmeyin!** 

`.gitignore` dosyasına ekleyin:
```
docker/.env
```

## Alternatif Yöntem (Manuel)

Eğer `.env` dosyası kullanmak istemiyorsanız, `docker-compose.yml`'de direkt değeri yazabilirsiniz (ama bu güvenlik riski):

```yaml
- GOOGLE_API_KEY=AIzaSyAWeAMxuFbtC_vbMeUaKFNKu0SvO9X7njg
```

Ancak bu yöntem önerilmez çünkü API key git'e commit edilir.


