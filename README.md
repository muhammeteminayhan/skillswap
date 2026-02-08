# SkillSwap

Yerel yetenek takasını kolaylaştıran bir demo platformu. Backend Spring Boot ile REST API sağlar, mobil istemci Flutter ile geliştirilmiştir. Ayrıca kredi/adalet hesapları için basit bir regresyon modeli ve tohum veriler bulunur.

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
