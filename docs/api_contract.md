# API Contract (MVP)

## 1) `/extract` - Metinden yapılandırılmış çıkarım
Kullanıcı metninden wants/offers ve risk-zorluk bilgilerini üretir.

```bash
curl -X POST http://localhost:8080/extract \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Evime 3 priz çektirmek istiyorum, karşılığında kombi bakımını yapabilirim. Kadıköy civarı."
  }'
```

## 2) `/fairness` - Takas adalet analizi
İki görevin değerini kıyaslayıp adalet yüzdesi ve öneri metni döndürür.

```bash
curl -X POST http://localhost:8080/fairness \
  -H "Content-Type: application/json" \
  -d '{
    "leftTaskText": "Eve 3 adet priz hattı çekimi",
    "rightTaskText": "Kombi yıllık bakım ve filtre temizliği"
  }'
```

## 3) `/match` - Mock eşleştirme
Girilen metne göre demo aday listesi döndürür.

```bash
curl -X POST http://localhost:8080/match \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Priz ve sigorta kutusu için usta arıyorum, bilgisayar format desteği verebilirim."
  }'
```
