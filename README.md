# İMECE

Yerel yetenek takasını kolaylaştıran görsel odaklı bir demo platformu. Backend Spring Boot ile REST API sağlar, mobil istemci Flutter ile geliştirilmiştir. Ayrıca kredi/adalet hesapları için basit bir regresyon modeli ve tohum veriler bulunur.

## Özellikler
- Teklif ve ihtiyaç ilanları oluşturma
- Eşleştirme ve takas akışları
- Kredi bakiyesi ve işlem geçmişi
- Mesajlaşma ve profil akışı
- Gemini tabanlı metinden yapılandırılmış çıkarım (opsiyonel)

## Repo Yapısı
- `backend/`: Spring Boot API
- `mobile/`: Flutter uygulaması
- `ml/`: Kredi regresyon modeli eğitim scriptleri
- `data/`: Eğitim verisi ve SQL tohum dosyaları
- `docs/`: API kontratı ve örnek istekler
- `uploads/`: Dosya yüklemeleri için dizin

## Görseller
Uygulama ekran görüntülerini `docs/screenshots/` altına ekleyebilirsiniz. README içinde örnek kullanım:
```md
![Ana Akış](docs/screenshots/home.png)
![Profil](docs/screenshots/profile.png)
![Takas Ekranı](docs/screenshots/swap.png)
```

## Gereksinimler
- Java 21
- PostgreSQL 13+
- Flutter 3.x (mobil istemci için)
- Python 3.10+ (ML scriptleri için)

## Hızlı Başlangıç (Backend)
1. PostgreSQL veritabanı oluşturun:
```sql
CREATE DATABASE hackathon;
```

2. `backend/src/main/resources/application.properties` içindeki DB ayarlarını güncelleyin:
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/hackathon
spring.datasource.username=postgres
spring.datasource.password=123456
```

3. Opsiyonel: Gemini API anahtarını tanımlayın:
```
GEMINI_API_KEY=your_key
```
Not: Backend, `.env`, `.env.properties`, `backend/.env`, `backend/.env.properties` dosyalarını otomatik okur.

4. Backend’i çalıştırın:
```bash
cd backend
./mvnw spring-boot:run
```

API varsayılan olarak `http://localhost:8080` adresinde çalışır.

## Örnek API Çağrıları
Detaylı örnekler için `docs/api_contract.md` dosyasına bakın. Kısa örnek:
```bash
curl -X POST http://localhost:8080/extract \
  -H "Content-Type: application/json" \
  -d '{"text":"Evime 3 priz çektirmek istiyorum, karşılığında kombi bakımını yapabilirim."}'
```

## API Endpoints (Eksiksiz)
`GET /health` - Sağlık kontrolü
`GET /gemini/ping` - Gemini bağlantı testi (API key gerekir)
`POST /extract` - Metinden yapılandırılmış çıkarım
`POST /fairness` - Takas adalet analizi
`POST /match` - Demo eşleştirme
`POST /api/auth/register` - Kayıt
`POST /api/auth/login` - Giriş
`GET /api/profile/{userId}` - Profil görüntüle
`PUT /api/profile/{userId}` - Profil güncelle
`GET /api/messages/{userId}` - Mesaj kutusu
`GET /api/skills/{userId}` - Yetenekler
`PUT /api/skills/{userId}` - Yetenek güncelle
`POST /api/skills/{userId}/offer` - Yeni teklif yeteneği ekle
`PUT /api/skills/{userId}/offer/{skillId}` - Teklif yeteneği güncelle
`DELETE /api/skills/{userId}/offer/{skillId}` - Teklif yeteneği sil
`GET /api/listings` - İlanları listele
`GET /api/listings/{id}` - İlan detayı
`POST /api/listings` - İlan oluştur
`PUT /api/listings/{id}` - İlan güncelle
`DELETE /api/listings/{id}?ownerUserId=` - İlan sil
`GET /api/requests` - Tüm takas istekleri
`GET /api/requests/{userId}` - Kullanıcı istekleri
`GET /api/requests/{userId}/wants` - Kullanıcı istek listesi
`POST /api/requests` - Takas isteği oluştur
`POST /api/requests/{userId}/wants` - Kullanıcıya want ekle
`DELETE /api/requests/{userId}/wants?want=` - Kullanıcıdan want sil
`POST /api/requests/{requestId}/feedback` - Geri bildirim
`PUT /api/requests/{requestId}/status` - İstek durumu güncelle
`GET /api/swaps/matches/{userId}` - Eşleşmeleri listele
`POST /api/swaps/matches/{matchId}/accept` - Eşleşmeyi kabul et
`POST /api/swaps/matches/{matchId}/done` - Eşleşmeyi tamamla
`POST /api/swaps/matches/{matchId}/review` - Eşleşmeyi değerlendir
`GET /api/swaps/matches/{matchId}/reviews` - Eşleşme yorumları
`GET /api/swaps/reviews/{userId}` - Kullanıcı yorumları
`DELETE /api/swaps/matches/{matchId}?userId=` - Tamamlanan eşleşmeyi sil
`POST /api/swaps/rebuild` - Eşleşmeleri yeniden oluştur
`GET /api/credits/{userId}/balance` - Kredi bakiyesi
`GET /api/credits/{userId}/transactions` - Kredi işlemleri
`POST /api/credits/purchase` - Kredi satın al
`POST /api/chat` - AI sohbet
`GET /api/chat/conversations/{userId}` - Konuşma listesi
`GET /api/chat/thread?userId=&otherUserId=` - Konuşma detayları
`POST /api/chat/send` - Mesaj gönder
`GET /api/ml/insights/{userId}` - ML içgörüleri
`GET /api/demo/dashboard/{userId}` - Demo dashboard
`GET /api/demo/chains/{userId}` - Demo zincirler
`GET /api/demo/quantum/{userId}?realMatching=true` - Demo eşleştirme
`GET /api/demo/talents/{userId}` - Demo yetenekler
`GET /api/demo/search/{userId}?query=&radiusKm=5` - Demo arama
`GET /api/demo/boost` - Demo boost
`POST /api/demo/boost/activate/{userId}` - Demo boost aktivasyon
`POST /api/uploads` - Dosya yükleme (multipart/form-data)

## Veri Tohumlama (Opsiyonel)
Uygulama açılışında demo verisi yüklemek için:
```properties
app.seed.enabled=true
```

## Mobil Uygulama
```bash
cd mobile
flutter pub get
flutter run
```

## ML Scriptleri
Kredi regresyon modeli için SQL çıktıları üretir:
```bash
python3 ml/train_credit_regression.py --csv data/synthetic_training_data_520.csv --out-dir data
```

## Sorun Giderme
- PostgreSQL bağlantı hatası alırsanız `application.properties` içindeki kullanıcı/şifre ve DB adını kontrol edin.
- Gemini çağrıları boş dönüyorsa `GEMINI_API_KEY` değeri eksik olabilir.

## Lisans
Bu repo demo amaçlıdır. Lisans bilgisi eklenmedi.
