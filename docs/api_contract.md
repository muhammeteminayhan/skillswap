# API Contract

Tüm uç noktalar varsayılan olarak `http://localhost:8080` altındadır. JSON gövdelerde `Content-Type: application/json` kullanılır.

## Sağlık
- `GET /health` — servis canlı mı
- `GET /gemini/ping` — Gemini anahtarı doğrulama (opsiyonel)

## Kimlik
- `POST /api/auth/register` — `{name,email,password,title,location}`
- `POST /api/auth/login` — `{email,password}`

## Profil
- `GET /api/profile/{userId}`
- `PUT /api/profile/{userId}` — profil güncelle

## Yetenekler
- `GET /api/skills/{userId}`
- `PUT /api/skills/{userId}` — toplu güncelle
- `POST /api/skills/{userId}/offer` — yeni OFFER
- `PUT /api/skills/{userId}/offer/{skillId}`
- `DELETE /api/skills/{userId}/offer/{skillId}`

## İlanlar
- `GET /api/listings`
- `GET /api/listings/{id}`
- `POST /api/listings`
- `PUT /api/listings/{id}`
- `DELETE /api/listings/{id}?ownerUserId=`

## Takas İstekleri
- `GET /api/requests` — tümü
- `GET /api/requests/{userId}` — kullanıcının
- `GET /api/requests/{userId}/wants`
- `POST /api/requests` — serbest metinden istek oluştur
- `POST /api/requests/{userId}/wants` — want ekle (ihtiyaç)
- `DELETE /api/requests/{userId}/wants?want=`
- `POST /api/requests/{requestId}/feedback`
- `PUT /api/requests/{requestId}/status`

## Takas Eşleşmeleri
- `GET /api/swaps/matches/{userId}` — eşleşme listesi
- `POST /api/swaps/matches/{matchId}/accept` — `{userId}`
- `POST /api/swaps/matches/{matchId}/done` — `{userId}`
- `POST /api/swaps/matches/{matchId}/review` — `{fromUserId,rating,comment}`
- `GET /api/swaps/matches/{matchId}/reviews`
- `GET /api/swaps/reviews/{userId}`
- `DELETE /api/swaps/matches/{matchId}?userId=` — sadece DONE eşleşmeleri siler
- `POST /api/swaps/rebuild` — tüm eşleşmeleri yeniden kur

## Krediler
- `GET /api/credits/{userId}/balance`
- `GET /api/credits/{userId}/transactions`
- `POST /api/credits/purchase` — `{userId,credits}`

## Chat / Mesajlaşma
- `POST /api/chat` — AI destekli yanıt
- `GET /api/chat/conversations/{userId}`
- `GET /api/chat/thread?userId=&otherUserId=`
- `POST /api/chat/send` — `{fromUserId,toUserId,body}`

## ML & Demo
- `GET /api/ml/insights/{userId}`
- `POST /extract` — metinden want/offer çıkar
- `POST /fairness` — iki görev için adalet skoru
- `POST /match` — demo eşleştirme
- `GET /api/demo/dashboard/{userId}`
- `GET /api/demo/chains/{userId}`
- `GET /api/demo/quantum/{userId}?realMatching=true`
- `GET /api/demo/talents/{userId}`
- `GET /api/demo/search/{userId}?query=&radiusKm=5`
- `GET /api/demo/boost`
- `POST /api/demo/boost/activate/{userId}`

## Upload
- `POST /api/uploads` — multipart/form-data dosya yükleme
