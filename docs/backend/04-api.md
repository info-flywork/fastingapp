# 04 — API Sözleşmesi (`/v1`)

Genel kurallar [02-mimari.md §4](02-mimari.md#4-http-sözleşme-standartları) belgesinde:
- yanıt zarfı
- hata kodları
- header'lar
- sayfalama

Bu belge uç noktaları listeler. Her uç noktanın JSON Schema'sı kodda `*.schemas.js` dosyalarında tutulur
ve OpenAPI otomatik olarak üretilir.

**Gösterim:**
- 🔓 kimlik doğrulama gerektirmez
- 🔐 kullanıcı token'ı gerekir
- 💎 premium entitlement gerekir (yoksa 402 `PREMIUM_REQUIRED`)
- 🛡️ admin

## Yanıt zarfı

```jsonc
{ "status": "success", "message": "OK", "data": { … } }
```

- **Liste uçları** `data.items` + `data.pageInfo` döner (istemci `data` dizisini parse edemiyor).
- **204 yanıtları** gövdesiz döner. İstemci `NoContent` bekler. 204 yerine
  `{status:"success", data:{}}` ile 200 dönmek de kabul edilebilir; tutarlılık için **200 + boş data** tercih edilir.

## Enum eşlemesi

DB'de `snake_case`, API'de **lowerCamelCase** kullanılır (Dart enum adlarıyla birebir):

| DB | API | Not |
|---|---|---|
| `lose_weight` | `loseWeight` | |
| `non_binary` | `nonBinary` | |
| `prefer_not_to_say` | `preferNotToSay` | |
| `low_carb` | `lowCarb` | |
| `super` | `super` | İstemcideki `superMood` / `superFeeling` → `@JsonValue('super')` |
| plan kodu `20_4` | `"20_4"` | Plan kodları enum değil, katalog kodudur. İstemcideki `twentyFour` → `20_4` |

---

## 1. Kimlik doğrulama — `auth`

### `POST /v1/auth/guest` 🔓

Onboarding'in **başında** çağrılır. Sahte `local-onboarding-session` token'ının yerini alır.

```jsonc
// istek
{ "installId": "6f1c…-uuid", "platform": "ios", "locale": "tr", "timezone": "Europe/Istanbul",
  "appVersion": "1.0.0" }
// yanıt 201
{ "token": { "accessToken": "eyJ…", "refreshToken": "rt_…", "expiresIn": 900 },
  "user": { "id": "0192…", "name": null, "email": null, "isGuest": true, "isPremium": false,
            "isAnsweredQuestions": false } }
```

Aynı `installId` için tekrar çağrılırsa mevcut misafir kullanıcıya **yeni oturum** açılır (yeni kullanıcı oluşturulmaz).

**Rate limit:**
- IP başına 10/saat
- installId başına 5/saat

### `POST /v1/auth/register` 🔓

Mevcut istemci yolu korunur. `POST /v1/auth/social` ve `POST /v1/auth/firebase` ile aynıdır. Firebase token doğrulaması: [06 §2.1](06-guvenlik.md#21-sağlayıcı-token-doğrulama-firebase-authentication).

```jsonc
// istek
{ "provider": "firebase" | "guest",
  "idToken": "…",                 // Firebase ID token (Apple/Google girişini Firebase SDK yapar)
  "fullName": { "givenName": "Atilla", "familyName": "E." },  // Apple adı yalnızca ilk girişte istemciye gelir
  "deviceId": "<installId>" }
// yanıt 200 (mevcut hesap) | 201 (yeni hesap)
{ "token": {…}, "user": {…}, "isNewUser": true, "linkedFromGuest": true, "mergedFromGuest": false }
```

**Davranış:**

| Durum | Ne olur |
|---|---|
| Header'da **misafir oturumu** var + sosyal kimlik yeni | Misafir hesap sosyal hesaba **yükseltilir**: aynı `userId`, onboarding/oruç verileri korunur, `isGuest=false` |
| Header'da misafir var + sosyal kimlik **başka bir hesaba** bağlı | `409 ACCOUNT_LINK_CONFLICT`. `details.options = ["switch_account","merge"]`. Varsayılan: kullanıcı mevcut hesaba geçer, misafir verisi `merge` seçilirse taşınır ([05 §11](05-is-kurallari.md#11-misafir-hesap-birleştirme)) |
| Header yok + kimlik bulundu | Giriş yapılır |
| Header yok + kimlik yok | Yeni kullanıcı oluşturulur |

**Çakışma akışı:** İlk çağrı `mergeGuest` olmadan yapılır; çakışma varsa 409 döner. İstemci kullanıcıya sorar ve aynı isteği
`"mergeGuest": false` (mevcut hesaba geç; misafir `pending_deletion`) ya da `"mergeGuest": true` (misafir verisi taşınır) ile tekrarlar.
Her iki durumda da misafir oturumları iptal edilir ve misafirin `installId`'si artık giriş için kullanılamaz.

### `POST /v1/auth/refresh` 🔓

```jsonc
{ "refreshToken": "rt_…" }   →   { "token": { "accessToken", "refreshToken", "expiresIn" } }
```

- Her çağrıda yeni refresh token döner. Eski token `rotated` olarak işaretlenir.
- **Yeniden kullanım** tespit edilirse aile iptal edilir ve `401 REFRESH_REUSED` döner.
- İstemci aynı anda tek refresh yapmalıdır. Aynı token ile 10 saniye içinde gelen paralel çağrılara **aynı yeni çift** döner (verilen çift API process belleğinde 10 sn "grace" kaydı olarak tutulur).

### `POST /v1/auth/logout` 🔐

`{ "refreshToken": "rt_…", "allDevices": false }` → mevcut oturum ya da tüm oturumlar iptal edilir, cihazın push token'ı silinir.

### `GET /v1/auth/sessions` 🔐 / `DELETE /v1/auth/sessions/:id` 🔐

Aktif cihaz oturumlarını listeler ve uzaktan çıkış yapmayı sağlar (profil → güvenlik, faz 10).

---

## 2. Kullanıcı — `user`

### `GET /v1/user/me` 🔐 (mevcut yol `/user/me` korunur)

```jsonc
{ "id": "0192…", "name": "Atilla E.", "email": "x@privaterelay.appleid.com",
  "avatarUrl": "https://media.mochifast.app/u/…_256.webp?token=…&expires=…",
  "isGuest": false, "isPremium": true, "isAnsweredQuestions": true,
  "locale": "tr", "timezone": "Europe/Istanbul",
  "units": { "weight": "kg", "height": "cm", "water": "ml" },
  "entitlements": ["premium"], "createdAt": "2026-10-06T08:00:00.000Z" }
```

### `PATCH /v1/user/me` 🔐

```jsonc
{ "name": "Atilla E.", "locale": "tr", "timezone": "Europe/Istanbul",
  "units": { "weight": "lb" } }
```

### `PUT /v1/user/me/avatar` 🔐

- `multipart/form-data`, alan `file`, en fazla 10 MB.
- Kabul edilen türler: jpeg/png/webp/heic*.
- Yanıt: `{ "avatarUrl": "…" }`. Senkron çalışır (küçük görsel). Ayrıntı: [08](08-medya-bunny.md).

### `DELETE /v1/user/me/avatar` 🔐

### `POST /v1/user/onboarding` 🔐

Tüm onboarding cevapları **tek seferde** gönderilir. Mevcut `PATCH /user/onboarding {level}` yolu 200 döner ve yok sayılır (kullanımdan kaldırıldı).

```jsonc
// istek
{ "schemaVersion": 1,
  "goal": "loseWeight",
  "gender": "woman",
  "weightKg": 74.0, "goalWeightKg": 64.0, "heightCm": 172, "age": 29,
  "diet": "everything",
  "foodLoves": ["chicken","eggs"], "foodSkips": ["onions"],
  "weightHistory": "firstTime",
  "obstacles": ["lifeGotBusy","lostMotivation"],
  "fastingReason": "specialDate",
  "planCode": "16_8",
  "mealWindow": { "start": "07:00", "end": "19:00" },
  "healthFlags": [],                       // önerilen yeni güvenlik adımı (05 §2.6)
  "safetyAcknowledged": false,             // diyabet/ilaç/kalp + >14 sa planda zorunlu (yoksa 422 SAFETY_ACK_REQUIRED)
  "consents": { "terms": "2026-10", "privacy": "2026-10", "healthData": true, "aiProcessing": true } }
// yanıt 200 — BuildingPlan / WeightProjection ekranları için hesaplanmış plan özeti
{ "user": {…, "isAnsweredQuestions": true},
  "plan": { "planCode": "16_8", "fastMinutes": 960, "eatWindow": {"start":"11:00","end":"19:00"} },
  "projection": { "currentWeightKg": 74.0, "goalWeightKg": 64.0, "weeklyLossKg": 0.4,
                  "targetDate": "2027-03-20", "weeks": 25 },
  "targetDate": "2026-11-20",
  "warnings": [] }                          // GOAL_BMI_BELOW_18_5, MEAL_WINDOW_SHORTER_THAN_PLAN
```

**Doğrulamalar:**
- Aralıklar: [01 §2.1](01-uygulama-analizi.md#21-kimlik-doğrulama--onboarding-presentationauth).
- `goalWeightKg ≤ weightKg` ya da `goal != loseWeight`.
- `mealWindow` bitişi başlangıçtan sonra olmalı. Gece yarısını geçen pencereye izin var.
- Planla tutarlılık uyarısı.
- Sağlık kuralları: [05 §2.6](05-is-kurallari.md#26-sağlık-güvenliği-kuralları). İhlalde 422 `UNSAFE_REQUEST` (`details.reason`: `plan_min_age`, `plan_pregnancy`, `plan_eating_disorder`, `goal_bmi`).
- `consents.healthData` `true` değilse 403 `CONSENT_REQUIRED` (sağlık verisi açık rıza ister).
- Plan özeti: günlük planlarda yeme penceresi öğün penceresinin **sonunda** biter (07:00–19:00 + 16:8 → 11:00–19:00).
- Aynı istek tekrar gönderilebilir: profil güncellenir, onboarding kilo kaydı tek kalır.

**Yan etkiler (tek transaction):**
- `user_profiles`, `user_food_preferences`, `user_obstacles` güncellenir.
- `user_plans` (aktif plan) oluşturulur.
- `weight_entries` (source = onboarding) eklenir.
- `user_goals` ve `user_settings` varsayılanları yazılır.
- Consent'ler kaydedilir.
- `onboarding_submissions` anlık görüntüsü saklanır.

### `GET /v1/user/profile` 🔐 / `PATCH /v1/user/profile` 🔐

Edit Profile ekranının tüm alanları:
- `gender`, `heightCm`, `age`
- `goal` (fasting target), `goalWeightKg`
- `diet`, `foodLoves[]`, `foodSkips[]`
- `obstacles[]`, `fastingReason`, `mealWindow`, `healthFlags[]`

`weightKg` gönderilirse **yeni bir kilo kaydı** oluşturulur (profilde tek değer saklanmaz).

### `GET /v1/user/settings` 🔐 / `PATCH /v1/user/settings` 🔐

```jsonc
{ "pushEnabled": true,
  "notifications": { "fasting": true, "streak": true, "weight": true, "water": false,
                     "challenges": true, "marketing": false },
  "waterReminderIntervalMin": 120,
  "quietHours": { "start": "22:30", "end": "08:00" },
  "healthSyncEnabled": false }
```

### `GET /v1/user/goals` 🔐 / `PATCH /v1/user/goals` 🔐

```jsonc
{ "waterGoalMl": 2500, "glassSizeMl": 300, "customGlassSizes": [350],
  "stepsGoal": 8000,
  "kcalGoal": null, "proteinGoalG": null,   // null = sunucu önerisi kullanılır
  "computed": { "kcalGoal": 1850, "proteinGoalG": 110, "carbsGoalG": 180, "fatGoalG": 65 },
  "sleepGoalMin": 450, "bedtime": "23:00", "wakeTime": "06:30" }
```

### `GET /v1/user/summary` 🔐 — **Ana sayfa tek çağrı**

Ana sayfayı, profil başlığını, oruç sekmesi başlığını ve widget'ları besleyen birleşik yanıt (cache: 15 sn, [07](07-cache-performans.md)).

```jsonc
{ "user": { "id", "name", "avatarUrl", "isPremium", "isGuest" },
  "progress": { "level": 4, "xp": 380, "nextLevelXp": 450,
                "streakDays": 5, "bestStreak": 12, "completedFasts": 23 },
  "activeFast": { /* GET /v1/fasts/active ile aynı, yoksa null */ },
  "plan": { "planCode": "16_8", "displayName": "16:8", "fastMinutes": 960,
            "eatWindow": {"start":"12:00","end":"20:00"} },
  "week": [ { "date": "2026-10-05", "fastedMinutes": 970, "goalMinutes": 960, "progress": 1.0 }, … 7 gün ],
  "today": {
    "water": { "ml": 600, "goalMl": 2500 },
    "steps": { "count": 1000, "goal": 8000 },
    "nutrition": { "kcal": 1240, "kcalGoal": 1850 },
    "lastMeal": { "id", "eatenAt", "kind": "meal", "dietType": "ketogenic", "feeling": "good" } | null,
    "hunger": { "physical": 2, "emotional": 1 } },
  "weight": { "currentKg": 102.5, "startKg": 112.2, "goalKg": 75.2, "progress": 0.26 },
  "featuredChallenge": { /* §12 */ } | null,
  "unreadNotifications": 2 }
```

### `GET /v1/user/progress` 🔐 (mevcut yol korunur)

`{ "level", "streakDays", "completedFasts" }` döner. Ek alanlar eklenebilir; mevcut alanlar değişmez.

### `GET /v1/user/stats?range=week|month|year|all` 🔐

Döner:
- toplam oruç sayısı
- tamamlanma oranı
- toplam, en uzun ve ortalama oruç süresi
- en iyi seri
- kilo değişimi
- su hedefi tutturulan günler
- öğün sayısı

### Hesap & veri

| Uç | Açıklama |
|---|---|
| `POST /v1/user/consents` 🔐 | `{type, version, granted}`. Yalnızca ekleme yapılır (append-only). Yanıt ve `GET /v1/user/consents`: her tür için son durum `{items:[{type, version, granted, at}]}` |
| `DELETE /v1/user/me` 🔐 | Hesap silme talebi. Gövde: `{reason?}`. Yanıt 202 `{scheduledFor}`. Oturumlar hemen iptal edilir, hesap `pending_deletion` olur. Süre dolunca silme işi çalışır ([06 §8](06-guvenlik.md#8-kvkk--gdpr)) |
| `POST /v1/user/me/restore` 🔐 | Silme süresi içinde yeniden giriş yapıldıysa talebi iptal eder |
| `POST /v1/user/me/export` 🔐 | 202. Hazır olunca bildirim ve imzalı zip linki gelir (günde 1) |
| `GET /v1/user/me/export/:id` 🔐 | Dışa aktarma durumu ve link |

---

## 3. Cihazlar — `devices`

### `PUT /v1/devices/current` 🔐

Her uygulama açılışında ve push token değiştiğinde çağrılır.

```jsonc
{ "installId": "…", "platform": "ios", "osVersion": "26.3", "appVersion": "1.0.0",
  "deviceModel": "iPhone17,1", "pushToken": "fcm…", "pushEnabled": true,
  "locale": "tr", "timezone": "Europe/Istanbul" }
```

### `DELETE /v1/devices/current/push-token` 🔐

---

## 4. Katalog & uygulama yapılandırması — `catalog`, `app`

Bu uçların hepsi **public + cache'li**:
- `Cache-Control: public, max-age=300, stale-while-revalidate=86400`
- `ETag`
- `Vary: Accept-Language`

Token zorunlu değildir; varsa premium kilit durumu kişiselleştirilir ve `Cache-Control: private` olur.

| Uç | Yanıt |
|---|---|
| `GET /v1/catalog/plans` 🔓 | `{ groups: [{ category, title, plans: [{code, category, scheduleType, displayName, cardLabel, shortDescription, fastHours, eatHours, reducedDaysPerWeek, reducedDayKcal, intensity, isPremium, isLocked, isFeatured, requiresSafetyAck, minAge, allowedTimings, defaultTiming, defaultEatStart}] }], timings: [{code, title}] }`. Grup sırası: beginner, popular, intermediate, advanced, weekly, flexible; bir plan birden çok grupta olabilir |
| `GET /v1/catalog/plans/:code` 🔓 | Özet alanları + `longDescription`, `safetyNote`, `exampleWindow {start,end}`, `weeklyTemplate` (haftalık/özel planlarda 7 gün: `{dow, type: normal\|reduced\|fast, kcal?, fastMinutes?}`). Bilinmeyen kod 404 |
| `GET /v1/catalog/stages?type=body\|eating_window` 🔓 | `[{position, startHour, endHour, rangeLabel, title, body, imageKey}]` |
| `GET /v1/catalog/struggle` 🔓 | `{ reasons:[{code,title,body,imageKey,tips:[…]}], tips:[{code,title,body,imageKey,activity:{…},done:{title,body}}] }` |
| `GET /v1/catalog/onboarding-options` 🔓 | Hedefler, diyetler, yiyecekler, engeller, sebepler (gün sayılarıyla) ve onboarding'de gösterilecek plan alt kümesi. Uygulamadaki sabit listelerin uzaktan güncellenebilmesi için |
| `GET /v1/catalog/faq` 🔓 | `[{code, question, answer}]` |
| `GET /v1/app/config` 🔓 | `{ platform, minAppVersion, latestAppVersion, updateRequired, updateAvailable, features:{chat,photoAnalysis,challenges,forecast}, limits:{freeChatDaily,freePhotoDaily,premiumChatDaily,premiumPhotoDaily}, marketing:{activeUsers:"2M+", rating:4.8, avgStreakDays:12, trustedBy:"200K+"}, legal:{termsUrl, privacyUrl, termsVersion, privacyVersion}, support:{email}, catalogVersion }`. Platform `?platform=` ya da `X-Platform`; sürümü eski istemci de erişir |

---

## 5. Planlar — `plans`

### `GET /v1/plans/current` 🔐

```jsonc
{ "id": "…", "planCode": "16_8", "displayName": "16:8", "timing": "skipBreakfast",
  "fastMinutes": 960, "eatWindow": { "start": "12:00", "end": "20:00" },
  "weeklySchedule": [ { "dow": 1, "type": "fast", "fastMinutes": 960, "eatStart": "12:00" }, … ],
  "startedOn": "2026-10-01", "isPremium": false }
```

### `PUT /v1/plans/current` 🔐

```jsonc
{ "planCode": "18_6", "timing": "custom",
  "eatWindow": { "start": "13:00", "end": "19:00" },     // custom/timing seçimine göre
  "fastMinutes": 1080,                                   // custom_daily için 720–1380
  "weeklySchedule": [ … ],                               // custom_weekly / 5:2 / ADF için zorunlu
  "safetyAcknowledged": true }
```

**Hata durumları:**
- 💎 premium plan seçildiyse ve kullanıcı premium değilse: 402.
- `requiresSafetyAck` olan planda onay yoksa: 422 `SAFETY_ACK_REQUIRED`.
- Sağlık bayrağı çakışırsa: 422 `UNSAFE_REQUEST`.

**Davranış:**
- Aktif oruç varsa hedefi **değişmez**. Yeni plan bir sonraki orucun hedefidir.
- Eski plan `ended_at` ile kapatılır.

### `PUT /v1/plans/days/:date` 🔐

Haftalık planlarda (5:2, 6:1, ADF) azaltılmış günü işaretler: `{status:"done"|"skipped"}`.
Seri ve dünya hesabına girer ([05 §2.2](05-is-kurallari.md#22-haftalık-planlar)).

### `GET /v1/plans/history` 🔐

---

## 6. Oruç — `fasts`

### `GET /v1/fasts/active` 🔐

Aktif oruç yoksa `data: { "fast": null, "eatingWindow": {...} }` döner.

```jsonc
{ "fast": {
    "id": "…", "status": "active", "planCode": "16_8",
    "startedAt": "2026-10-06T19:30:00.000Z", "plannedEndAt": "2026-10-07T11:30:00.000Z",
    "targetMinutes": 960, "elapsedMinutes": 104, "progress": 0.108,
    "goalReached": false,
    "stage": { "position": 1, "title": "Blood Sugar Rises", "rangeLabel": "0h - 2h",
               "nextStageAt": "2026-10-06T21:30:00.000Z" },
    "serverTime": "2026-10-06T21:14:14.000Z" },
  "eatingWindow": null }
```

İstemci, geri sayımı yerel saatte yürütür. `serverTime`, saat kaymasını düzeltmek için kullanılır.

### `POST /v1/fasts` 🔐 — oruç başlat (idempotent)

```jsonc
{ "id": "<uuidv7, opsiyonel>", "startedAt": "2026-10-06T19:30:00.000Z",   // yoksa şimdi
  "targetMinutes": 960 }                                                     // yoksa aktif plandan
```

- Zaten aktif oruç varsa: 409 `ACTIVE_FAST_EXISTS` (`details.activeFastId`).
- `startedAt` en fazla şimdiden 7 gün önce, en geç şimdiden 5 dk sonra olabilir.
- Önceki seanslarla çakışmamalı.
- **Yan etkiler:** bildirimler planlanır (hedefe ulaşma, yarı yol vb.), `fast.started` olayı yayınlanır.

### `PATCH /v1/fasts/:id` 🔐

`{ startedAt?, targetMinutes? }`

- Aktif seansta başlangıç zamanı veya hedef değiştirilir. Bildirimler yeniden planlanır.
- Tamamlanmış seansta `startedAt`, `endedAt`, `feeling`, `notes` düzenlenebilir. İstatistikler yeniden hesaplanır.

### `POST /v1/fasts/:id/finish` 🔐

```jsonc
// istek
{ "endedAt": "2026-10-07T11:45:00.000Z",     // yoksa şimdi; startedAt'tan ≥1 dk sonra, ≤ şimdi+5dk
  "startedAt": "…",                           // bitiş ekranında düzenlendiyse
  "feeling": "super", "notes": "Kolay geçti",
  "weightKg": 102.1 }                         // opsiyonel → weight_entries(source=fasting_finish)
// yanıt
{ "fast": { …, "status": "completed", "durationMinutes": 975, "goalReached": true },
  "isFirstFast": true,
  "streak": { "current": 6, "best": 12, "increased": true },
  "xpGained": 15, "levelUp": null,
  "world": { "levelUps": [ { "zone": "forest", "from": 1, "to": 2 } ], "health": "thriving" },
  "challenges": [ { "code": "week_fasts_3", "progress": 2, "target": 3 } ] }
```

- Süre hedefin altındaysa durum `endedEarly` olur. Yine de sayılır, ama seriye katkısı [05 §1](05-is-kurallari.md#1-oruç-seansı-durum-makinesi)'e göre belirlenir.

### Diğer oruç uçları

| Uç | Açıklama |
|---|---|
| `POST /v1/fasts/:id/cancel` 🔐 | Yanlışlıkla başlatıldı. 10 dk içindeyse iz bırakmaz. Daha sonra ise `cancelled` olur, istatistiğe girmez |
| `POST /v1/fasts/manual` 🔐 | Geçmiş oruç girme: `{startedAt, endedAt, targetMinutes?, feeling?, notes?}` |
| `GET /v1/fasts?from=&to=&status=&cursor=&limit=` 🔐 | Geçmiş (Profil → Fasting History) |
| `GET /v1/fasts/:id` 🔐 | Detay (not şifresi çözülmüş) |
| `DELETE /v1/fasts/:id` 🔐 | Yumuşak silme + istatistik yeniden hesaplama |
| `GET /v1/fasts/week?date=2026-10-06` 🔐 | Hafta şeridi (Pzt–Paz): `[{date, fastedMinutes, goalMinutes, progress, isRequiredDay}]`. Widget'ın `fasting_week` değeri de buradan gelir |
| `GET /v1/fasts/stats?range=week\|month\|all` 🔐 | Toplamlar + grafik kovaları |
| `POST /v1/fasts/:id/struggles` 🔐 | `{reason, tip?, tipCompleted, outcome?}`. Zorlanma olayı logu (oruç olmadan da `/v1/struggles` ile) |
| `GET /v1/fasts/forecast` 🔐 | **Faz 7+.** `{dayType:"easy\|moderate\|hard", confidence, hungerPeakTime, riskZone:{start,end}, recommendedFastMinutes, curve:[7], peakIndex}` |
| `GET /v1/fasts/daily-tip` 🔐 | **Faz 6+.** "Mochi's Plan for Today": `{fastMinutes, eatMinutes, startAt, endsAt, message}` |

---

## 7. Kilo — `weights`

| Uç | Açıklama |
|---|---|
| `POST /v1/weights` 🔐 | `{id?, weightKg, recordedAt?}` → kayıt + bildirim kutusu ("Weight updates") |
| `PATCH /v1/weights/:id` 🔐, `DELETE /v1/weights/:id` 🔐 | |
| `GET /v1/weights?range=day\|week\|month&cursor=` 🔐 | Ham liste |
| `GET /v1/weights/chart?range=day\|week\|month` 🔐 | 7 kova: `[{label, from, to, weightKg}]` (kovadaki son değer). `yAxis:{min,max}` sunucu tarafından hesaplanır (sabit 65–120 yerine). Etiketler `Accept-Language`'e göre yerelleştirilir |
| `GET /v1/weights/summary` 🔐 | `{currentKg, startKg, goalKg, progress, changeKg, bmi, bmiCategory:"underweight\|normal\|overweight\|obese1\|obese2\|obese3", bmiBand:"low\|normal\|high", heightCm}` |
| `PATCH /v1/weights/goal` 🔐 | `{goalWeightKg}` (profil ile aynı alan) |

## 8. Su — `water`

| Uç | Açıklama |
|---|---|
| `GET /v1/water/day?date=2026-10-06` 🔐 | `{date, totalMl, goalMl, progress, goalReached, glassSizeMl, entries:[{id, amountMl, loggedAt}]}` |
| `POST /v1/water` 🔐 | `{id?, amountMl, loggedAt?}`. Yanıt güncel gün özetidir. Widget'tan gelen kayıtlar `source: widget` ile gelir |
| `DELETE /v1/water/:id` 🔐 | Geri al = son kaydı sil |
| `GET /v1/water/week?date=` 🔐 | `[{date, totalMl, goalMl, progress}]` |

Hatırlatıcı ayarları `PATCH /v1/user/settings` + `PATCH /v1/user/goals` üzerinden yapılır.

## 9. Adım — `steps`

| Uç | Açıklama |
|---|---|
| `PUT /v1/steps/:date` 🔐 | `{steps, source:"manual"}` (upsert) |
| `POST /v1/steps/sync` 🔐 | `{source:"appleHealth\|googleFit", days:[{date, steps, distanceM?, activeKcal?}]}`. En fazla 31 gün, toplu upsert |
| `GET /v1/steps?range=week&date=` 🔐 | `{goal, days:[{date, steps, distanceKm, kcal, durationMin}]}`. Türetilmiş değerler sunucuda hesaplanır ([05 §8](05-is-kurallari.md#8-adım--kalori-türetmeleri)) |

## 10. Uyku — `sleep`

| Uç | Açıklama |
|---|---|
| `POST /v1/sleep` 🔐 | `{id?, sleepStart, sleepEnd, quality?}` |
| `PATCH/DELETE /v1/sleep/:id` 🔐 | |
| `POST /v1/sleep/sync` 🔐 | Sağlık uygulamasından toplu aktarım |
| `GET /v1/sleep/summary?date=` 🔐 | `{lastNight:{durationMin, sleepStart, sleepEnd}, goalMin, progress, schedule:{bedtime, wakeTime}, week:[{date, minutes}]}` |

## 11. Öğün, beslenme ve fotoğraf analizi — `meals`, `nutrition`

### `POST /v1/meals/photo-analyses` 🔐 (kota: [09](09-yapay-zeka.md#4-kotalar))

- `multipart/form-data`, alan `file` (≤ 10 MB) ve opsiyonel `hint` metni.
- Yanıt **202**: `{ "analysisId": "…", "status": "queued", "pollAfterMs": 1500 }`.

### `GET /v1/meals/photo-analyses/:id` 🔐

```jsonc
{ "id": "…", "status": "succeeded",          // queued|processing|succeeded|notFood|failed
  "photo": { "url": "https://media…/…_1024.webp?token=…", "thumbUrl": "…" },
  "result": { "mealTitle": "Izgara tavuk ve fırın sebze", "kcal": 550,
              "proteinG": 27, "carbsG": 64, "fatG": 22, "confidence": 0.78,
              "items": [ { "name": "Izgara tavuk göğsü", "portion": "150 g", "kcal": 250 } ] } }
```

İstemci en fazla 30 sn boyunca 1.5 sn arayla yoklar (poll).

> **Neden asenkron?** Mevcut Dio `receiveTimeout` değeri 15 sn ve analiz 5–15 sn sürebiliyor.
> Asenkron akış hem zaman aşımı riskini hem bağlantı kopmasını tolere eder.

### `POST /v1/meals` 🔐

```jsonc
{ "id": "<uuid?>", "eatenAt": "…",
  "kind": "meal", "slot": "lunch", "dietType": "ketogenic", "feeling": "super",
  "notes": "…",
  "title": "…", "kcal": 550, "proteinG": 27, "carbsG": 64, "fatG": 22,
  "analysisId": "…",                           // fotoğraflı ise; fotoğraf ve AI sonucu bağlanır
  "source": "aiPhoto" | "manual" | "quickKcal" }
```

Aktif oruç varken öğün kaydedilirse yanıt `{ "activeFastId", "suggestEndFast": true }` döner. İstemci "orucu bitir?" diye sorar.

### Diğer öğün ve beslenme uçları

| Uç | Açıklama |
|---|---|
| `GET /v1/meals?date=` veya `?from=&to=&cursor=` 🔐 | Öğün listesi (Meal Records zaman çizelgesi) |
| `GET/PATCH/DELETE /v1/meals/:id` 🔐 | |
| `GET /v1/nutrition/day?date=` 🔐 | `{kcal, kcalGoal, overKcal, burnedKcal, macros:{protein:{g,goalG,progress}, carbs:{…}, fat:{…}}, meals:[…]}`. Calories ve Protein Tracker ekranları |
| `GET /v1/nutrition/week?date=&metric=protein\|kcal` 🔐 | Haftalık çubuk grafik |

## 12. Açlık check-in — `hunger`

| Uç | Açıklama |
|---|---|
| `POST /v1/hunger-checkins/evaluate` 🔐 | Durumsuz (stateless) skorlama. Sonuç ekranı için: `{symptoms[], q1, q2, bodyNotices[], q4}` → `{resultType, physicalScore, emotionalScore, safetyFlag, recommendations:[{code, title, body}]}` |
| `POST /v1/hunger-checkins` 🔐 | Kaydet: aynı gövde + `{id?, notes?, mode}`. Sonuç sunucuda **yeniden hesaplanır**; istemcinin gönderdiği sonuca güvenilmez |
| `GET /v1/hunger-checkins?date=&type=all\|physical\|emotional&cursor=` 🔐 | Geçmiş |
| `GET /v1/hunger-checkins/summary?date=` 🔐 | `{today:{total, physical, emotional}, week:[{date, physical, emotional, fastedMinutes}]}` |
| `DELETE /v1/hunger-checkins/:id` 🔐 | |

## 13. Mochi World & oyunlaştırma — `world`, `challenges`

### `GET /v1/world` 🔐

```jsonc
{ "level": 4,                       // hesap seviyesi (XP)
  "sceneLevel": 2,                  // bölgelerin max'ı (görsel)
  "health": "thriving",             // thriving|wilting|drought
  "worldProgress": 0.42,
  "zones": [
    { "zone": "forest", "metric": "completedFasts", "unit": "fasts",
      "current": 12, "nextThreshold": 25, "level": 2, "ratioToNext": 0.13 },
    { "zone": "lake",   "metric": "waterGoalDays",  "unit": "days",  "current": 9,  "nextThreshold": 14, "level": 2 },
    { "zone": "summit", "metric": "weightLostKg",   "unit": "kg",    "current": 3.4,"nextThreshold": 5,  "level": 2 },
    { "zone": "garden", "metric": "mealsLogged",    "unit": "meals", "current": 18, "nextThreshold": 30, "level": 2 } ],
  "week": [ { "date": "2026-10-05", "fastedMinutes": 970 }, … ] }
```

### Challenge uçları

| Uç | Açıklama |
|---|---|
| `GET /v1/challenges` 🔐 | Aktif katalog + benim katılımım: `[{code, title, subtitle, badge, targetCount, durationDays, participantsCount, participantAvatars:[url×3], isPremium, my:{status, progress, windowEnd} \| null}]` |
| `GET /v1/challenges/featured` 🔐 | Ana sayfa kartı (tek kayıt) |
| `POST /v1/challenges/:code/join` 🔐 | Rolling pencere başlar. Aktif katılım zaten varsa 409 |
| `POST /v1/challenges/:code/leave` 🔐 | |

## 14. Coach Mochi sohbeti — `chat` (ayrıntı: [09](09-yapay-zeka.md))

| Uç | Açıklama |
|---|---|
| `GET /v1/chat/suggestions?context=general\|fasting\|hungerPhysical…` 🔐 | `[{code, text}]` |
| `GET /v1/chat/quota` 🔐 | `{plan:"free\|premium", dailyLimit, usedToday, resetAt}` |
| `GET /v1/chat/conversations?cursor=` 🔐 | Önce sabitlenenler, sonra `lastMessageAt` azalan sırada: `[{id, title, messageCount, lastMessageAt, isPinned}]` |
| `POST /v1/chat/conversations` 🔐 | `{contextSource?, contextRef?}` → `{id}` |
| `GET /v1/chat/conversations/:id/messages?cursor=&limit=50` 🔐 | Eskiden yeniye: `[{id, role:"user\|assistant", text, status, createdAt}]` |
| `POST /v1/chat/conversations/:id/messages` 🔐💎* | **SSE akışı** (aşağıda). *Ücretsiz kullanıcıya günlük kota uygulanır |
| `PATCH /v1/chat/conversations/:id` 🔐 | `{isPinned?, title?}` |
| `DELETE /v1/chat/conversations/:id` 🔐 | |
| `POST /v1/chat/messages/:id/feedback` 🔐 | `{rating:"up\|down", reason?}` |

**SSE sözleşmesi** (`Accept: text/event-stream`):

```
POST /v1/chat/conversations/:id/messages
{ "id": "<client uuid>", "text": "Kahve içebilir miyim?" }

event: message.created
data: {"userMessageId":"…","assistantMessageId":"…"}

event: delta
data: {"text":"Evet squish! Sade kahve"}

event: delta
data: {"text":" orucu bozmaz ☕"}

event: message.completed
data: {"assistantMessageId":"…","usage":{"remainingToday":7}}

event: error
data: {"code":"QUOTA_EXCEEDED","message":"…","resetAt":"…"}
```

- Kalp atışı (heartbeat): her 15 sn'de `: ping`.
- Aynı konuşmada eşzamanlı ikinci istek: 409 `REPLY_IN_PROGRESS`.
- `Accept: application/json` gönderilirse akışsız tam yanıt döner (yedek yol).

## 15. Öğren (Insights) — `insights`

| Uç | Açıklama |
|---|---|
| `GET /v1/insights/categories` 🔓 | `[{slug, title, description, iconKey, bgColor, isPremium, articleCount}]` |
| `GET /v1/insights/articles?category=&q=&cursor=` 🔓 | `q` sunucu tarafında FULLTEXT ile, tüm içerikte aranır |
| `GET /v1/insights/articles/:slug` 🔓 (💎 premium içerikte) | `{slug, kicker, title, subtitle, quote, quoteAuthor, sections:[{iconKey, title, body}], tip, coverUrl, isRead, isBookmarked}` |
| `POST /v1/insights/articles/:slug/read` 🔐 | |
| `PUT /v1/insights/articles/:slug/bookmark` 🔐, `DELETE …/bookmark` 🔐 | |
| `GET /v1/insights/bookmarks` 🔐 | |

## 16. Bildirimler — `notifications`

| Uç | Açıklama |
|---|---|
| `GET /v1/notifications?cursor=` 🔐 | `[{id, type, category, title, body, params, iconKey, deepLink, createdAt, readAt}]`. `title`/`body` sunucuda kullanıcının diline göre render edilir; `params` istemcide vurgulama için (ör. `weightKg`) |
| `GET /v1/notifications/unread-count` 🔐 | `{count}` |
| `POST /v1/notifications/:id/read` 🔐, `POST /v1/notifications/read-all` 🔐 | |
| `DELETE /v1/notifications/:id` 🔐 | Kaydırarak silme |

## 17. Abonelik — `subscription`

| Uç | Açıklama |
|---|---|
| `GET /v1/subscription` 🔐 | `{isPremium, entitlement, status, productId, store, periodType, expiresAt, willRenew, managementUrl}` |
| `POST /v1/subscription/sync` 🔐 | Satın alma sonrası. Sunucu RevenueCat REST'ten doğrular ve günceller |
| `POST /v1/webhooks/revenuecat` (webhook auth header) | [11](11-abonelik.md) |

## 18. Medya — `media`

| Uç | Açıklama |
|---|---|
| `POST /v1/media` 🔐 | `multipart`, `purpose=mealPhoto` → `{id, url, thumbUrl}` (öğüne fotoğrafı AI'sız eklemek için) |
| `DELETE /v1/media/:id` 🔐 | |

Medya URL'leri ilgili kaynakların yanıtına **imzalı** olarak gömülür. Ayrı bir "URL ver" ucu yoktur.

## 19. Yönetim — `admin` 🛡️ (faz 10)

**Kimlik doğrulama:**
- `/v1/admin/auth/login`: e-posta + şifre + TOTP.
- Ayrı JWT `aud=admin`, 1 saat ömürlü.
- IP allowlist uygulanır.

**Uçlar:**

| Alan | Yapılabilecekler |
|---|---|
| İçerik | plan, evre, struggle, insights, FAQ, öneri, challenge, bildirim şablonu CRUD + çeviriler |
| `app_config` | düzenleme |
| Kullanıcı arama (destek) | id ya da e-posta ile; kişisel veri maskeli |
| Destek işlemleri | oturumları sonlandır, premium tanımla (promotional), silme talebini hızlandır |
| Raporlar | kayıt, aktif kullanıcı, dönüşüm, AI maliyeti |

Tüm yönetici işlemleri `audit_logs` tablosuna yazılır.

## 20. Operasyon

| Uç | Erişim |
|---|---|
| `GET /health/live`, `GET /health/ready` | Deploy kontrolü ve dış izleme |
| `GET /metrics` | Yalnızca iç ağ |
| `GET /docs` | Dev/staging, basic auth |

## Eski (prefix'siz) yollar — geçiş uyumluluğu

| Eski | Yeni |
|---|---|
| `POST /auth/register` | `POST /v1/auth/register` |
| `GET /user/me` | `GET /v1/user/me` |
| `GET /user/progress` | `GET /v1/user/progress` |
| `PATCH /user/onboarding` | 200 + yok sayılır (`Deprecation: true`) |

İstemci `/v1`'e geçtikten ve minimum sürüm yükseltildikten sonra eski yollar kaldırılır.
