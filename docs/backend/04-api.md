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

**Misafir sırrı:** yanıtta `guestSecret` (`gs_…`) yalnızca yeni verildiğinde döner (misafir oluşturulurken ya da eski sırsız misafirin ilk girişinde); istemci güvenli depoda saklar ve aynı `installId` ile sonraki her girişte gövdede `guestSecret` gönderir. Eksik/yanlışsa `401 UNAUTHENTICATED {reason: "guest_secret_invalid"}` — istemci yeni `installId` ile yeni misafir açar. `POST /auth/register {provider:"guest"}` için de aynı kural.

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

- `multipart/form-data`, alan `file`, en fazla 10 MB (aşınca 413).
- Kabul edilen türler (içerikten, magic byte ile): jpeg/png/webp. HEIC/SVG/PDF → 415 (HEIC'te `details.hint: "convert_to_jpeg"`; istemci JPEG'e çevirir).
- Yanıt: `{ "avatar": <medya> }` (aşağıdaki medya biçimi; `md` 512, `thumb` 128). Senkron çalışır. Eski avatar hemen silinir. Ayrıntı: [08](08-medya-bunny.md).
- `GET /v1/user/me` → `avatarUrl` (imzalı, `md`).
- Kullanıcı başına saatte 30 yükleme.

### `DELETE /v1/user/me/avatar` 🔐

Avatarı kaldırır, dosyaları siler.

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

Ana sayfayı, profil başlığını, oruç sekmesi başlığını ve widget'ları besleyen birleşik yanıt. Şimdilik cache'lenmez: oruç, plan, profil ve hedef yazmalarının hepsi özeti değiştirir; 15 sn cache ([07](07-cache-performans.md)) bu invalidation'lar F4'te takipçilerle birlikte bağlanınca eklenir.

```jsonc
{ "user": { "id", "name", "avatarUrl", "isPremium", "isGuest" },
  "progress": { /* GET /v1/user/progress ile aynı */ },
  "activeFast": { /* GET /v1/fasts/active → fast, yoksa null */ },
  "eatingWindow": { /* GET /v1/fasts/active → eatingWindow */ },
  "plan": { "planCode": "16_8", "displayName": "16:8", "fastMinutes": 960,
            "eatWindow": {"start":"12:00","end":"20:00"} },     // yoksa null
  "pendingPlanCode": null,
  "week": [ /* GET /v1/fasts/week → days (7 gün) */ ],
  "today": {
    "date": "2026-10-07",                                       // kullanıcının yerel günü
    "water": { "ml": 600, "goalMl": 2500 },
    "steps": { "count": 1000, "goal": 8000 },
    "sleep": { "minutes": 450, "goalMin": 450 },
    "nutrition": { "kcal": 1240, "kcalGoal": 1850 },
    "lastMeal": { "id", "eatenAt", "kind": "meal", "dietType": "ketogenic", "feeling": "good" } | null,
    "hunger": { "physical": 2, "emotional": 1 } },
  "weight": { "currentKg": 102.5, "startKg": 112.2, "goalKg": 75.2, "progress": 0.26 },
  "featuredChallenge": { /* §12 */ } | null,
  "unreadNotifications": 2,
  "serverTime": "…" }
```

`featuredChallenge` öne çıkan challenge (katılımımla), `unreadNotifications` F9'a kadar 0 döner; diğer alanların hepsi gerçek veridir. `today.nutrition.kcalGoal`, `eating_disorder_history` bayrağında null. `lastMeal`: `{id, eatenAt, kind, dietType, feeling, title, kcal}`.

### `GET /v1/user/progress` 🔐 (mevcut yol korunur)

`{ level, xp, levelXp, nextLevelXp, streakDays, bestStreak, completedFasts, totalFasts, totalFastedMinutes, longestFastMinutes }` döner. `level`, `streakDays`, `completedFasts` eski istemcinin alanlarıdır, değişmez; diğerleri eklenmiştir.

Seri, kullanıcının yerel gününe göre hesaplanır. Son hesap dünden kaldıysa (gün döndüyse) okuma sırasında yenilenir; gün dönümü işi kaçsa da seri doğru görünür.

### `GET /v1/user/stats?range=week|month|year|all` 🔐

Varsayılan `range=all`. Aralık bugünle biter (week = son 7 gün, month = 30, year = 365).

```jsonc
{ "range": "all", "from": null, "to": "2026-10-07",
  "fasts": 23, "completedFasts": 20, "completionRate": 0.87,
  "totalFastedMinutes": 21000, "longestFastMinutes": 1260, "avgFastMinutes": 913,
  "currentStreak": 5, "bestStreak": 12,          // seri aralıktan bağımsız
  "weightChangeKg": -2.4,                        // aralıktaki ilk ve son ölçüm; < 2 ölçümde null
  "waterGoalDays": 0, "mealsLogged": 0 }         // F4'te dolar
```

### Hesap & veri

| Uç | Açıklama |
|---|---|
| `POST /v1/user/consents` 🔐 | `{type, version, granted}`. Yalnızca ekleme yapılır (append-only). Yanıt ve `GET /v1/user/consents`: her tür için son durum `{items:[{type, version, granted, at}]}` |
| `DELETE /v1/user/me` 🔐 | Hesap silme talebi. Gövde: `{reason?}`. Yanıt 202 `{scheduledFor, hasActiveSubscription}`. Oturumlar hemen iptal edilir, push token'lar silinir, planlı bildirimler iptal edilir, hesap `pending_deletion` olur. 7 gün sonra silme işi çalışır ([06 §8.3](06-guvenlik.md#83-hesap-silme-akışı)). Tekrar çağrı aynı talebi döner. `hasActiveSubscription: true` ise istemci "aboneliğini mağazadan iptal et" uyarısı gösterir |
| Geri alma | Süre içinde Apple/Google (ya da aynı cihazla misafir) girişi `409 ACCOUNT_PENDING_DELETION` döner: `details: {scheduledFor, options:["restore"]}`. İstemci sorar; aynı istek `"restoreAccount": true` ile tekrarlanınca talep iptal edilir ve giriş yapılır (`/auth/register` ve `/auth/guest`). Ayrı bir `/user/me/restore` ucu yoktur: silme talebindeki hesabın geçerli oturumu olmaz |
| `POST /v1/user/me/export` 🔐 | 202 `{export}`. Günde 1: son 24 saatte talep varsa o döner. Hazır olunca `data_export_ready` bildirimi (`params.exportId`) |
| `GET /v1/user/me/export/:id` 🔐 | `{export: {id, status: queued\|processing\|ready\|expired\|failed, requestedAt, completedAt, expiresAt, bytes, url, urlExpiresAt}}`. `url` yalnızca `ready` iken; 1 saatlik imzalı link, her çağrıda yenisi. Dosya 7 gün sonra silinir |

- **Zip içeriği:** `data/*.json` (her domain), `csv/*.csv` (oruç, kilo, su, adım, uyku, öğün, açlık, günlük özet, zorlanma), `photos/meals|avatar/*.webp`, `README.txt`, `manifest.json`. Şifreli notlar ve sohbet metni çözülmüş olarak verilir; token, push token ve IP verilmez.
- **Yasal metin güncellemesi:** `GET /v1/user/me` → `requiredConsents: ["terms","privacy"]` (onboarding tamamlanmış ve son onaylanan sürüm `app_config.legal.*Version`'dan farklıysa). İstemci yeniden onay ekranı gösterir → `POST /v1/user/consents {type, version, granted:true}`.
- **Rıza geri çekme:** `healthData: false` → sağlık kaydı yazan uçlar (kilo, su, adım, uyku, öğün, açlık; POST/PATCH/PUT) `403 CONSENT_REQUIRED {consent:"healthData"}`; silme serbest. `marketingPush: false` → `notifications.marketing` kapanır. `aiProcessing: false` → AI uçları 403.

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
| `GET /v1/catalog/stages?type=body\|eating_window` 🔓 | `{ type, items: [{position, startHour, endHour, rangeLabel, title, body, imageKey, images:{idle, reached}}] }`. Görseller mantıksal yoldur (`assets/images/…png`), istemci `appImage()` ile yükler |
| `GET /v1/catalog/struggle` 🔓 | `{ intro:{title,body}, reasons:[{code,title,body,image,tips:[tipCode…]}], tips:[{code,title,body,image,activity:{type:sips\|timer\|breathing,…}, session:{title,body}, done:{title,body,button}}] }` |
| `GET /v1/catalog/onboarding-options` 🔓 | `{ goals, genders, diets, foodLoves, foodSkips, weightHistories, obstacles, fastingReasons:[…, days], plans:[plan özeti + title, subtitle, badge, badgeColor] }`. Seçenek: `{code (API enum), title, subtitle?, badge?, image?}`. Uygulamadaki sabit listelerin uzaktan güncellenebilmesi için |
| `GET /v1/catalog/faq` 🔓 | `{ items: [{code, question, answer}] }` |
| `GET /v1/catalog/chat-suggestions` 🔓 | `{ items: [{code, text}] }` (sohbet ekranındaki hazır öneriler) |
| `GET /v1/insights/categories` 🔓 | `{ items: [{slug, title, description, icon, iconImage, bgColor, isPremium, isLocked, articleCount}] }` |
| `GET /v1/insights/articles?category=&q=&limit=&cursor=` 🔓 | Sayfalı `{ items: [{slug, category, kicker, title, subtitle, readMinutes, isPremium, isLocked}], pageInfo }`. `q`: her kelime bir kelimenin başında geçmeli (başlık + bölümler), dil ve büyük/küçük harf duyarsız |
| `GET /v1/insights/articles/:slug` 🔓 | Makale + `quote, quoteAuthor, tip, sections:[{position, icon, iconImage, title, body}]`. Kilitli makale 402 `PREMIUM_REQUIRED`, bilinmeyen 404 |
| `GET /v1/app/config` 🔓 | `{ platform, minAppVersion, latestAppVersion, updateRequired, updateAvailable, features:{chat,photoAnalysis,challenges,forecast}, limits:{freeChatDaily,freePhotoDaily,premiumChatDaily,premiumPhotoDaily}, marketing:{activeUsers:"2M+", rating:4.8, avgStreakDays:12, trustedBy:"200K+"}, legal:{termsUrl, privacyUrl, termsVersion, privacyVersion}, support:{email}, catalogVersion }`. Platform `?platform=` ya da `X-Platform`; sürümü eski istemci de erişir |

---

## 5. Planlar — `plans`

### `GET /v1/plans/current` 🔐

```jsonc
{ "plan": {
    "id": "…", "planCode": "16_8", "displayName": "16:8", "timing": "skipBreakfast",
    "fastMinutes": 960, "eatWindow": { "start": "12:00", "end": "20:00" },
    "weeklySchedule": null,          // haftalık planlarda [ { "dow": 1, "type": "reduced", "kcal": 500 }, … ]
    "startedOn": "2026-10-01", "isPremium": false },
  "pendingPlanCode": null }          // onboarding'de 💎 plan seçildiyse plan=null, kod burada bekler (F8'de etkinleşir)
```

`PUT` aynı şekli döner. Onboarding'de seçilen ücretsiz plan, öğün penceresine göre `timing: "custom"` ile otomatik etkinleşir.

### `PUT /v1/plans/current` 🔐

```jsonc
{ "planCode": "18_6", "timing": "custom",
  "eatWindow": { "start": "13:00", "end": "19:00" },     // custom/timing seçimine göre
  "fastMinutes": 1080,                                   // custom_daily için 720–1380
  "weeklySchedule": [ … ],                               // custom_weekly / 5:2 / ADF için zorunlu
  "safetyAcknowledged": true }
```

**Hata durumları:**
- 💎 premium plan seçildiyse ve kullanıcı premium değilse: 402 `PREMIUM_REQUIRED` (`details.planCode`).
- Plan zamanlaması/penceresi plan kuralına uymuyorsa (ör. 16:8'de 10 sa pencere): 400 `VALIDATION_ERROR`.
- `requiresSafetyAck` olan planda onay yoksa: 422 `SAFETY_ACK_REQUIRED`.
- Sağlık bayrağı çakışırsa: 422 `UNSAFE_REQUEST`.

**Davranış:**
- Aktif oruç varsa hedefi **değişmez**. Yeni plan bir sonraki orucun hedefidir.
- Eski plan `ended_at` ile kapatılır.

### `PUT /v1/plans/days/:date` 🔐

Haftalık planlarda (5:2, 6:1, ADF, seçili günler) planlı günü işaretler: `{status:"done"|"skipped"}`. Yalnızca son 7 gün; planlı gün değilse 409 `CONFLICT` (`details.reason: "not_a_plan_day"`).
Seri ve dünya hesabına girer ([05 §2.2](05-is-kurallari.md#22-haftalık-planlar)).

### `GET /v1/plans/history?cursor=&limit=` 🔐

Yeniden eskiye plan geçmişi: `{items:[{…plan, endedAt}], pageInfo}`. Aktif planın `endedAt` değeri `null`.

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
               "imageKey": "a1", "nextStageAt": "2026-10-06T21:30:00.000Z" },
    "serverTime": "2026-10-06T21:14:14.000Z" },
  "eatingWindow": null }
```

İstemci, geri sayımı yerel saatte yürütür. `serverTime`, saat kaymasını düzeltmek için kullanılır.

Son oruç bittikten sonra, yeme penceresi süresince (`1440 − plan.fastMinutes`, en az 60 dk):

```jsonc
{ "fast": null,
  "eatingWindow": {
    "lastFastId": "…", "startedAt": "…", "endsAt": "…", "eatMinutes": 480, "elapsedMinutes": 35,
    "stage": { "key": "break", "title": "Orucu aç", "position": 1 },   // break → open → next
    "suggestedNextStartAt": "…", "serverTime": "…" } }
```

Evreler: `break` = ilk max(%20, 30 dk), `next` = son 60 dk, arası `open`. Pencere dışında `eatingWindow: null`.

### `POST /v1/fasts` 🔐 — oruç başlat (idempotent)

```jsonc
{ "id": "<uuidv7, opsiyonel>", "startedAt": "2026-10-06T19:30:00.000Z",   // yoksa şimdi
  "targetMinutes": 960 }                                                     // yoksa aktif plandan
```

- Zaten aktif oruç varsa: 409 `ACTIVE_FAST_EXISTS` (`details.activeFastId`).
- `startedAt` en fazla şimdiden 7 gün önce, en geç şimdiden 5 dk sonra olabilir.
- Önceki seanslarla çakışmamalı: 409 `FAST_OVERLAP`.
- İstemci `id` gönderip tekrar denerse aynı oruç **200** ile döner (ilk istek 201).
- Tüm yazma uçları `Idempotency-Key` başlığını (8–64 karakter `[A-Za-z0-9_-]`) destekler: aynı anahtar + aynı gövde → saklı yanıt (`Idempotent-Replayed: true`); aynı anahtar + farklı gövde → 409 `IDEMPOTENCY_KEY_REUSED`; ilk istek hâlâ işleniyorsa 409 `CONFLICT`. Anahtarlar 24 sa saklanır.
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
  "warnings": [],                             // hedef + 12 sa aşıldıysa ["LONG_OVERRUN"]
  "streak": { "current": 6, "best": 12, "increased": true },
  "xpGained": 15,                             // oruç XP'si + bu bitişle ulaşılan seri taşı XP'si
  "levelUp": null,                            // ya da { "from": 1, "to": 2 }
  "world": { "levelUps": [ { "zone": "forest", "from": 0, "to": 1 } ], "health": "thriving" },
  "challenges": [ { "code": "week_fasts_3", "progress": 2, "target": 3, "status": "active" } ] }
```

Bitirme, düzenleme, elle kayıt ve silme; günlük özetleri, seriyi, sayaçları ve XP'yi **aynı transaction'da** yeniden hesaplar ([05 §14](05-is-kurallari.md#14-yeniden-hesaplama-recompute-garantisi)). Bu yüzden yanıt döndüğünde `/user/progress` ve `/fasts/week` günceldir.

- Süre hedefin altındaysa durum `endedEarly` olur. Yine de sayılır, ama seriye katkısı [05 §1](05-is-kurallari.md#1-oruç-seansı-durum-makinesi)'e göre belirlenir.

### Diğer oruç uçları

| Uç | Açıklama |
|---|---|
| `POST /v1/fasts/:id/cancel` 🔐 | Yanlışlıkla başlatıldı. 10 dk içindeyse iz bırakmaz. Daha sonra ise `cancelled` olur, istatistiğe girmez |
| `POST /v1/fasts/manual` 🔐 | Geçmiş oruç girme: `{startedAt, endedAt, targetMinutes?, feeling?, notes?}`. En fazla 30 gün geriye; `localDate` bitişin yerel günüdür |
| `GET /v1/fasts?from=&to=&status=&cursor=&limit=` 🔐 | Geçmiş (Profil → Fasting History) |
| `GET /v1/fasts/:id` 🔐 | Detay (not şifresi çözülmüş) |
| `DELETE /v1/fasts/:id` 🔐 | Yumuşak silme + istatistik yeniden hesaplama. Aktif oruç silinemez (409; önce iptal) |
| `GET /v1/fasts/week?date=2026-10-06` 🔐 | Hafta şeridi (Pzt–Paz; `date` yoksa bu hafta): `{weekStart, today, serverTime, days:[{date, dayType:"fast\|reduced\|normal", isRequiredDay, goalMinutes, fastedMinutes, progress, checkin, kept, isToday, isFuture}]}`. Aktif oruç bugüne canlı eklenir. `kept`: gelecek gün ve henüz tutulmamış bugün için `null`; nötr günde `null`. Widget'ın `fasting_week` değeri de buradan gelir |
| `GET /v1/fasts/forecast` 🔐 | Fast Forecast v0: `{forecast:{available, successChance (0–1), basedOnFasts, toughestElapsedHour, toughestAt, fast:{active, startsAt, endsAt}}}`. Son 14 günde < 3 biten oruç → `{available:false}` (kart gizlenir). Başarı: `(hedefe ulaşan+1)/(biten+2)` + seri bonusu (gün başına %1, en çok %7), %5–%97. En zor saat: son 30 günün zorlanma olaylarında orucun en sık saati (≥ 3 olay). Oruç: aktifse o, yoksa planın yeme penceresi sonundan başlayan sıradaki |
| `GET /v1/fasts/daily-tip` 🔐 | Günün ipucu: `{tip:{code, phase:"fast\|eat", date, text}}`. AI yok; katalogdaki `daily_tip` etiketlerinden (7 dil), oruç sürüyorsa `fast_*`, değilse `eat_*`; kullanıcı + yerel gün için sabit seçim |
| `GET /v1/fasts/stats?range=week\|month\|year\|all` 🔐 | `{range, from, to, bucketSize:"day\|month", totals:{fasts, completedFasts, completionRate, totalFastedMinutes, longestFastMinutes, avgFastMinutes}, buckets}`. week/month: günlük `[{date, fastedMinutes, goalMinutes}]`; year/all: aylık `[{month, fastedMinutes, fasts}]`. `fasts` 60 dk ve üstü bitmiş oruçlardır |
| `POST /v1/fasts/:id/struggles` 🔐 | `{reason, tip?, tipCompleted, outcome?}` → 201 `{id, elapsedMinutes}`. Zorlanma olayı logu (oruç olmadan da `/v1/struggles` ile; o zaman `elapsedMinutes: null`) |
| `GET /v1/fasts/forecast` 🔐 | **Faz 7+.** `{dayType:"easy\|moderate\|hard", confidence, hungerPeakTime, riskZone:{start,end}, recommendedFastMinutes, curve:[7], peakIndex}` |
| `GET /v1/fasts/daily-tip` 🔐 | **Faz 6+.** "Mochi's Plan for Today": `{fastMinutes, eatMinutes, startAt, endsAt, message}` |

---

## 7. Kilo — `weights`

| Uç | Açıklama |
|---|---|
| `POST /v1/weights` 🔐 | `{id?, weightKg, recordedAt?}` → 201 `{entry:{id, weightKg, recordedAt, localDate, source}}`. Aynı `id` tekrar gelirse 200 ve aynı kayıt. `recordedAt` en fazla 365 gün geriye, 5 dk ileriye |
| `PATCH /v1/weights/:id` 🔐 | `{weightKg?, recordedAt?}` → `{entry}` |
| `DELETE /v1/weights/:id` 🔐 | Yumuşak silme |
| `GET /v1/weights?from=&to=&cursor=&limit=` 🔐 | Ham liste, yeniden eskiye (`recordedAt`) |
| `GET /v1/weights/chart?range=day\|week\|month` 🔐 | `{range, goalKg, yAxis:{min,max}, buckets:[{label, from, to, weightKg}]}`. 7 kova, kovadaki son ölçüm; ölçüm yoksa `null`. `yAxis` ölçümler **ve hedef** üzerinden hesaplanır (hedef çizgisi görünsün). Etiketler `Accept-Language`'e göre: day → "Çar", week → "5 Eki", month → "Eki" |
| `GET /v1/weights/summary` 🔐 | `{currentKg, startKg, goalKg, progress, changeKg, bmi, bmiCategory:"underweight\|normal\|overweight\|obese1\|obese2\|obese3", bmiBand:"low\|normal\|high", heightCm, targetDate}` |
| `PATCH /v1/weights/goal` 🔐 | `{goalWeightKg}` → özet + `warnings`. Profil güncellemesiyle aynı doğrulama (kilo verme hedefinde hedef ≤ güncel) |

Her kilo yazması o günün özetini (`daily_summaries.weight_kg`) ve kilo XP'sini (günde bir, 3 XP) aynı transaction'da günceller. Onboarding kilosu XP vermez.

## 8. Su — `water`

| Uç | Açıklama |
|---|---|
| `GET /v1/water/day?date=2026-10-06` 🔐 | `{date, totalMl, goalMl, progress, goalReached, glassSizeMl, entries:[{id, amountMl, loggedAt, source}], warnings}` |
| `POST /v1/water` 🔐 | `{id?, amountMl (1–5000), loggedAt?, source?: "app"\|"widget"}`. Yanıt güncel gün özetidir (201; aynı `id` tekrar gelirse 200). `loggedAt` en fazla 7 gün geriye. Günlük toplam 6000 ml'yi aşınca `warnings: ["HIGH_WATER_INTAKE"]` |
| `DELETE /v1/water/:id` 🔐 | Geri al. Yanıt güncel gün özetidir |
| `GET /v1/water/week?date=` 🔐 | `{weekStart, days:[{date, totalMl, goalMl, progress, goalReached, isToday, isFuture}]}` (Pzt–Paz) |

- Toplam, kaydın **yerel gününe** göre hesaplanır: 23:50'deki bardak o güne, 00:10'daki ertesi güne yazılır.
- `goalMl`: bugün ve gelecek için güncel hedef, geçmiş gün için o günün anlık görüntüsü.
- Hedefin tutturulduğu gün 5 XP verir ve `user_stats.water_goal_days` sayacına girer. Kayıt silinip hedefin altına düşülürse ikisi de geri alınır.

Hatırlatıcı ayarları `PATCH /v1/user/settings` + `PATCH /v1/user/goals` üzerinden yapılır.

## 9. Adım — `steps`

| Uç | Açıklama |
|---|---|
| `PUT /v1/steps/:date` 🔐 | `{steps, source?:"manual"}` (upsert). Gün sağlık uygulamasından senkronlanmışsa 409 `CONFLICT` (`details:{reason:"synced_day", source}`). Yanıt: o günün `GET /steps?range=day` çıktısı |
| `POST /v1/steps/sync` 🔐 | `{source:"appleHealth\|googleFit", days:[{date, steps, distanceM?, activeKcal?}]}`. En fazla 31 gün, toplu upsert. Yanıt `{updated, skipped}` |
| `GET /v1/steps?range=day\|week\|month&date=` 🔐 | `{range, from, to, goal, days:[{date, steps, distanceKm, kcal, durationMin, progress, source, isFuture}]}`. week = Pzt–Paz, month = takvim ayı |

Türetilmiş değerler ([05 §8](05-is-kurallari.md#8-adım--kalori-türetmeleri)): sağlık uygulaması mesafe/kalori gönderdiyse o, yoksa boy ve kiloya göre formül. Tarih bugünden ileri ya da 31 günden eski olamaz (400).

## 10. Uyku — `sleep`

| Uç | Açıklama |
|---|---|
| `POST /v1/sleep` 🔐 | `{id?, sleepStart, sleepEnd, quality? (1–5)}` → 201 `{entry}`. Uyanış gününe (`localDate`) yazılır. En fazla 16 sa; başka kayıtla çakışırsa 409 `CONFLICT` (`details.reason: "sleep_overlap"`) |
| `PATCH /v1/sleep/:id` 🔐, `DELETE /v1/sleep/:id` 🔐 | Düzenleme aynı kurallarla; silme yumuşak |
| `POST /v1/sleep/sync` 🔐 | `{source:"appleHealth\|googleFit", entries:[{externalId, sleepStart, sleepEnd}]}` (en fazla 100). `externalId` ile idempotent: tekrar gönderim aynı kaydı günceller. Yanıt `{created, updated}` |
| `GET /v1/sleep/summary?date=` 🔐 | `{date, lastNight:{…entry, totalMinutes} \| null, goalMin, progress, schedule:{bedtime, wakeTime}, week:[{date, minutes}]}`. `lastNight` günün en uzun kaydıdır; `totalMinutes` şekerlemeleri de içerir |

## 11. Öğün, beslenme ve fotoğraf analizi — `meals`, `nutrition`

### `POST /v1/meals/photo-analyses` 🔐 (kota: [09](09-yapay-zeka.md#4-kotalar))

- `multipart/form-data`, alan `file` (≤ 10 MB; jpeg/png/webp). Sonuç dili `Accept-Language`.
- Yanıt **202**: `{ "analysisId": "…", "status": "queued", "pollAfterMs": 1500 }`.
- Aynı fotoğraf 24 sa içinde tekrar gönderilirse önceki analiz döner; yeni AI çağrısı yapılmaz, hak düşmez.
- Hatalar: `ai_processing` rızası yok → 403 `CONSENT_REQUIRED` (`details.consent: "aiProcessing"`); günlük kota doldu → 429 `QUOTA_EXCEEDED` (`details: {kind, limit, used, resetAt, upgradeAvailable}`); AI kapalı/devre açık/günlük bütçe doldu → 503 `UNAVAILABLE` (`details.reason: ai_disabled | ai_circuit_open | ai_budget`).

### `GET /v1/meals/photo-analyses/:id` 🔐

```jsonc
{ "analysis": {
    "id": "…", "status": "succeeded",          // queued|processing|succeeded|notFood|failed
    "photo": <medya>,                          // §18 medya biçimi
    "result": { "mealTitle": "Izgara tavuk ve fırın sebze", "kcal": 550,
                "proteinG": 27, "carbsG": 64, "fatG": 22, "confidence": 0.78,
                "items": [ { "name": "Izgara tavuk göğsü", "portion": "150 g", "kcal": 250,
                             "proteinG": 46, "carbsG": 0, "fatG": 6 } ],
                "notes": "Sos miktarı belirsiz",
                "flags": [] },                 // totals_recomputed | macro_mismatch (sunucu düzeltmesi)
    "error": null,                             // failed: {code: REFUSED|TRUNCATED|INVALID_OUTPUT|AI_UNAVAILABLE|AI_ERROR|TIMEOUT}
    "createdAt": "…", "completedAt": "…" } }
```

Başarısız analizde (ret, hata, zaman aşımı) kota iade edilir. `notFood` hak düşer (AI çağrısı yapıldı). Öğün `POST /v1/meals {analysisId, …}` ile kaydedilir: fotoğraf bağlanır, kaynak `aiPhoto` olur, değerler kullanıcı tarafından düzenlenebilir; analiz `succeeded` değilse 409.

İstemci en fazla 30 sn boyunca 1.5 sn arayla yoklar (poll).

> **Neden asenkron?** Mevcut Dio `receiveTimeout` değeri 15 sn ve analiz 5–15 sn sürebiliyor.
> Asenkron akış hem zaman aşımı riskini hem bağlantı kopmasını tolere eder.

### `POST /v1/meals` 🔐

```jsonc
{ "id": "<uuid?>", "eatenAt": "…",            // yoksa şimdi; en fazla 30 gün geriye
  "kind": "meal", "slot": "lunch", "dietType": "ketogenic", "feeling": "super",
  "notes": "…",                                // şifreli saklanır, ≤ 1000
  "title": "…", "kcal": 550, "proteinG": 27, "carbsG": 64, "fatG": 22,
  "photoMediaId": "…",                         // POST /v1/media ile yüklenmiş kendi fotoğrafı
  "source": "manual" | "quickKcal" }           // "aiPhoto" + analysisId F6'da açılır
// yanıt (201; aynı id tekrar gelirse 200)
{ "meal": { …, "localDate": "2026-10-07", "photo": <medya> | null },
  "activeFastId": "…" | null, "suggestEndFast": true }
```

Öğün aktif orucun başlangıcından sonra yenmişse `suggestEndFast: true` ve `activeFastId` döner. İstemci "orucu bitir?" diye sorar, onaylanırsa `POST /fasts/:id/finish` çağırır. Her öğün yazması o günün özetini (kcal, makrolar, öğün/ara öğün sayısı) ve öğün XP'sini (öğün başına 2, günde en fazla 5 öğün) aynı transaction'da günceller.

### Diğer öğün ve beslenme uçları

| Uç | Açıklama |
|---|---|
| `GET /v1/meals?date=` 🔐 | Günün zaman çizelgesi (eskiden yeniye, sayfasız) |
| `GET /v1/meals?from=&to=&cursor=&limit=` 🔐 | Sayfalı geçmiş (yeniden eskiye) |
| `GET/PATCH/DELETE /v1/meals/:id` 🔐 | `PATCH` kısmi; `notes: null` notu siler. Silme yumuşak |
| `GET /v1/nutrition/day?date=` 🔐 | `{date, kcal, kcalGoal, progress, overKcal, burnedKcal, macros:{protein:{g, goalG, progress}, carbs:{…}, fat:{…}}, meals:[…]}`. Hedef: kullanıcının girdiği, yoksa öneri (bugünün adım kalorisi dahil). `eating_disorder_history` bayrağında tüm hedefler, `progress` ve `overKcal` `null` |
| `GET /v1/nutrition/week?date=&metric=kcal\|protein` 🔐 | `{metric, weekStart, goal, days:[{date, value, progress, isToday, isFuture}]}` (Pzt–Paz) |

## 12. Açlık check-in — `hunger`

| Uç | Açıklama |
|---|---|
| `POST /v1/hunger-checkins/evaluate` 🔐 | Durumsuz skorlama (sonuç ekranı): `{symptoms[], q1, q2, bodyNotices[], q4}` → `{resultType, physicalScore, emotionalScore, safetyFlag, scoringVersion, activeFastId, recommendations:[{code, title}]}`. Aktif oruç bağlamı sunucuda eklenir |
| `POST /v1/hunger-checkins` 🔐 | Kaydet: aynı cevaplar + `{id?, mode:"quick\|full\|hungryNow", loggedAt?, notes?}`. Yanıt (201) `{checkin, …evaluate yanıtı}`. Sonuç sunucuda **yeniden hesaplanır**: istemci `resultType`/`physicalScore`/`emotionalScore`/`safetyFlag` gönderirse kabul edilir ama **yok sayılır** |
| `GET /v1/hunger-checkins?date=&type=all\|physical\|emotional&cursor=` 🔐 | Geçmiş |
| `GET /v1/hunger-checkins/summary?date=` 🔐 | `{today:{date, total, physical, emotional}, week:[{date, physical, emotional, fastedMinutes}]}` |
| `DELETE /v1/hunger-checkins/:id` 🔐 | |

- `recommendations[].title` `Accept-Language`'e göre katalogdan gelir (`catalog_labels`, ad alanı `hunger_rec`). Güvenlik bayrağında ilk öneri `safety_end_fast`'tir ve `activeFastId` "Orucu bitir" kısayolu için döner.
- Check-in başına 2 XP, günde en fazla 3.

## 13. Mochi World & oyunlaştırma — `world`, `challenges`

### `GET /v1/world` 🔐

```jsonc
{ "level": 4, "xp": 380,            // hesap seviyesi (XP)
  "sceneLevel": 2,                  // bölgelerin max'ı (görsel)
  "health": "thriving",             // thriving|wilting|drought
  "worldProgress": 0.42,
  "zones": [
    { "zone": "forest", "metric": "completedFasts", "unit": "fasts",
      "current": 12, "level": 2, "nextThreshold": 25, "ratioToNext": 0.133,
      "thresholds": [3, 10, 25, 50] },
    { "zone": "lake",   "metric": "waterGoalDays", "unit": "days",  "current": 9,   "level": 2, … },
    { "zone": "summit", "metric": "weightLostKg",  "unit": "kg",    "current": 3.4, "level": 2, … },
    { "zone": "garden", "metric": "mealsLogged",   "unit": "meals", "current": 18,  "level": 2, … } ],
  "week": [ { "date": "2026-10-05", "fastedMinutes": 970, "kept": true }, … ] }
```

- `level` ulaşılan en yüksek seviyedir (ada geri gitmez); `current` güncel metriktir. İstemci kendi `round(oran·4)` hesabını bırakır, `level`'ı kullanır. Bölge kartı `current / nextThreshold` gösterir.
- Seri/sağlık gün döndüyse okumada yenilenir. Cache'siz (birkaç hafif sorgu).
- Seviye atlamaları ve sağlık `POST /fasts/:id/finish` yanıtındaki `world` alanında döner; bildirimler F9'da.

### Challenge uçları

| Uç | Açıklama |
|---|---|
| `GET /v1/challenges` 🔐 | `{items:[{code, title, subtitle, badge, description, metric, targetCount, durationDays, windowType, startsAt, endsAt, rewardXp, isPremium, isFeatured, participantsCount, participantAvatars:[], my:{id, status:"active\|completed\|failed\|left", progress, target, windowStart, windowEnd, completedAt} \| null}]}` (dile göre) |
| `GET /v1/challenges/featured` 🔐 | `{challenge}` — öne çıkan (yoksa ilk). `/user/summary` → `featuredChallenge` aynı nesne |
| `POST /v1/challenges/:code/join` 🔐 | `{challenge}`. Rolling pencere şimdi başlar (`durationDays`). Aktif katılım varsa 409 (`already_joined`); premium challenge → 402; sabit pencere açık değilse 409 (`challenge_not_open`). Tamamlanan challenge'a yeniden katılınabilir (yeni pencere) |
| `POST /v1/challenges/:code/leave` 🔐 | `{challenge}` (`my.status: "left"`); aktif katılım yoksa 404 |

- İlerleme her ilgili yazmada (öğün, oruç, su, açlık check-in'i) pencere içinde **yeniden sayılır** (silinen kayıt düşer). Hedefe ulaşınca `completed` + `rewardXp` XP (bir kez).
- Süresi dolan aktif katılım saatlik işle `failed` olur.
- `participantsCount`: aktif ya da tamamlamış **gerçek** katılımcı sayısı. `participantAvatars` izin ayarı olmadığı için boş; istemci jenerik maskot gösterir.

## 14. Coach Mochi sohbeti — `chat` (ayrıntı: [09](09-yapay-zeka.md); model: **OpenAI**)

| Uç | Açıklama |
|---|---|
| `GET /v1/chat/suggestions?context=` 🔐 | `{items:[{code, text}]}` (dile göre). `context` kabul edilir; bağlama göre süzme henüz yok |
| `GET /v1/chat/quota` 🔐 | §17b |
| `GET /v1/chat/conversations?cursor=&limit=` 🔐 | İlk sayfada önce sabitlenenler, sonra son mesaja göre azalan: `{items:[{id, title, isPinned, messageCount, contextSource, lastMessageAt, createdAt}], pageInfo}` |
| `POST /v1/chat/conversations` 🔐 | `{contextSource?: "direct\|hungerResult\|fastingStruggle\|suggestion", contextRef?}` → 201 `{conversation}`. `hungerResult` + check-in id'si → bağlamda `entry_point: hunger_result(physical)` |
| `GET /v1/chat/conversations/:id/messages?cursor=&limit=50` 🔐 | Eskiden yeniye: `{items:[{id, role, text, status, safety, feedback, createdAt}], pageInfo}`; imleç daha eski mesajları getirir |
| `POST /v1/chat/conversations/:id/messages` 🔐 | **SSE akışı** (aşağıda). Gövde `{id?, text (1–2000)}`. Günlük kota (ücretsiz 3) |
| `PATCH /v1/chat/conversations/:id` 🔐 | `{isPinned?, title?}` |
| `DELETE /v1/chat/conversations/:id` 🔐 | Yumuşak silme |
| `POST /v1/chat/messages/:id/feedback` 🔐 | `{rating:"up\|down", reason?}` (yalnızca kendi asistan mesajları) |

**SSE sözleşmesi** (`Accept: text/event-stream`):

```
POST /v1/chat/conversations/:id/messages
{ "id": "<client uuid>", "text": "Kahve içebilir miyim?" }

event: message.created
data: {"userMessageId":"…","assistantMessageId":"…","safety":"none"}

event: delta
data: {"text":"Evet squish! Sade kahve"}

event: delta
data: {"text":" orucu bozmaz ☕"}

event: message.completed
data: {"assistantMessageId":"…","status":"complete","safety":"none","usage":{"remainingToday":2}}

event: error
data: {"code":"UNAVAILABLE","reason":"first_token_timeout|total_timeout|provider_error","assistantMessageId":"…"}
```

- Akış açılmadan önceki hatalar **normal JSON** döner: 403 `CONSENT_REQUIRED` (`aiProcessing`), 404, 409 `REPLY_IN_PROGRESS` (aynı konuşmada eşzamanlı ikinci istek), 429 `QUOTA_EXCEEDED` (`details: {kind:"chat", limit, used, resetAt, upgradeAvailable}`), 503 `UNAVAILABLE` (`chat_disabled`, `chat_circuit_open`, `ai_budget`).
- `safety: "urgent"`: kullanıcı mesajında tehlike belirtisi (bayılma, göğüs ağrısı, şiddetli baş dönmesi…; 7 dil). İstemci yanıtın altına "Acil durum" kartı ekler.
- `status`: `complete` | `refused` (yerelleştirilmiş ret metni `delta` olarak gelir) | `interrupted` (istemci ayrıldı; o ana kadarki metin saklanır, tamamlanma olayı gönderilmez) | `failed` (`error` olayı; kota iade edilir).
- Kalp atışı (heartbeat): her 15 sn'de `: ping`.
- Aynı `id` ile tekrar gönderim: yeni yanıt üretilmez; `message.created` (`replay: true`) + kayıtlı yanıt tek `delta` olarak döner.
- `Accept: application/json`: akışsız tam yanıt `{userMessageId, assistantMessage, remainingToday}` (yedek yol).
- Nginx bu yolda tamponlamayı kapatır (`deploy/nginx`); yanıt `X-Accel-Buffering: no` da gönderir.

## 15. Öğren (Insights) — `insights`

| Uç | Açıklama |
|---|---|
| `GET /v1/insights/categories` 🔓 | `[{slug, title, description, iconKey, bgColor, isPremium, articleCount}]` |
| `GET /v1/insights/articles?category=&q=&cursor=` 🔓 | `q` sunucu tarafında FULLTEXT ile, tüm içerikte aranır |
| `GET /v1/insights/articles/:slug` 🔓 (💎 premium içerikte) | `{slug, kicker, title, subtitle, quote, quoteAuthor, sections:[{iconKey, title, body}], tip, coverUrl, isRead, isBookmarked}` |
| `POST /v1/insights/articles/:slug/read` 🔐 | |
| `PUT /v1/insights/articles/:slug/bookmark` 🔐, `DELETE …/bookmark` 🔐 | |
| `GET /v1/insights/bookmarks` 🔐 | |

## 16. Bildirimler — `notifications` (ayrıntı: [10](10-bildirimler.md))

| Uç | Açıklama |
|---|---|
| `GET /v1/notifications?cursor=&limit=` 🔐 | `{items:[{id, type, category, title, body, params, iconKey, deepLink, createdAt, readAt}], pageInfo}` (yeniden eskiye). `title`/`body` okuma anında render edilir: `Accept-Language` varsa o dil, yoksa kullanıcının kayıtlı dili; sayılar dile göre (`72,4 kg`). `params` istemcide vurgulama için |
| `GET /v1/notifications/unread-count` 🔐 | `{count}` |
| `POST /v1/notifications/:id/read` 🔐 | Okundu; başkasının kaydı 404 |
| `POST /v1/notifications/read-all` 🔐 | `{updated}` |
| `DELETE /v1/notifications/:id` 🔐 | Kaydırarak silme (yumuşak) |

- Push token'ı ve izin: `PUT /v1/devices/current {pushToken, pushEnabled}` (§3). Kategori anahtarları ve sessiz saatler: `PATCH /v1/user/settings` (`notifications.world` eklendi).
- Push veri alanları: `{type, deepLink, notificationId}`; push metinleri sağlık değeri içermez.

## 17. Abonelik — `subscription` (RevenueCat; ayrıntı: [11](11-abonelik.md))

**Paywall istemcidedir** (RevenueCat Paywalls, `purchases_ui_flutter`); sunucuda paywall/ürün listesi ucu yoktur. Sunucu yalnızca abonelik durumunu RevenueCat'ten yansıtır ve yetki kararını verir.

| Uç | Açıklama |
|---|---|
| `GET /v1/subscription` 🔐 | `{subscription:{isPremium, entitlement, status, productId, store, environment, periodType, willRenew, expiresAt, graceExpiresAt, managementUrl}}`. `status`: `active\|billing_issue\|in_grace\|expired\|refunded` ya da `null` (hiç abonelik yok) |
| `POST /v1/subscription/sync` 🔐 | Satın alma / geri yükleme sonrası. Sunucu RevenueCat REST'ten çeker, yazar, önbelleği temizler; yanıt `GET` ile aynı. Saatte 20 |
| `POST /v1/webhooks/revenuecat` | Oturumsuz; `Authorization` başlığı `REVENUECAT_WEBHOOK_AUTH` ile birebir aynı olmalı (yoksa 401; ayar yoksa 503). `{received, duplicate}`; işleme asenkron (`billing` kuyruğu) |

- `isPremium` her yerde aynı kaynaktan: `/user/me`, giriş yanıtları, plan kilidi (402), katalog/insights kilitleri, AI kotaları (premium limitleri), premium challenge'lar.
- Webhook'u worker işlediği için API'deki premium önbelleği en geç 30 sn eski kalabilir; istemci satın alma sonrası `sync` çağırır (anında).
- RevenueCat `app_user_id` = bizim kullanıcı UUID'miz (`Purchases.logIn(userId)`).

## 17b. AI kotası

### `GET /v1/chat/quota` 🔐

```jsonc
{ "chat": { "used": 1, "limit": 3, "remaining": 2, "resetAt": "2026-10-07T21:00:00.000Z" },
  "photoAnalysis": { "used": 0, "limit": 2, "remaining": 2, "resetAt": "…" },
  "isPremium": false }
```

Limitler `app_config.limits`'ten; `resetAt` kullanıcının yerel gece yarısıdır.

## 18. Medya — `media`

| Uç | Açıklama |
|---|---|
| `POST /v1/media?purpose=mealPhoto` 🔐 | `multipart` (alan `file`) → 201 `{media}`. Aynı içerik 24 sa içinde tekrar gelirse 200 ve mevcut kayıt. Öğüne `POST/PATCH /v1/meals {photoMediaId}` ile bağlanır |
| `GET /v1/media/:id` 🔐 | `{media}`: süresi dolan imzalı URL'leri yenilemek için. Yalnızca sahibine (başkasına 404) |
| `DELETE /v1/media/:id` 🔐 | Dosyalar silinir; öğün/avatar bağlantısı kalkar |

**Medya biçimi** (yanıtlara gömülü, ör. `meal.photo`, `avatar`):

```jsonc
{ "id": "…",
  "url": "https://<private-pull-zone>/u/<ownerKey>/meals/2026/10/<id>_1024.webp?token=…&expires=…",
  "thumbUrl": "…_256.webp?token=…",
  "variants": { "lg": "…", "md": "…", "thumb": "…" },
  "width": 1024, "height": 768, "blurhash": "LKO2?U%2Tw=w]~RBVZRi};RPxuwH",
  "expiresAt": "2026-10-07T18:00:00.000Z" }
```

- URL'ler **imzalıdır** (Bunny Token Authentication) ve saat başına yuvarlanmış süreyle (varsayılan ≥ 6 sa) döner. Ayrı bir "URL ver" ucu yoktur; süre dolunca kaynak yeniden çekilir (403 → yenile).
- İstemci görsel cache anahtarı: **`${id}_${variant}`** (token değişse de aynı görsel tekrar inmez).
- Geliştirmede (`MEDIA_DRIVER=local`) URL'ler API'nin `/media-files/*` ucuna gider; doğrulama Bunny edge'iyle aynıdır.

## 19. Yönetim — `admin` 🛡️ (faz 10)

**Kimlik doğrulama** ([06 §12](06-guvenlik.md#12-yönetim-paneli-güvenliği)):
- `POST /v1/admin/auth/login {email, password, totp}` → `{token, expiresIn: 3600, admin: {…, mustChangePassword}}`. JWT `aud=mochifast-admin`, yenileme yok. TOTP zorunlu; aynı kod ikinci kez kabul edilmez. 5 hatalı denemede 15 dk kilit (kilitliyken de genel `401` döner).
- `GET /v1/admin/auth/me`; `POST /v1/admin/auth/password {currentPassword, newPassword ≥ 12}` → yeni `{token}` (eski token'lar iptal); `POST /v1/admin/auth/logout` (bu yöneticinin tüm token'ları iptal).
- Geçici şifreyle (oluşturma/sıfırlama sonrası) girişte yalnızca bu üç uç açıktır; diğerleri `403 password_change_required`.
- Her uç `ADMIN_IP_ALLOWLIST`'ten geçer. Üretimde liste boşsa admin API kapalıdır (`403 admin_disabled`), bilinçli açmak için `ADMIN_ALLOW_ANY_IP=true`. İlk owner: `npm run admin:create -- <email> owner`.

**Roller:** `owner` (her şey), `editor` (içerik, yapılandırma, medya), `support` (kullanıcı arama/işlem), `analyst` (raporlar). Rol dışı uç `403`.

| Uç | İzin | Açıklama |
|---|---|---|
| `GET/POST /admin/admins`, `PATCH /admin/admins/:id`, `POST /admin/admins/:id/reset-credentials` | owner | Yönetici ekle (geçici şifre + `totp.otpauthUrl` yalnızca bu yanıtta), rol/aktiflik, şifre+TOTP sıfırlama |
| `GET /admin/catalog` | editor | Bölümler: `content` (evreler, struggle, insights, FAQ, öneriler), `gamification` (challenge'lar), `notifications` (şablonlar), `plans`, `labels`; güncel sürüm |
| `GET /admin/catalog/:section` | editor | Seed biçiminde doküman (tüm çeviriler) + `version` |
| `PUT /admin/catalog/:section {document, baseVersion, note?}` | editor | Bölümü kaydeder: tek transaction, seed ile aynı yazıcı; `baseVersion` güncel değilse `409 stale_version`; bozuk doküman `400` (hiçbir şey değişmez). `catalog.version` artar. Panelde kaydedilen bölümü `npm run seed` artık ezmez |
| `GET /admin/catalog/:section/versions[/:version]`, `POST /admin/catalog/:section/rollback {version}` | editor | Sürüm geçmişi (son 30) ve geri alma |
| `GET /admin/config`, `PUT /admin/config/:key {platform?, value}`, `DELETE /admin/config/:key?platform=` | editor | `app_config`; `catalog.version` korunur |
| `POST /admin/media?purpose=insightCover\|challengeImage\|planImage` | editor | Public zone, kalıcı URL (`p/<purpose>/…`) |
| `POST /admin/users/search {q}` | support | Kimlik (UUID) ya da **tam** e-posta; ad/e-posta maskeli (`a***@g***.com`). POST: e-posta URL'de/loglarda görünmez |
| `GET /admin/users/:id` | support | Durum, cihazlar, oturum sayısı, abonelik, silme talebi, rızalar, seviye/seri. Sağlık verisi yok |
| `POST /admin/users/:id/sessions/revoke {reason}` | support | Tüm oturumları sonlandırır |
| `POST /admin/users/:id/premium {duration, reason}` | support | RevenueCat promosyon premium + senkron |
| `POST /admin/users/:id/deletion {reason}` | support | E-postayla gelen silme talebi: uygulamadaki silmeyle aynı (7 gün, geri alınabilir) |
| `POST /admin/users/:id/deletion/expedite {reason}` | support | Bekleyen silme talebini şimdiye çeker (≤ 1 sa) |
| `GET /admin/reports/overview?days=30` | analyst | UTC günlük: kayıt (misafir/kayıtlı), DAU (`user_activity_daily`), oruç başlatma/tamamlama, AI maliyeti, yeni abonelik; toplamlar: DAU/WAU/MAU, premium, ödeyen; aralıktaki hesapların hunisi (oluşan → onboarding → kayıt → abone) |

Tüm yönetici işlemleri (arama ve görüntüleme dahil) `audit_logs`'a yazılır (`actor_type = admin`).

**Web hesap silme (Play Store):** `GET /account/delete` — sade bilgi sayfası (HTML, tr/en, script yok): uygulamadan silme adımları ve destek e-postası. Uygulamaya erişemeyen kullanıcı e-postayla talep eder; destek `POST /admin/users/:id/deletion {reason}` ile uygulamadakiyle aynı talebi oluşturur. Firebase web uygulaması bilinçli olarak kullanılmaz.

## 20. Operasyon

| Uç | Erişim |
|---|---|
| `GET /health/live`, `GET /health/ready` | Deploy kontrolü ve dış izleme |
| `GET /metrics` | Yalnızca iç ağ |
| `GET /docs` | Dev/staging, basic auth |

## Eski (prefix'siz) yollar

Kaldırıldı (F11, lansman öncesi): `/auth/register`, `/user/me`, `/user/progress`, `PATCH /user/onboarding` artık 404. İstemci yalnızca `/v1` kullanır.
