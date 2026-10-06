# 01 — Uygulama Analizi

Bu belge, Flutter kod tabanının (352 Dart dosyası, 76 rota, 7 dil dosyası) backend açısından
envanteridir. Her bölümde: **ekranda ne var → bugün nereden geliyor → backend'in ne sağlaması gerekiyor.**

## 1. Genel resim

| Katman | Durum |
|---|---|
| Mimari | BLoC/Cubit + `go_router` (StatefulShellRoute; 5 sekme: Ana sayfa, Oruç, Mochi World, Planlar, Profil) + `get_it`/`injectable` DI |
| Ağ | Dio, `BaseUrl = https://api.example.com` (yer tutucu), 15 sn timeout, interceptor zinciri: Language → Auth → ExpiredToken → Log |
| Modeller | `User`, `UserProgress`, `Token`, `AuthResponse`, `AuthRegisterRequest`, `SummaryResponse` (kullanılmıyor), `NoContent`, `RawData` |
| Repository'ler | `AuthRepository`, `UserRepository`, `ProgressRepository` dolu; `NotificationsRepository`, `ProductRepository` boş iskelet; `RevenueCatService` TODO |
| Yerel depolama | Secure storage: `access_token`, `refresh_token`, `user_json`. SharedPreferences: `first_launch`. HomeWidget app group: `group.com.flywork.mochifast` |
| Diller | Dosyalar: en, tr, de, es, fr, it, ru. `supportedLocales` yalnızca en, tr, de, fr, es (**it ve ru eksik**). Dil seçim ekranında 11 dil listeleniyor (pt, ko, hi, ja dahil, dosyası yok) |
| Ödeme | `purchases_flutter` / `purchases_ui_flutter` kurulu, hiç çağrılmıyor |
| Sağlık entegrasyonu | Yok (HealthKit/Google Fit paketi yok). Profilde yalnızca bir anahtar (toggle) var |

### 1.1 Mevcut API sözleşmesi (korunacak)

```
Yanıt zarfı:  { "status": String?, "message": String?, "data": { ... } }
JSON:         camelCase (json_serializable varsayılanı)
Header:       Authorization: Bearer <accessToken>, Accept-Language: <dil kodu>
```

| Endpoint | İstek | Yanıt `data` |
|---|---|---|
| `POST /auth/register` | `{provider: "google"\|"apple"\|"guest", idToken, deviceId}` | `{token:{accessToken, refreshToken}, user:User}` |
| `GET /user/me` | – | `{id, name, email, isPremium, isAnsweredQuestions}` |
| `PATCH /user/onboarding` | `{level:int}` (eski "LanguageLevel" kalıntısı) | `User` |
| `GET /user/progress` | – | `{level, streakDays, completedFasts}` |

> ⚠️ **Kritik uyumluluk notu:** `BaseResponse.fromJson`, `data` alanını **yalnızca JSON nesnesiyse** parse
> ediyor. `data` bir dizi olursa `null` dönüyor. Bu yüzden tüm liste endpoint'leri
> `data: { items: [...], pageInfo: {...} }` biçiminde dönmeli. Ayrıntı: [04-api.md](04-api.md#yanıt-zarfı).

## 2. Modül modül envanter

### 2.1 Kimlik doğrulama & Onboarding (`presentation/auth/**`)

**Akış:** Splash → Entry → [Get Started → 22 onboarding ekranı → Login] veya [I already have an account → Login].

**Giriş yöntemleri:** `AuthProviderType { google, apple, guest }`.

- E-posta/şifre, OTP ve telefon girişi yok.
- `google_sign_in` ve `sign_in_with_apple` paketleri yok; bütün girişler `_fakeLogin()` (900 ms bekleyip `/home`'a gidiyor).
- `DeviceManager.getDeviceId()` sabit olarak `'unknown-device-id'` döndürüyor.

**Onboarding'de toplanan veriler.** Hiçbiri saklanmıyor. Hepsi backend'e taşınmalı.

| Adım | Alan | Tip / değerler | Kısıtlar |
|---|---|---|---|
| Goal | `goal` | `loseWeight, buildHabit, moreEnergy, gutReset` | Tek seçim |
| About You | `gender` | `woman, man, nonBinary, preferNotToSay` | Tek seçim |
| Starting Point | `weightKg` | double | 30–300, 0.5 adım |
| | `goalWeightKg` | double | 30 – mevcut kilo |
| | `heightCm` | int | 100–250 |
| | `age` | int | 13–100. Doğum tarihi yok |
| Diet | `diet` | `everything, vegetarian, pescatarian, vegan, lowCarb, mediterranean` | Tek seçim, zorunlu |
| Food Loves | `foodLoves[]` | `chicken, fish, rice, redMeat, pasta, salads, cheese, eggs, spicy, noodles, fruit, avocado, sweets` | Çoklu, ≥1 |
| Food Skips | `foodSkips[]` | `mushrooms, olives, seafood, onions, broccoli, tooSpicy, dairy, nuts, beans, eggplant` | Çoklu, opsiyonel |
| Weight History | `weightHistory` | `manyTimes, onceOrTwice, firstTime` | Tek seçim |
| Obstacles | `obstacles[]` | `tooRestrictive, lostMotivation, noTimeToCook, tooConfusing, lifeGotBusy, hitPlateau` | Kodda tek seçim, metin "hepsini seç" diyor → **çoklu modellenmeli** |
| Fasting Reason | `fastingReason` | `specialDate(45 gün), trip(90), healthLongevity(180), confidence(120)` | `targetDate = bugün + N`, kullanıcı değiştiremiyor |
| Fasting Plan | `fastingPlan` | `16:8, 14:10, 18:6, 20:4 (enum adı yanlışlıkla twentyFour), OMAD, 5:2` | Tek seçim |
| Meal Window | `mealWindowStart/End` | HH:mm (varsayılan 07:00–19:00) | Doğrulama yok: bitiş başlangıçtan önce olabiliyor |

**Yalnızca gösterim yapan ekranlar** (değerler sabit kodlanmış):

- **BuildingPlan:** "Woman, 74 kg, 172 cm…" çipleri.
- **WeightProjection:** 74→68 kg, haftada 0.4 kg.
- **GoodCompany:** "12d avg streak, 2M+ squishes, 4.8 rating".

**Sahte oturum.** `GoodCompanyViewMixin` sonunda şunları yazıyor:
- `Token(accessToken: 'local-onboarding-session')`
- `User(name:'Squish')`

Backend bunu 401 ile reddetmeli. Doğrusu, onboarding başında gerçek bir **misafir oturumu** açmaktır ([13](13-flutter-entegrasyonu.md)).

**Backend ihtiyacı:**
- Misafir hesap
- Apple/Google token doğrulama
- Misafir → sosyal hesap bağlama
- Tek seferde onboarding gönderimi
- Profil tabloları
- Rıza (consent) kaydı

### 2.2 Profil (`presentation/profile/**`)

- **Başlık:** "Atilla E.", streak 3, `isPremium:true`. Hepsi sabit.
- **Düzenlenebilir alanlar** (hepsi yerel mock):
  - fotoğraf (image_picker; 1024 px, kalite 85)
  - görünen ad
  - oruç hedefi (goal), kilo, boy, yaş, cinsiyet, diyet tipi
  - sevilen/atlanan yiyecekler
  - oruç planı
- **Profilden düzenlenemeyenler:** hedef kilo, öğün penceresi, sebep, engeller, e-posta.
- **Anahtarlar:** Push Notifications ("Fasting reminders & streak nudges") ve Health Sync. İkisi de yerel.
- **Birimler:** Kilo diyaloğunda kg/lb var ama saklanmıyor. Su ekranında ml/oz var. Global bir birim ayarı yok.
- **Bildirim kutusu:** `NotificationKind { weight, meal }` ve 2 mock kayıt. Kaydırarak silme var.
- **Eksikler:** hesap silme (**App Store zorunluluğu**), abonelik yönetimi, gizlilik/şartlar linkleri, veri dışa aktarma.
- **Boş handler'lar:** Rate App, Share App, Fasting History, Get Premium.

### 2.3 Oruç (`presentation/fasting/**`)

**Durum makinesi yok.**
- `_mealSelected` (yeme/oruç) ve `_finishReady` booleanları var.
- `_started` yalnızca başlangıç zamanı seçicisinden geliyor.
- Varsayılan değerler: 01:44:14 geçen süre, %10, streak 3.

**Başlangıç zamanı düzenleme:** tarih, saat ve dakika. Aralık bugün −30 gün ile +14 gün arası.

**Bitiş ekranı** (`FastingFinishView`). Kaydedilmeli ama hiçbir şey kaydedilmiyor:
- `start` ve `end` düzenlenebilir.
- Geçen süre (flip clock)
- Güncel kilo kartı (102.5 / 112.2 / 75.2 sabit), kilo düzenleme
- Ruh hâli: `tough, meh, good, super`
- Serbest not

**İlk oruç kutlaması:** Her seferinde gösteriliyor. Backend `isFirstFast` bayrağı dönmeli.

**Vücut evreleri** (9 evre, saat eşikleri):

| # | Aralık | Başlık |
|---|---|---|
| 1 | 0–2 sa | Blood Sugar Rises |
| 2 | 2–5 sa | Blood Sugar Drops |
| 3 | 5–8 sa | Blood Sugar Stabilizes |
| 4 | 8–12 sa | Entering Fasting Mode |
| 5 | 12–16 sa | Fat Burning Begins |
| 6 | 16–18 sa | You're in Ketosis |
| 7 | 18–24 sa | Fat-Burning Mode Deepens |
| 8 | 24–48 sa | Autophagy Begins |
| 9 | 48+ sa | Mental Clarity |

Bugün seçili evre elle dokunmayla değişiyor. Backend geçen süreden hesaplamalı.

**Yeme penceresi evreleri:** Break / Nourish / Next (3 adım).

**Zorlanma akışı** (`FastingStruggleReason`):

| Sebep | Önerilen ipuçları |
|---|---|
| hungry | hydration, walk |
| craving | breathe |
| energy | walk |
| stressed | hydration, breathe |
| bored | hydration, walk, breathe |

Aktivite parametreleri:
- Yudum: 8 dokunuş
- Yürüyüş: 180 sn
- Nefes 4-7-8: 4 tur

Hiçbiri loglanmıyor.

**Tamamen sahte kartlar:**
- **Fast Forecast:** %87 güven, 14:00 açlık zirvesi, risk 13:30–14:30, 7 noktalı eğri.
- **"Mochi's Plan for Today":** Kişiselleştirilmesi gereken sabit metin.

**Backend ihtiyacı:**
- `fasting_sessions` (durum makinesi)
- plan anlık görüntüsü (snapshot)
- düzenleme kuralları
- istatistik ve seri hesabı
- vücut evresi kataloğu
- zorlanma olay logu
- (sonraki faz) tahmin modeli

### 2.4 Planlar (`presentation/plans/**`) — üç ayrı, tutarsız katalog

| Kaynak | İçerik |
|---|---|
| `plans_catalog.dart` (Planlar sekmesi) | 6 başlangıç (16-8/15-9/14-10 × kahvaltı/akşam atla) + 6 ileri (19-5, 20-4, OMAD, 18-6…). İleri olanların hepsi `isLocked` (premium) |
| `fasting_plan_options_catalog.dart` (onboarding/profil) | 16:8, 14:10, 18:6, 20:4, OMAD, 5:2 (POPULAR/BEGINNER FRIENDLY/… rozetleri) |
| `assets/MochiFast_Genisletilmis_Aralikli_Oruc_Planlari.docx` (**ürün kaynağı**) | 22 plan, aşağıda |

**Ürün dokümanındaki 22 plan.** Backend'in tek doğru kaynağı (source of truth) bu olmalı:

| Kategori | Plan | Oruç | Yeme | Kart etiketi | Kısa açıklama |
|---|---|---|---|---|---|
| Beginner | 12:12 | 12 sa | 12 sa | Easy Start | The easiest way to start fasting |
| Beginner | 13:11 | 13 | 11 | Gentle Start | Ease into a longer fasting window |
| Beginner | 14:10 | 14 | 10 | Habit Builder | Build a simple daily fasting habit |
| Beginner | 15:9 | 15 | 9 | Balanced Start | A gentle step toward classic fasting |
| Popular | 16:8 | 16 | 8 | Most Popular | The classic intermittent fasting schedule |
| Intermediate | 17:7 | 17 | 7 | Step Up | Extend your fasting window gradually |
| Intermediate | 18:6 | 18 | 6 | Daily Challenge | A longer daily fasting routine |
| Intermediate | 19:5 | 19 | 5 | Narrow Window | A more focused eating window |
| Advanced | 20:4 | 20 | 4 | Warrior Style | A short daily eating window |
| Advanced | 21:3 | 21 | 3 | Advanced Fast | A very narrow daily eating window |
| Advanced | 22:2 | 22 | 2 | Expert Window | Designed for experienced fasters |
| Advanced | 23:1 | 23 | 1 | One-Hour Window | A highly restrictive daily schedule |
| Advanced | OMAD | ~23 | 1 öğün | One Meal a Day | One main meal within the day |
| Weekly | 5:2 | 5 normal gün | 2 azaltılmış gün | Weekly 5:2 | A weekly approach instead of a daily timer |
| Weekly | 6:1 | 6 normal | 1 azaltılmış | Weekly 6:1 | One fasting-focused day each week |
| Weekly | Alternate-Day | Gün aşırı | – | Alternate-Day Fasting | Alternate fasting and regular eating days |
| Flexible | Crescendo | Seçili günler | – | Crescendo Fasting | Fast on selected non-consecutive days |
| Flexible | Early TRE | Özel | Erken pencere | Early Eating | Finish your eating window earlier in the day |
| Flexible | Late TRE | Özel | Geç pencere | Late Eating | Use a later eating window that fits your routine |
| Flexible | Custom Daily | Özel | Özel | Create Your Plan | Choose your own fasting and eating hours |
| Flexible | Custom Weekly | Özel günler | Özel | Build Your Week | Choose different fasting schedules by day |

Dokümana göre **gruplama:** Beginner Level (12:12–15:9), Popular (16:8, 18:6), Intermediate (17:7–19:5), Advanced (20:4–OMAD), Weekly (5:2, 6:1, ADF, Crescendo), Flexible (Early, Late, Custom Daily, Custom Weekly).

**Zamanlama tercihi** (12:12–23:1 için plan kartını çoğaltmak yerine detayda seçiliyor):
- Skip Breakfast
- Skip Dinner
- Early Eating Window
- Late Eating Window
- Choose My Hours

**Ürün kuralları** (backend'de zorunlu olarak uygulanacak):
- 16:8 "Most Popular" olarak öne çıkar.
- Custom Daily/Weekly mutlaka bulunur.
- 20:4, 21:3, 22:2, 23:1 ve OMAD "Advanced" altında kalır.
- ≥24 saat açlık "daha zor = daha iyi" ilerleme sistemi içinde **teşvik edilmez**.
- Hamilelik/emzirme, yeme bozukluğu öyküsü, diyabet ve ilaç kullanımı için **güvenlik mesajları** gösterilir ([05 §2.6](05-is-kurallari.md#26-sağlık-güvenliği-kuralları)).

**Plan detay ekranı:** "Change" ile yeme penceresinin saatleri değiştiriliyor. Haftalık çubuklar 7 günün hepsinde aynı (5:2 desteği yok).

**Seçim kaybı:** "Start this plan" yalnızca kartı döndürüyor, özel saatler kayboluyor. Planlar sekmesindeki seçim Oruç sekmesiyle paylaşılmıyor.

### 2.5 Ana sayfa (`presentation/home/**`)

`HomeBloc` → `/user/me` + `/user/progress`. Hata durumunda `Squish`, streak 3 gösteriyor.

| Kart | Bugünkü değer | Backend kaynağı |
|---|---|---|
| Üst bar | streak (0 ise 3 gösteriyor), Get Premium | `user_stats.current_streak`, entitlement |
| Hafta şeridi | Yalnızca bugün "10h" | `daily_summaries.fasted_minutes` (Pzt–Paz) |
| Oruç kartı | 6:12:39 geri sayım | aktif seans |
| Su / Adım | 600/2500 ml, 1000/8000 | günlük özet + hedefler |
| Kilo | 102.5 / 112.2 / 75.2 | kilo kayıtları + profil |
| Metabolic Twin | Enerji 0.72, Hidrasyon 0.45, Oruca Hazır 0.88 | türetilmiş skor (faz 7+) |
| Öğün kaydı | "July 1, 12:53", Full Meal / Ketogenic | son öğün |
| Challenge | "1 Week of fasting challenge", 8954 katılımcı, Join no-op | challenges |

### 2.6 Takipçiler (tracker'lar)

| Modül | Mevcut | Backend modeli |
|---|---|---|
| **Su** | Tek kalıcı modül (yalnızca widget storage'ında). Bardak boyları [50,100,200,300,500] + özel. Son 3 yudum tutuluyor, geri al. ml/oz (29.5735). Hedef varsayılanı 2500, hatırlatıcı ekranında 2000 (tutarsız). **Gece yarısı sıfırlanmıyor (hata)** | `water_entries`, hedef snapshot'lı günlük toplam, hatırlatıcı ayarı |
| **Adım** | Tamamen mock. Haftalık [4200…1000]. Türetme: kcal = 0.04·adım, km = 0.0007·adım, dk = 0.01·adım | `step_daily` (manuel + HealthKit/Fit senkron) |
| **Uyku** | Tamamen mock (7s30d, 23:00–06:30, hedef 7.5 sa) | `sleep_entries`, yatış/kalkış hedefi |
| **Kalori** | Mock: 3143 yenen, 273 fazla, makrolar. Kamera fotoğraf çekiyor ama analiz/kayıt yok. "Sonuç" ekranındaki "Grilled Chicken 550 kcal" çeviri dosyasından geliyor | `meals` + `food_photo_analyses` + beslenme hedefleri |
| **Protein** | Mock 75/120 g, 3 sabit öğün, haftalık çubuklar | `meals` makroları + hedef |
| **Öğün kaydı** | `MealKind {meal, snack}`, `MealDietChoice {ketogenic, lowCarb, mixed, highCarb, notSure}`, `MealFeeling {meh, good, super}`, not. Kaydetme yalnızca `pop()` | `meals` (kalori modülüyle **tek tablo**) |
| **Açlık** | Belirtiler `{sleeplessness, headache, dizziness, nausea, fatigue, weakness}`. 4 soru: Q1 `{yes, notReally, notSure}`, Q2 `{gradually, suddenly, notSure}`, Q3 çoklu beden bulgusu, Q4 `{almostAnything, somethingSweet, fastFood, notSure}`. **Sonuç `Random().nextBool()`!** | `hunger_checkins` + sunucu tarafında skorlama ([05 §5](05-is-kurallari.md#5-açlık-check-in-skorlaması)) |
| **Kilo** | 102.5 kg mock, hedef 74.2 (ana sayfada 75.2, tutarsız). BMI eşikleri <18.5 / <25 / üstü. Grafik Y ekseni 65–120 kg sabit. Ay harfleri Türkçe sabit kodlanmış | `weight_entries`, gün/hafta/ay grafik kovaları |

### 2.7 Coach Mochi sohbeti (`presentation/chat/**`)

- **Modeller:** `ChatMessage {id, text, sender: user|ai}` (zaman damgası yok) ve `ChatHistoryItem {id, title, messageCount, date, isPinned}`.
- **Yanıtlar:** Anahtar kelime eşleşmeli hazır metinler. Persona: sıcak, kullanıcıya "squish" diyor, emoji kullanıyor.
- **Davranış:**
  - Tek bir aktif sohbet var.
  - Sabitlenebiliyor (pin) ve silinebiliyor.
  - Geçmiş sohbet tekrar açılamıyor.
  - Aynı anda tek istek gönderilebiliyor.
- **Önerilen sorular:** 4 adet.
- **Kota:** Yok. Ama metinler "Premium AI chat açar" diyor.

### 2.8 Öğren / Insights (`presentation/insights/**`)

- **Konular:** 5 adet (`basics, during, eating, health, tips`).
- **Konu içeriği:** kicker, title, subtitle, quote, 3 kart (ikon + başlık + gövde), tip.
- İçeriğin tamamı çeviri JSON'larında, 7 dilde.
- Arama yalnızca istemcide ve yalnızca liste başlığında.
- **Tamamen CMS adayı.**

### 2.9 Mochi World (`presentation/mochi_world/**`)

4 bölge, her birinin metriği ve sabit kodlanmış değerleri:

| Bölge | Metrik | Sabit değer |
|---|---|---|
| Orman | oruç sayısı | 3/10 |
| Göl | gün | 2/7 |
| Zirve | verilen kg | 0/2 |
| Bahçe | öğün | 3/10 |

**Seviye:**
- Bölge seviyesi `round(oran·4)` → 0–4.
- Sahne seviyesi bölgelerin en yükseği.

**Sağlık:** `thriving / wilting / drought`. TODO: "seri kırılmasından beslenecek".

**Diğer sabit değerler:**
- `_worldProgress = 0.12`
- Seviye rozeti "1"
- Hafta şeridinde bugün "10h"

Backend `GET /v1/world` ile tüm bunları hesaplanmış olarak dönmeli ([05 §7](05-is-kurallari.md#7-mochi-world)).

### 2.10 Premium

- Planlarda kilit sabit kodlanmış.
- Paywall ekranı yok.
- FAQ'a göre Premium şunları açıyor: **AI sohbet, tüm planlar, daha derin içgörüler, ek koçluk araçları.**
- Kodda entitlement, offering veya ürün ID'si yok.

### 2.11 Ana ekran widget'ları

App group `group.com.flywork.mochifast` üzerinden yazılan anahtarlar:

| Widget | Anahtarlar |
|---|---|
| Oruç | `fasting_active`, `fasting_start_ms`, `fasting_end_ms`, `fasting_plan_label`, `fasting_week` |
| Su | `water_current_ml`, `water_goal_ml`, `water_add_ml`, `water_timeline`, `water_week` |

**Sahte veri:** Hafta için yedek değer `[0.75, 0, 0.6, 0, 0.7, 0.7, 0.3]`.

**Backend etkisi:**
- İstemci bu anahtarları sunucu yanıtından doldurmalı.
- Başka cihazdan yapılan değişikliklerde sessiz push (opsiyonel).

### 2.12 Paylaşım

- **İçerik:** Yalnızca metin (oruç durumu, ilk oruç süresi).
- **Sahte değerler:** streak ve geçen süre.
- **Share App:** Boş handler. Referans linki ileride eklenebilir.

## 3. Sabit kodlanmış veri envanteri (gerçek veriyle değiştirilecek)

| Yer | Sabit değer | Gelecek kaynak |
|---|---|---|
| Profil başlığı | "Atilla E.", "AE", streak 3, premium true | `GET /v1/user/summary` |
| HomeBloc hata yedeği | "Squish", streak 3 | (yedek kaldırılmalı, hata durumu gösterilmeli) |
| Oruç sekmesi | 01:44:14, %10, streak 3, "Today 9:34 AM" | `GET /v1/fasts/active` |
| Ana sayfa oruç kartı | 6:12:39 | aktif seans |
| Hafta şeridi | yalnızca bugün 10 sa | `GET /v1/fasts/week` |
| Kilo | 102.5 / 112.2 / 75.2 (ve 74.2) | `GET /v1/weights/summary` |
| Su / adım | 600/2500, 1000/8000 | `GET /v1/user/summary` |
| Metabolik kart | 0.72 / 0.45 / 0.88 | türetilmiş skor |
| Tahmin kartı | %87, 14:00, 13:30–14:30, 16 sa | `GET /v1/fasts/forecast` (faz 7+) |
| Mochi'nin planı | "intense workout… slept 5h" | AI/kurala dayalı günlük ipucu |
| Challenge | 8954 katılımcı | `GET /v1/challenges/featured` |
| Kalori | 3143, 273, makrolar, 651 yakılan | `GET /v1/nutrition/today` |
| Kalori sonucu | çeviri dosyasındaki "Grilled Chicken 550 kcal" | fotoğraf analizi |
| Protein | 75/120, 3 öğün | `GET /v1/nutrition/today` |
| Uyku | tamamı | `GET /v1/sleep/summary` |
| Adım haftası | [4200…] | `GET /v1/steps?range=week` |
| Açlık geçmişi | 3 check-in, 2/1 | `GET /v1/hunger-checkins/summary` |
| Bildirimler | 2 kayıt | `GET /v1/notifications` |
| Sohbet geçmişi | h1/h2 (24 mesaj) | `GET /v1/chat/conversations` |
| Mochi World | 0.12, seviye 1, bölgeler | `GET /v1/world` |
| GoodCompany / premium kartı | 2M+, 4.8, 200K+ | `GET /v1/app/config` |
| Onboarding BuildingPlan / Projection | 74 kg… | `POST /v1/user/onboarding` yanıtı |

## 4. İstemci tarafında backend'i etkileyen açıklar

Hepsinin çözümü [13-flutter-entegrasyonu.md](13-flutter-entegrasyonu.md) belgesinde.

1. Sahte `local-onboarding-session` token'ı her istekte Bearer olarak gidiyor.
2. 401 durumunda refresh yok. `ExpiredTokenInterceptor` boş TODO.
3. `Accept-Language` uygulamada seçilen dili değil, **cihazın** dilini gönderiyor.
4. Saat dilimi hiç gönderilmiyor. Gün sınırları (su, seri, hafta şeridi) için zorunlu.
5. `data` dizi olarak gelirse parse edilmiyor (liste zarfı kuralı).
6. Onboarding BLoC'ları `registerFactory`, yani cevaplar ekrandan çıkınca kayboluyor.
7. `deviceId` sabit `'unknown-device-id'`.
8. Enum tutarsızlıkları:
   - `twentyFour` aslında 20:4 planı.
   - Ruh hâli bir yerde `superMood`, bir yerde `superFeeling`.
   - Plan başlığı bir yerde `16-8`, bir yerde `16:8`.
9. Varsayılan değer tutarsızlıkları:
   - Su hedefi 2000 ile 2500.
   - Hedef kilo 74.2 ile 75.2.
10. Engeller (obstacles) tek seçimli ama metin çoklu seçim söylüyor.
11. Öğün penceresinde doğrulama yok.
12. Açlık sonucu rastgele hesaplanıyor.
13. Kilo grafiğinin Y ekseni sabit. Ay harfleri Türkçe sabit kodlanmış.
14. `supportedLocales` it ve ru'yu içermiyor. Dil kataloğunda dosyası olmayan 4 dil var.
15. Kamera fotoğrafı hiç sıkıştırılmadan gidecek. Sunucuda yeniden kodlanacak ama istemcide de küçültülmeli.
