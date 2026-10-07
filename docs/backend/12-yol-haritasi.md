# 12 — Backend Yol Haritası

## 0. Özet takvim

| Faz | İçerik | Süre (1 dev) | Kilometre taşı |
|---|---|---|---|
| **F0** | Temel altyapı & proje iskeleti | 1 hafta | |
| **F1** | Kimlik doğrulama, kullanıcı, cihaz, onboarding | 2 hafta | |
| **F2** | Katalog & içerik, i18n, cache temeli | 1 hafta | |
| **F3** | Oruç çekirdeği: plan, seans, istatistik, seri, özet | 2 hafta | **M1 — Çekirdek MVP** |
| **F4** | Takipçiler: kilo, su, adım, uyku, öğün, açlık, beslenme | 2 hafta | |
| **F5** | Medya & Bunny CDN | 1 hafta | **M2 — Tam takip** |
| **F6** | Yapay zekâ: fotoğraf analizi, Coach Mochi | 2 hafta | |
| **F7** | Oyunlaştırma: Mochi World, XP/seviye, challenge'lar | 1.5 hafta | |
| **F8** | Abonelik (RevenueCat) & premium kapıları | 1 hafta | |
| **F9** | Bildirimler (push, inbox, zamanlayıcı) | 1.5 hafta | **M3 — Akıllı & ücretli** |
| **F10** | Yönetim paneli API'si, hesap/veri hakları, analitik | 1.5 hafta | |
| **F11** | Sertleştirme, yük testi, güvenlik denetimi, yayın | 1.5 hafta | **M4 — Yayın** |
| | **Toplam** | **~18 hafta** | |

**2 geliştirici ile ~10–11 hafta** sürer. Kritik yol: **F0 → F1 → F3**.

| Geliştirici | İş sırası |
|---|---|
| **Dev A** (çekirdek) | F0 → F1 → F3 → F7 → F9 → F11 |
| **Dev B** (yan modüller) | F0'ın ikinci yarısında katılır → F2 → F4 → F5 → F6 → F8 → F10 |

Mobil ekip, her fazın "İstemci işleri" bölümünü aynı sprintte yürütür. Ayrıntılı istemci listesi: [13](13-flutter-entegrasyonu.md).

## 1. Tanımlar

### 1.1 Her endpoint için Definition of Done
- [ ] JSON Schema: body, query, params ve **response**. `additionalProperties: false`.
- [ ] Kimlik doğrulama kancası ve **sahiplik testi** (başka kullanıcının kaydına erişince 404).
- [ ] İş kuralları saf fonksiyonlarda yazıldı ve birim testi var.
- [ ] Entegrasyon testi gerçek MySQL ile çalışıyor: mutlu yol, doğrulama hatası, yetki hatası.
- [ ] Cache okuma ve invalidation kuralları [07 §3.1](07-cache-performans.md#31-olay--invalidation-tablosu) tablosuna eklendi.
- [ ] Rate limit sınıfı atandı.
- [ ] Hata kodları katalogda tanımlı. Mesajlar en az `en` ve `tr` dillerinde mevcut.
- [ ] Loglar PII içermiyor. Gerekliyse metrik eklendi.
- [ ] OpenAPI'de görünüyor ve örnek yanıtı var.
- [ ] Migration gözden geçirildi: indeksler, `EXPLAIN` çıktısı, geri dönüş planı.

### 1.2 Ortamlar
| Ortam | Ne zaman hazır | Not |
|---|---|---|
| local | F0 | Yerel MySQL |
| staging | F0 sonu | Her `main` merge'ünde otomatik deploy. Ayrı Bunny/Firebase/RevenueCat sandbox |
| production | F11 | Etiketli (tag) sürüm + manuel onay. Migration ayrı bir adımda çalışır |

---

## F0 — Temel altyapı & proje iskeleti (1 hafta)

**Hedef:** Boş ama üretim kalitesinde bir iskelet. Bundan sonra her fazda yalnızca domain kodu yazılır.

### Görevler
- [ ] `mochifast-backend` reposu oluşturulur:
  - Node 24, ESM, saf JavaScript (TypeScript yok)
  - ESLint (flat config) + Prettier + husky/lint-staged + commitlint
  - `.editorconfig`, `.nvmrc`
- [ ] Klasör yapısı: [02 §3](02-mimari.md#3-proje-repo-yapısı).
- [ ] `config/index.js`: ortam değişkenleri şema ile doğrulanır, eksikse başlangıçta hata verir. `.env.example` tam ve açıklamalı.
- [ ] `infra/logger.js`: pino. Redaksiyon listesi, dev ortamında `pino-pretty`.
- [ ] `infra/db.js`: mysql2 havuzu, `withTransaction`, satır dönüştürücüler (BINARY(16) ↔ UUID, DECIMAL → number).
- [ ] `scripts/migrate.js`:
  - Checksum'lı migration runner
  - `GET_LOCK` ile eşzamanlı çalışma engeli
  - `schema_migrations` tablosu
  - `--dry-run` seçeneği
- [ ] `infra/cache.js`: process içi LRU (`get/set/del/delPrefix/getOrSet`, TTL jitter, single-flight). Redis yok (ADR 0005).
- [ ] `infra/queue.js`: MySQL iş kuyruğu (`migrations/0001_create_jobs.sql`: `jobs`, `job_schedules`), retry/backoff, `dedupeKey`, tekrarlı iş zamanlayıcısı. `worker.js` giriş noktası (kuyruk + zamanlayıcı), `schedules.js` tekrarlı iş tanımları.
- [ ] `app.js` ve eklentiler:
  - `request-context`: requestId, `Accept-Language` → locale, `X-Timezone`, `X-App-Version`, `X-Platform`, `X-Install-Id`
  - `envelope`: `{status, message, data}`
  - `errors`: `AppError` → zarf. Bilinmeyen hata → 500 + Sentry
  - `helmet`, `cors` (yalnızca admin origin), `rate-limit` (bellek içi store), `under-pressure`, `etag`, `swagger`
- [ ] `shared/i18n.js`: sunucu tarafı hata/şablon mesajları (en, tr, de, es, fr, it, ru) ve yedek dil.
- [ ] Sağlık uçları: `/health/live`, `/health/ready`. `/metrics` (prom-client, varsayılan metrikler + HTTP histogramı).
- [ ] Graceful shutdown: SIGTERM → readiness false → açık istekleri bitir → havuzları kapat.
- [ ] Geliştirme: `npm run dev` (`node --watch`, `.env` okunur).
- [ ] Test altyapısı:
  - Vitest
  - Global kurulum: `TEST_MYSQL_URL`; her test dosyası kendi geçici veritabanını kurar
  - `buildApp()` + `app.inject` yardımcıları
  - Fixture fabrikaları
- [ ] CI (GitHub Actions):
  - lint, format, unit + integration testleri
  - `npm audit` / OSV, gitleaks
  - staging deploy (main)
- [ ] Sentry entegrasyonu (release = git SHA).
- [ ] Staging ortamı: MySQL (staging), PM2 + Nginx, alan adı + TLS (Redis yok).
- [ ] `README.md` (çalıştırma), `CONTRIBUTING.md` (PR şablonu, DoD), ADR klasörü (`docs/adr/0001-fastify.md`…).

### Kabul kriterleri
- `.env` doldurulur → `npm run migrate` → `npm test` temiz makinede çalışır.
- Staging'de `/health/ready` 200 döner. Sentry'ye test hatası düşer. `/metrics` iç ağdan okunabilir.
- Var olmayan bir route 404 döner ve zarf biçimi doğrudur. Şema ihlali 400 `VALIDATION_FAILED` döner, alan detayları içerir.

---

## F1 — Kimlik doğrulama, kullanıcı, cihaz, onboarding (2 hafta)

**Hedef:** Gerçek misafir ve sosyal giriş, token yaşam döngüsü, onboarding verilerinin kalıcı olarak saklanması.

### Görevler

**Hafta 1 — Auth:**
- [ ] Migration'lar: kimlik (`0002_identity.sql`, `audit_logs` dahil), profil (sıradaki numara).
- [ ] JWT (`jose`, EdDSA):
  - imzalama ve doğrulama
  - `kid` desteği, anahtar rotasyonu yardımcı script'i (`scripts/gen-jwt-key.js`)
- [ ] `plugins/auth.js`:
  - `request.user`, `requireAuth`
  - `sid` iptal + kullanıcı durumu kontrolü (process içi cache `sess:{uid}:{sid}`, 60 sn; iptalde `delPrefix('sess:{uid}:')`)
- [ ] `POST /v1/auth/guest`: installId ile oluştur veya oturum aç, rate limit.
- [ ] Firebase ID token doğrulayıcı (Apple/Google girişi Firebase'de): JWKS cache, `iss`/`aud` = proje, `auth_time`, izinli `sign_in_provider`. Misafir backend'de (cihaz başına tek).
- [ ] `POST /v1/auth/register` (+ `/auth/social` takma adı):
  - giriş
  - kayıt
  - misafir yükseltme
  - `ACCOUNT_LINK_CONFLICT`
  - `mergeGuest` ([05 §11](05-is-kurallari.md#11-misafir-hesap-birleştirme))
- [ ] Refresh token rotasyonu:
  - aile (family) takibi
  - yeniden kullanım tespiti
  - 10 sn paralel istek toleransı
- [ ] `POST /v1/auth/logout` (tek cihaz / tüm cihazlar), `GET/DELETE /v1/auth/sessions`.
- [ ] `infra/crypto.js`: AES-256-GCM alan şifreleme, `kid` rotasyon desteği + birim testleri.
- [ ] `audit_logs` yazıcısı. Kayıt tipleri: `auth.login`, `auth.guest_created`, `auth.linked`, `auth.reuse_detected`.

**Hafta 2 — Kullanıcı & onboarding:**
- [ ] `GET/PATCH /v1/user/me` (+ eski `/user/me` yolu).
- [ ] `POST /v1/user/onboarding`:
  - tam doğrulama
  - sağlık kuralları ([05 §2.6](05-is-kurallari.md#26-sağlık-güvenliği-kuralları))
  - tek transaction ile yazılan tablolar: `user_profiles`, `food_preferences`, `obstacles`, `onboarding_submissions`, onboarding `weight_entries` kaydı, `user_goals` ve `user_settings` varsayılanları, consent'ler
  - yanıtta projeksiyon ve hedef tarih
  - eski `PATCH /user/onboarding` → 200 + kullanımdan kaldırıldı header'ı
  - **Not:** aktif plan oluşturma F3'te bağlanır. O zamana kadar `planCode` profilde (`user_profiles.plan_code`) saklanır. Plan listesi geçici olarak kodda (`src/modules/user/plans.js`); F2 kataloğu gelince oradan okunur.
- [ ] `GET/PATCH /v1/user/profile` (Edit Profile'ın tüm alanları).
- [ ] `GET/PATCH /v1/user/settings`, `GET/PATCH /v1/user/goals` (hesaplanan hedefler F4'te tamamlanır).
- [ ] `POST /v1/user/consents`.
- [ ] `PUT /v1/devices/current`, `DELETE /v1/devices/current/push-token`.
- [ ] `GET /v1/user/progress` iskeleti (F3'te gerçek veriyle dolar). Şimdilik `user_stats` satırından okur.
- [ ] Eski yol uyumluluğu: `/auth/register`, `/user/me`, `/user/progress` → `/v1` yönlendirmesi + `Deprecation` header'ı.

### Kabul kriterleri
- Misafir → onboarding → Apple (Firebase) ile giriş akışında **aynı userId** korunur. Onboarding verileri kaybolmaz.
- Mevcut bir Apple hesabıyla misafirden giriş yapılınca 409 döner. `mergeGuest` ile veriler taşınır (entegrasyon testi).
- Kullanılmış refresh token tekrar kullanılınca tüm aile iptal edilir ve 401 `REFRESH_REUSED` döner (test).
- 15 dk sonra access token 401 `TOKEN_EXPIRED` verir. Refresh ile yeni çift alınır.
- `local-onboarding-session` gibi geçersiz bir token 401 döner.
- Onboarding'de 18 yaş altı + OMAD seçimi 422 `UNSAFE_REQUEST` döner.

### İstemci işleri (paralel)
- `firebase_core`, `firebase_auth` (+ `sign_in_with_apple`, `google_sign_in`) eklenir; `flutterfire configure`. Sahte login kaldırılır.
- Onboarding başında `POST /auth/guest` çağrılır, sahte token kaldırılır.
- **Tek** bir `OnboardingCubit` (singleton) tüm cevapları toplar ve `POST /v1/user/onboarding` ile gönderir.
- Refresh interceptor yazılır (tek uçuşlu kuyruk). `installId` üretilip saklanır. Standart header'lar eklenir.

---

## F2 — Katalog & içerik, i18n, cache temeli (1 hafta)

**Hedef:** Uygulamadaki tüm statik içeriğin backend'den, cache'li ve 7 dilde gelmesi.

### Görevler
- [ ] Migration'lar: katalog `0005_catalog_plans.sql` (planlar, gruplar, etiketler, app_config), içerik (sıradaki numara).
- [ ] `scripts/extract-translations.js` (`npm run seed:extract`): Flutter `assets/translations/*.json` dosyalarından şu bölümleri çeker ve `seeds/content.json` + `seeds/content_labels.json` üretir (görsel/renk/eşleşme yapısı uygulamanın ekran kodundan alınmıştır):
  - `plans.*`, `onboarding.plan_*`
  - `body_status.*`, `eating_window.*`
  - `fasting_struggle.*`
  - `insights_page.*`, `insights_detail.*`
  - `faq.*`, `chat.suggestion_*`, `home.challenge_*`
- [ ] `seeds/plans.json`:
  - Ürün dokümanındaki **21 plan** (dokümanda 21 satır var) ([01 §2.4](01-uygulama-analizi.md#24-planlar-presentationplans--üç-ayrı-tutarsız-katalog)).
  - Kategori, yoğunluk, premium, güvenlik onayı, izin verilen zamanlama tercihleri.
  - Doküman İngilizce; diğer 6 dil için çeviri gerekecek ([14 #14](14-acik-kararlar.md)).
- [ ] `scripts/seed.js`: idempotent seed (upsert by code).
- [ ] `GET /v1/catalog/plans`, `/plans/:code`, `/stages`, `/struggle`, `/onboarding-options`, `/faq`, `/chat-suggestions`.
- [ ] `GET /v1/app/config` + `app_config` seed (min sürüm, özellikler, limitler, pazarlama sayıları, yasal metin sürümleri).
- [ ] `GET /v1/insights/categories`, `/articles` (kelime başı arama, imleçli sayfalama; MariaDB'de ngram yok), `/articles/:slug`.
- [ ] Cache katmanları: `cat:v{n}:*` anahtarları + `cat:version` artırma yardımcısı.
- [ ] HTTP cache: `ETag` + `Cache-Control` + `Vary: Accept-Language`, 304 testleri.
- [ ] Minimum sürüm ara katmanı: `X-App-Version < min` → 426 `APP_UPDATE_REQUIRED`.

### Kabul kriterleri
- `Accept-Language: tr` ile Türkçe içerik gelir. Desteklenmeyen dil `en`'e düşer.
- Katalog uçları p95 < 30 ms (cache'li). Aynı ETag ile istek atılınca 304 döner.
- 21 planın hepsi doğru kategoride gelir. Premium kilitleri oturumsuz istekte `isLocked: true`.

### İstemci işleri
- Planlar sekmesi ve plan detayı katalogdan beslenir. İki yerel katalog ve `twentyFour` enum'u kaldırılır.
- Vücut evreleri, zorlanma içeriği, Insights ve FAQ ekranları API'den beslenir.
- `supportedLocales` listesine `it` ve `ru` eklenir. `Accept-Language` uygulama diline bağlanır.

---

## F3 — Oruç çekirdeği (2 hafta) → **M1**

**Hedef:** Uygulamanın kalbi gerçek veriyle çalışır: plan seçimi, oruç başlat/bitir, geçmiş, istatistik, seri, hafta şeridi, ana sayfa özeti.

### Görevler

**Hafta 1 — Plan & seans:**
- [x] Migration `0007_plans_fasting.sql`: `user_plans`, `plan_day_checkins`, `fasting_sessions` (tek aktif için üretilmiş sütun + unique), `struggle_events`, `idempotency_keys`. Toplam tablolar (`daily_summaries`, `xp_events`) hafta 2'de.
- [x] `plans.rules.js`:
  - zamanlama tercihi → yeme penceresi
  - haftalık program doğrulama (5:2 ardışık değil vb.)
  - custom aralıklar
  - premium ve sağlık kontrolleri
- [x] `GET/PUT /v1/plans/current`, `PUT /v1/plans/days/:date`, `GET /v1/plans/history`. Onboarding'in `planCode`'u aktif plana bağlanır.
- [x] `fasting.rules.js`:
  - durum makinesi
  - zaman aralığı kontrolleri
  - vücut evresi hesabı
  - yeme penceresi evresi
- [x] `POST /v1/fasts` (idempotent, tek aktif, çakışma kontrolü `SELECT … FOR UPDATE`).
- [x] `GET /v1/fasts/active` (canlı `elapsed`, `progress`, `stage`, `serverTime`). Negatif cache bilinçli olarak eklenmedi: sorgu tek indeksli satır, cache invalidation riski kazançtan büyük; F3 hafta 2'de yük ölçülünce yeniden değerlendirilir.
- [x] `PATCH /v1/fasts/:id`, `POST /:id/finish`, `POST /:id/cancel`, `POST /v1/fasts/manual`, `DELETE /:id`.
- [x] `Idempotency-Key` eklentisi (MySQL `idempotency_keys` tablosu + migration, gövde hash'i kontrolü, süresi dolanları silen periyodik iş).

**Hafta 2 — Türetilmiş veriler:**
- [x] Migration `0008_aggregates.sql`: `daily_summaries`, `xp_events` (`ref_key` birincil anahtarda; NULL'lı UNIQUE yerine).
- [x] `stats.rules.js`: seri (nötr ve zorunlu gün, %80 tolerans, check-in), kilometre taşları, sayaçlar, XP ve seviye.
- [x] `stats.service`:
  - `recompute(userId, fromDate)`: günlük özetler, seri, taş XP'si, sayaçlar, seviye
  - yazmalarla aynı transaction, kullanıcı satırı kilidi
  - okuma uçlarında bayat seri tazeleme (`fresh`)
- [ ] ~~Domain olay altyapısı (`events.js`)~~ → ertelendi. Yeniden hesaplama yazmayla aynı transaction'da doğrudan çağrılıyor (tutarlı, basit). Olay yayını, F4/F7/F9'da birden çok dinleyici (dünya, challenge, bildirim) gelince eklenir. Cache invalidation da o zaman bağlanır (`/user/summary` şimdilik cache'siz).
- [x] `POST /finish` yanıtı: `isFirstFast`, `streak`, `xpGained`, `levelUp`.
- [x] `/fasts/week`, `/fasts/stats` (`GET /v1/fasts` ve `/fasts/:id` hafta 1'de bitti).
- [x] `GET /v1/user/summary` (ana sayfa birleşik yanıtı; F4'te takipçi alanları eklenir).
- [x] `GET /v1/user/progress` gerçek veriyle. `GET /v1/user/stats`.
- [x] İşler (`stats` kuyruğu, worker'da tek eşzamanlılık):
  - `daily-rollup` (24 saatte bir; son 26 sa değişenler)
  - `day-rollover` (saatlik; yerel gece yarısı geçen dilimler)
  - `fast-autoclose` (15 dk'da bir; 72 sa)
- [x] `npm run stats:recompute [-- <userId>]` (elle tam yeniden hesaplama).
- [x] `POST /v1/fasts/:id/struggles` (+ `/v1/struggles`) — hafta 1'de yapıldı.
- [x] Birim testleri:
  - seri senaryoları: günlük plan, 5:2, nötr gün, bugün sürüyor, kilometre taşları
  - gece yarısını geçen oruç (İstanbul 20:00 → 12:00, hafta 1 entegrasyon)
- [ ] Saat dilimi değişimi ve yaz saati (DST) geçişi senaryoları: seans `tz`'si saklanıyor, ama özel testleri yazılmadı. F11 sertleştirmede.

### Kabul kriterleri
- Aynı anda iki oruç başlatılamaz (eşzamanlı 10 istek testi → tek başarı).
- `Europe/Istanbul` saat diliminde 20:00 → 12:00 orucu bitiş gününe (ertesi gün) yazılır. Hafta şeridinde doğru günde görünür.
- 16 sa planında 13 sa oruç seriyi korur (%80). 12 sa korumaz.
- Tamamlanmış orucun silinmesi seriyi ve sayaçları doğru şekilde geri alır (recompute testi).
- `GET /user/summary` p95 < 120 ms (yük testi verisiyle).
- **M1 demosu:** Gerçek bir cihazda misafir → onboarding → plan → oruç başlat → bitir → ana sayfa ve hafta şeridi gerçek verilerle görünür.

### İstemci işleri
- `FastingView` gerçek durum makinesine bağlanır. Başlangıç sheet'i ve bitiş ekranı (feeling, notlar, kilo) kaydeder.
- Ana sayfa `GET /user/summary`'ye geçer. Sahte yedek değerler (Squish, 3, 10h, 6:12:39) kaldırılır.
- Widget senkronu (`FastingWidgetSync`) sunucu durumundan beslenir. Sahte hafta verisi kaldırılır.
- Profil → Fasting History ekranı (yeni).

---

## F4 — Takipçiler (2 hafta)

**Hedef:** Kilo, su, adım, uyku, öğün, açlık ve beslenme ekranlarının hepsi gerçek veriyle çalışır.

### Görevler

**Hafta 1:**
- [x] Migration `0009_trackers.sql` (`water_entries`, `step_daily`, `sleep_entries` + `external_id`; `weight_entries` 0003'te).
- [x] **Kilo:**
  - CRUD
  - `/weights/chart` (gün/hafta/ay kovaları, dinamik Y ekseni — hedefi de kapsar, yerelleştirilmiş etiketler)
  - `/weights/summary` (BMI kategorisi ve bandı, ilerleme)
  - `PATCH /weights/goal`
  - bitiş ekranından kilo kaydı (`source = fasting_finish`)
- [x] **Su:**
  - `/water/day`, `POST /water`, `DELETE /water/:id`, `/water/week`
  - hedef günü sayacı
  - `HIGH_WATER_INTAKE` uyarısı
- [x] **Adım:**
  - `PUT /steps/:date`, `POST /steps/sync` (toplu, kaynak önceliği)
  - `GET /steps` (türetilmiş km/kcal/dk; day/week/month)
- [x] **Uyku:**
  - CRUD
  - `/sleep/sync` (`externalId` ile idempotent)
  - `/sleep/summary` (son gece, hedef, hafta)
- [x] Takipçi yazmaları günlük özete ve XP'ye bağlandı (`stats.applyDay`; su hedefi 5, kilo 3 XP). `/user/summary` → `today.water/steps/sleep` gerçek veri. Gece doğrulaması son 3 günün takipçi sütunlarını yeniden yazar.

**Hafta 2:**
- [x] Migration `0010_meals_hunger.sql` (`meals`, `hunger_checkins`).
- [x] **Öğünler:**
  - CRUD (manuel, `quickKcal`). Aktif oruç varsa `suggestEndFast` önerisi.
  - `GET /meals?date` (zaman çizelgesi) ve sayfalı geçmiş.
- [x] **Beslenme:**
  - `nutrition.rules.js`: BMR, TDEE (bugünün adım kalorisi dahil), kcal hedefi, makrolar, taban değerler, sağlık bayrakları, yakılan kalori
  - `/nutrition/day`, `/nutrition/week`
  - `/user/goals` içinde `computed` alanı adım kalorisiyle
- [x] **Açlık:**
  - `hunger.rules.js` (skor tablosu v1, bağlam puanı, güvenlik bayrağı)
  - `/hunger-checkins/evaluate`, CRUD, `/summary`. Öneri metinleri katalogda (7 dil; `safety_end_fast` elle yazıldı)
- [x] Tüm takipçiler `daily_summaries`'e bağlandı (artımlı `applyDay` + gece/elle recompute). `GET /user/summary` `today` alanı tamam (`nutrition`, `lastMeal`, `hunger`).
- [ ] Bildirim kutusu için `weight_update` olayı → F9'a ertelendi (olay altyapısı henüz yok; bkz. F3 hafta 2 notu).
- [x] Çevrimdışı ve idempotent yazma: oruç, kilo, su, uyku, öğün, açlık POST'larında istemci `id` desteği (aynı id → 200, başkasının id'si → 409).

### Kabul kriterleri
- **Su:** 23:50'de içilen su o güne, 00:10'da içilen ertesi güne yazılır. Gece yarısı sıfırlama hatası çözülmüştür.
- **Açlık:** Aynı cevaplar her zaman aynı sonucu verir. İstemcinin gönderdiği sonuç dikkate alınmaz.
- **Kilo grafiği:** 50 kg ve 140 kg kullanıcılar için Y ekseni doğru hesaplanır.
- **Sağlık bayrakları:** `eating_disorder_history` bayrağı olan kullanıcıda `kcalGoal = null` döner.
- **Adım:** Sağlık senkronu manuel değeri ezer; manuel değer senkronlanmış günü ezemez (409).

### İstemci işleri
- Water, Steps, Sleep, Body History, Calories, Protein, Meal Records ve Hunger ekranlarının tüm mock değerleri kaldırılır.
- `Random()` ile hesaplanan açlık sonucu kaldırılır. Q1–Q4 cevapları `HungerFlowArgs` ile ileri taşınır.
- Kilo grafiğinin sabit Y ekseni ve Türkçe sabit ay harfleri kaldırılır.
- (Opsiyonel) HealthKit / Health Connect entegrasyonu ve `/steps/sync`, `/sleep/sync` çağrıları.

---

## F5 — Medya & Bunny CDN (1 hafta) → **M2**

**Hedef:** Güvenli fotoğraf yükleme hattı. Avatar ve öğün fotoğrafı çalışır.

### Görevler
- [x] Migration `0011_media.sql` (+ `users.avatar_media_id`, `meals.photo_media_id` FK'leri).
- [ ] Bunny hesabı kurulumu (**kullanıcı işi**, panelden):
  - `mochifast-private` storage zone (DE + AB içi replikasyon) ve pull zone'u; **Token Authentication açık**
  - anahtarlar `.env`/`.env.production`'a: `BUNNY_PRIVATE_*`, `BUNNY_TOKEN_AUTH_KEY`, `MEDIA_DRIVER=bunny`
  - alan adları ve TLS (`media.mochifast.app`), edge kuralları
  - public zone (`mochifast`, mevcut) uygulama görselleri için kalır
- [x] `infra/bunny.js`: `put` (checksum + 3 deneme), `delete`, `list(prefix)`, `purge`, `signPrivateUrl` (saat kovalı), `verifyPrivateToken`. Yerel diske yazan sürücü (`MEDIA_DRIVER=local`) + `/media-files/*` ucu.
- [x] `media.pipeline` / `media.service`:
  - multipart limitleri (1 dosya, 10 MB → 413)
  - magic byte kontrolü (jpeg/png/webp; HEIC/SVG/PDF → 415)
  - `sharp` hattı: rotate, varyantlar, WebP, metadata temizliği, piksel limiti
  - SHA-256 ile yinelenen yükleme tespiti (24 sa)
  - blurhash
- [x] `PUT/DELETE /v1/user/me/avatar` (senkron; eski avatar hemen silinir). `GET /user/me` → imzalı `avatarUrl`.
- [x] `POST /v1/media` (`purpose = mealPhoto`), `GET/DELETE /v1/media/:id`, öğüne fotoğraf bağlama (`photoMediaId`).
- [x] Yanıtlara imzalı URL gömme (`media.present`, listelerde toplu `presentMany`).
- [x] Temizlik işleri (`media` kuyruğu): takılı `processing` (1 sa), öğüne bağlanmamış fotoğraflar (24 sa), silinmiş öğünlerin medyası (30 gün).
- [x] Testler: EXIF/GPS temizliği, yön, dekompresyon bombası, HEIC/SVG/PDF reddi, imzalı URL formatı (token değeri `openssl` ile bağımsız hesaplanan değerle), token'sız/bozuk/süresi geçmiş → 403, 10 MB → 413.
- [ ] İmzalı URL'nin **gerçek Bunny edge'inde** doğrulanması: private zone kurulunca staging'de (token'sız 403, imzalı 200).

### Kabul kriterleri
- iPhone'dan GPS'li bir fotoğraf yüklenip Bunny'den indirildiğinde **hiç EXIF içermez**.
- Token'sız veya süresi geçmiş private URL 403 döner.
- 10 MB'tan büyük dosya 413 döner.
- **M2 demosu:** Tüm takipçiler + avatar + fotoğraflı öğün kaydı.

### İstemci işleri
- Avatar yükleme (Edit Profile).
- Kamera çıktısını sıkıştırma (≤ 2048 px, JPEG).
- `cached_network_image` için `cacheKey` ayarı. Süresi geçmiş URL için yenileme akışı.

---

## F6 — Yapay zekâ (2 hafta)

**Hedef:** Fotoğraftan kalori analizi ve Coach Mochi sohbetinin üretim kalitesinde çalışması.

### Görevler

**Hafta 1 — Fotoğraf analizi:**
- [x] Migration `0012_ai.sql` (`food_photo_analyses`, `ai_quota_daily`, `ai_usage_daily`; sohbet tabloları 2. haftada).
- [x] `infra/anthropic.js`:
  - istemci (`@anthropic-ai/sdk`, `maxRetries: 2`)
  - timeout'lar
  - devre kesici (5 geçici hata → 30 sn)
  - fiyat tablosu `app_config.ai.pricing`'ten
  - `fallbacks: "default"` (beta `server-side-fallback-2026-07-01`, kapatılabilir)
- [x] `prompts/meal_analysis.v1.md` + JSON şeması (`output_config.format`) + dil talimatı. Zod yerine saf JSON Schema + `normalizeAnalysis` (proje saf JS).
- [x] `POST /v1/meals/photo-analyses` (202) + `GET /:id`. `photoAnalysis` worker işi (`ai` kuyruğu): retry, refusal, doğrulama. Öğün kaydı `analysisId` ile.
- [x] Kota servisi (`ai.gate`):
  - MySQL `ai_quota_daily` (atomik artırma, eski satırları silen periyodik iş)
  - yerel gün, `resetAt`
  - başarısız istekte iade
  - global maliyet sigortası (`ai.daily_budget_usd`)
  - `GET /v1/chat/quota`
- [ ] **Eval seti:** `scripts/eval-meal-analysis.js` hazır (MAPE, MAE, `isFood` doğruluğu, p50/p95, maliyet). **Veri seti (100 öğün + 20 yemek dışı fotoğraf, bilinen kalori) ve `ANTHROPIC_API_KEY` bekleniyor.**
- [x] AI rıza kontrolü: `ai_processing` yoksa 403 `CONSENT_REQUIRED`.

**Hafta 2 — Coach Mochi** (sağlayıcı: **OpenAI**, kullanıcı kararı):
- [x] Migration `0013_chat.sql` (`chat_conversations`, `chat_messages`).
- [x] `infra/openai.js`: Chat Completions akışı, tipli hata sınıflandırması, ortak devre kesici (`infra/breaker.js`), kullanım dönüşümü.
- [x] `prompts/coach_mochi.v1.md`: persona, kapsam, sağlık korkulukları, biçim kuralları, bağlamın veri olduğu.
- [x] Bağlam derleyici (`chat.context.js`): profil, plan, aktif oruç / yeme penceresi, seri, bugün, son açlık sonucu, güvenlik bayrakları, giriş noktası.
- [x] Sohbet uçları: konuşma CRUD, mesaj listeleme (cursor), pin/sil, geri bildirim, öneriler.
- [x] `POST …/messages` SSE: kilit, kota, akış, bağlantı kopunca iptal (AbortController), `interrupted`, heartbeat, JSON yedek yolu, tekrar gönderim.
- [x] Prompt cache: sabit persona öneki + bağlamın birebir saklanması (test: önceki tur byte'ı byte'ına aynı). `cache_read_tokens` kaydı.
- [x] Uzun sohbet özeti işi (40+ mesaj, her 20 mesajda).
- [x] Acil durum sinyali sınıflandırıcısı (7 dil) → `safety: "urgent"`.
- [ ] Red-team: set (`redteam/chat-cases.json`, 14 vaka) ve betik hazır; **`OPENAI_API_KEY` + model gelince çalıştırılıp elle gözden geçirilecek**.
- [x] Nginx: SSE yolunda `proxy_buffering off` + 120 sn; yükleme yollarında 11 MB (`deploy/nginx/mochifast-api.conf`).

### Kabul kriterleri
- Eval: kcal MAPE ≤ %25, `isFood` ≥ %98, p95 uçtan uca < 12 sn.
- Sohbette ilk token p95 < 2.5 sn. Akış ortasında bağlantı kopunca Anthropic çağrısı iptal edilir (log/metrikle doğrulanır).
- Ücretsiz kullanıcı 4. mesajda 429 `QUOTA_EXCEEDED` alır, `resetAt` doğru olur.
- Red-team setindeki tüm "tehlikeli istek" vakalarında güvenli yanıt verilir.

### İstemci işleri
- Kalori sonucu ekranı: gönder → yokla (poll) → sonucu düzenle → `POST /meals`.
- Sohbet: SSE istemcisi (Dio `ResponseType.stream` + satır ayrıştırıcı), geçmiş konuşmayı açma (şu an çalışmıyor), mesaj zaman damgaları, kota ve paywall akışı.
- Açlık sonucundan "Talk to Mochi" → `contextSource = hungerResult` ile konuşma açılır.

---

## F7 — Oyunlaştırma (1.5 hafta)

**Hedef:** Mochi World, XP/seviye ve challenge'ların gerçek veriyle çalışması.

### Görevler
- [x] Migration `0014_gamification.sql` + `world_zone_thresholds` ve challenge kataloğu seed'i (`seeds/gamification.json`; 4 challenge, 7 dil).
- [x] `world.rules.js`: bölge seviyesi, `nextThreshold`, `ratioToNext`, `sceneLevel`, `worldProgress`, sağlık hesabı.
- [x] `user_stats` alanlarının beslenmesi:
  - `water_goal_days`, `meals_logged` (F4), `best_weight_lost_kg` (ham veriden)
  - `world_health` (her yeniden hesaplamada; gün dönümünde okuma/iş ile)
- [x] `GET /v1/world` (cache'siz; hafif sorgular).
- [x] Seviye atlama ve sağlık değişimi: bitirme yanıtında `world.levelUps`/`health` (bildirimler F9'da bağlanır).
- [x] **Challenge'lar:**
  - katalog seed
  - `GET /challenges`, `/featured`, `join`, `leave`
  - her ilgili yazmada pencere içinde yeniden sayım
  - tamamlanma + XP (bir kez)
  - süresi dolanlar için saatlik iş
  - gerçek katılımcı sayısı; avatarlar izin ayarı gelene kadar boş
- [x] Seri kilometre taşı XP'leri (F3'te yapıldı).
- [ ] (Opsiyonel) Fast Forecast v0 — yapılmadı.
- [ ] (Opsiyonel) Günlük ipucu — yapılmadı.

### Kabul kriterleri
- Mock senaryosu (3 oruç, 2 su günü, 0 kg, 3 öğün) verildiğinde dünya istemcinin beklediği seviyeleri üretir.
- 4 zorunlu gün kaçırılınca durum `drought` olur, tek bir tutulmuş gün `thriving`'e döndürür.
- "1 Week of fasting challenge" (7 günde 3 öğün) uçtan uca tamamlanır ve XP verilir.

### İstemci işleri
- Mochi World view'deki `_zones`, `_worldProgress`, `_health` ve seviye "1" değerleri `GET /world`'den gelir. İstemci `round(oran·4)` yerine sunucunun `level` değerini kullanır.
- Ana sayfa challenge kartı: Join butonu bağlanır. İlerleme ve detay görünümü (yeni) eklenir.

---

## F8 — Abonelik (1 hafta)

### Görevler
- [x] Migration `0015_subscriptions.sql` (`subscriptions`, `revenuecat_events`, `notifications` inbox).
- [ ] RevenueCat projesi (**kullanıcı işi**, `TODO.md`):
  - entitlement `premium`
  - ürünler ve offering + Paywall (RevenueCat Paywalls)
  - webhook URL'si + auth değeri
  - sandbox ve production ayrımı
- [x] `POST /v1/webhooks/revenuecat`: auth (sabit zamanlı), idempotency (`event_id`), kuyruk.
- [x] `revenuecatEvent` işi: REST teyidi, durum eşlemesi, TRANSFER, audit. (API önbelleği worker'dan silinemez: 30 sn TTL + istemci sync.)
- [x] `GET /v1/subscription`, `POST /v1/subscription/sync`.
- [x] Entitlement (tek kaynak, 30 sn önbellek). Bağlanan yerler:
  - premium planlar (402) ve bekleyen onboarding planının otomatik etkinleşmesi
  - AI kotaları (premium limitleri) ve bütçe sigortası muafiyeti
  - premium içerik (katalog/insights kilitleri)
  - challenge'lar
  - `/user/me` ve giriş yanıtlarında `isPremium`
- [x] Premium kaybı akışı: ertesi yerel gün plan 16:8'e düşer, inbox kaydı (`premium_expired`).
- [x] Promosyon premium: servis + `npm run premium:grant` (panel F10'da).
- [x] Paywall: istemcide RevenueCat Paywalls (sunucu kodu yok).

### Kabul kriterleri
- Sandbox satın alma yapılınca `/user/me.isPremium = true` en geç 5 sn içinde (sync ile anında) görünür.
- Aynı webhook iki kez gelirse tek kez işlenir.
- Süresi dolan abonelikte ertesi gün premium plan 16:8'e düşer ve inbox kaydı oluşur.

### İstemci işleri
- RevenueCat yapılandırması, `Purchases.logIn(userId)`, paywall (`purchases_ui_flutter`).
- "Get Premium" butonlarının bağlanması. 402 ve 429 hatalarında paywall gösterimi.
- Profil başlığındaki sabit `isPremium: true` kaldırılır.

---

## F9 — Bildirimler (1.5 hafta) → **M3**

### Görevler
- [x] Migration `0016_notifications.sql`. Şablon seed'i (`seeds/notifications.json`, 20 tür, 7 dil; metinlerin çoğu yeni → gözden geçirilecek).
- [ ] Firebase projeleri (staging ve prod) + servis hesabı (**kullanıcı işi**, `TODO.md`). `infra/fcm.js` (`sendEach`, geçersiz token temizliği) hazır.
- [x] Bildirim servisi: `schedule`, `cancel` (`notify.js`), inbox, şablon render (yer tutucular, `Intl`; bölge/challenge/plan adları dile göre).
- [x] `notificationDispatch` işi: 30 sn, `SKIP LOCKED`, 500'lük partiler.
- [x] `pushSend` işi: ayar, sessiz saat (ertele/sessiz/gönder), yeni kullanıcı sessiz dönemi, frekans sınırı (6/gün, kategori 3), gönderim anında geçerlilik, inbox ve push, retry.
- [x] Olay bağlamaları: oruç (hedef, yarı yol, evre, overdue), yeme penceresi, kilo, seri (dürtme, kilometre taşı, kayıp), dünya, challenge, abonelik. Dışa aktarma → F10.
- [x] Günlük planlama işi: su slotları, tartı hatırlatması, seri dürtmesi, oruç başlatma (yerel saat dilimine göre).
- [x] Inbox uçları: liste, okunmamış sayısı, okundu, tümü okundu, sil.
- [ ] (Opsiyonel) widget yenilemesi için sessiz push — yapılmadı.

### Kabul kriterleri
- 16 sa oruç başlatılınca hedefe ulaşma push'u ±60 sn içinde gelir. Oruç erken bitirilirse gelmez.
- Sessiz saatlerdeki su hatırlatması ertelenir veya atlanır. Ayarlardan kategori kapatılınca push gitmez.
- Geçersiz FCM token'ı otomatik olarak temizlenir.
- **M3 demosu:** AI, dünya, abonelik ve bildirimler dahil tam ürün akışı.

### İstemci işleri
- FCM kurulumu. İzin akışı (onboarding sonrası değer anlatan bir ekranla). `onTokenRefresh` → `PUT /devices/current`.
- Inbox ekranı API'ye bağlanır (`hoursAgo` yerine `createdAt`, gün gruplama).
- Profil → bildirim ayarları (kategori anahtarları, sessiz saatler, su aralığı).
- Derin link yönlendirme.

---

## F10 — Yönetim paneli API'si, hesap/veri hakları, analitik (1.5 hafta)

### Görevler
- [x] Migration `0017_compliance.sql` (silme ve dışa aktarma talepleri), `0018_admin.sql` (yöneticiler, katalog dokümanları, günlük etkinlik).
- [ ] **Hesap silme:**
  - [x] `DELETE /v1/user/me`; geri alma giriş akışında (`409 ACCOUNT_PENDING_DELETION` → `restoreAccount: true`)
  - [x] `account-delete` işi: Firebase kullanıcı silme, Bunny önek silme ve purge, RevenueCat silme, cascade, audit anonimleştirme. Apple revoke istemcide (06 §8.3)
  - [x] Play Store için web silme sayfası: `/account/delete` (bilgi sayfası + destek e-postası; destek panelden talep oluşturur)
- [x] **Veri dışa aktarma:** `POST /v1/user/me/export` → zip (JSON + CSV + fotoğraflar) → private zone → bildirim.
- [x] **Rıza yönetimi:**
  - yasal metin sürümü değişince yeniden onay (`requiredConsents`)
  - rıza geri çekme davranışları (sağlık → kayıt 403, pazarlama → bildirim kapalı)
- [x] **Saklama (retention) işleri:**
  - inaktif misafir (90 gün), birleştirmede kapanan misafir (30 gün)
  - yumuşak silinenler (30 gün), okunmuş bildirimler (90 gün)
  - `push_deliveries` (F9), audit (13 ay), kapanmış oturumlar (30 gün)
  - [ ] inaktif kayıtlı hesap (24 ay + uyarı) — e-posta kanalı gelince
- [x] **Admin API:**
  - kimlik doğrulama: argon2id, TOTP, kilitleme
  - RBAC, IP allowlist
  - içerik + çeviriler: bölüm dokümanları (planlar, evreler, struggle, insights, FAQ, öneriler, challenge'lar, şablonlar), sürüm geçmişi ve geri alma
  - `app_config` düzenleme + `catalog.version` artırma
  - medya yükleme (public)
  - kullanıcı arama (maskeli) ve destek işlemleri
  - raporlar: DAU/MAU, kayıt hunisi, oruç tamamlama, AI maliyeti, premium dönüşümü
- [ ] **Ürün analitiği (opsiyonel):** Sunucu tarafı olaylar (anonim ID ile) PostHog/Amplitude'a gönderilir. Rıza kontrolü yapılır. — yapılmadı (raporlar şimdilik DB'den)
- [ ] Admin arayüzü: Ayrı bir proje (React/Next veya Refine/AdminJS). Bu yol haritasının kapsamı **yalnızca API**'dir.

### Kabul kriterleri
- Hesap silme sonrası kullanıcıya ait hiçbir satır kalmaz (tablo bazında sayım testi). Bunny önek dizini boştur.
- Dışa aktarma zip'i tüm domainleri içerir ve 7 gün sonra erişilemez.
- Admin işlemlerinin hepsi `audit_logs`'a düşer. MFA'sız giriş mümkün değildir.

### İstemci işleri
- Profil: Hesabı sil (açıklama + onay), Verilerimi indir, gizlilik ve şartlar linkleri, rıza ekranı.

---

## F11 — Sertleştirme & yayın (1.5 hafta) → **M4**

### Görevler
- [ ] **Güvenlik:**
  - [x] OWASP ASVS L2 öz-denetimi (kod okuması): kritik/yüksek yok; düzeltilenler: kullanıcı bazlı rate limit (önceden hep IP'ydi) + IPv6 /64, misafir oluşturma sınırının `/auth/register` ile aşılması, yönetici token iptali + zorunlu şifre değişimi + kilitte hesap sızıntısı, üretimde boş allowlist'te admin kapalı, e-posta araması POST, oturum mutlak ömrü, HSTS (nginx), sohbet/analiz dakika limitleri
  - [ ] harici pentest (API + mobil)
  - [ ] bulguların kapatılması
- [ ] **Yük testi (k6):**
  - [x] sabah zirvesi senaryosu + eşikler (`loadtest/`)
  - [ ] staging'de 500 rps çalıştırma ve darboğaz analizi
- [ ] **Gözlemlenebilirlik:**
  - [x] worker metrikleri (iş sonuç/süre, kuyruk birikimi, AI maliyeti, push, geciken bildirim), alarm kuralları (`deploy/monitoring/alerts.yml`), runbook'lar (`docs/runbooks.md`)
  - [ ] Prometheus/Grafana kurulumu, uptime izleme; tracing Sentry ile (`SENTRY_TRACES_SAMPLE_RATE`), OpenTelemetry yok
- [ ] **Yedekleme:**
  - [x] saatlik şifreli yedek + tatbikat betikleri (`scripts/backup-db.sh`, `scripts/restore-drill.sh`); cPanel'de PITR yok → RPO ≤ 1 sa
  - [ ] cron kurulumu ve ilk **geri yükleme tatbikatı**
- [ ] **Read replica:** cPanel'de yok; raporlar şimdilik primary'de (küçük, indeksli sorgular).
- [ ] **WAF/CDN önü:** Bunny Shield veya Cloudflare.
- [ ] **Uyumluluk:**
  - KVKK: aydınlatma metni, açık rıza metinleri, VERBİS, yurt dışı aktarım sözleşmeleri
  - DPA'lar: Bunny, Anthropic, OpenAI, Google, RevenueCat, Sentry
  - [x] App Store gizlilik etiketi ve Play Veri güvenliği cevapları: [15](15-magaza-gizlilik.md)
- [x] **Runbook'lar:** olay müdahalesi, anahtar rotasyonu, kötü deploy geri alma, migration geri dönüşü, AI maliyet patlaması (+ AI acil kapatma: `app_config.features`)
- [x] **DST/saat dilimi:** testler + gün atlayan planlayıcı/gün dönümü düzeltmesi (`zone_day_runs`)
- [x] **Eski yollar:** uygulama mağazada olmadığı için önek'siz yollar lansmandan önce kaldırıldı.
- [ ] **Üretim kurulumu:** üretim ortamı, gizli bilgiler, alan adları, ilk seed, smoke testleri.
- [ ] **Lansman:** Kademeli açılış (önce TestFlight / iç test, sonra %10 → %100). İlk 72 saat yoğun izleme.

### Kabul kriterleri
- Pentest'te kritik veya yüksek seviye bulgu kalmamıştır.
- Yük testinde SLO'lar sağlanır. 5xx oranı < %0.1.
- Geri yükleme tatbikatı belgelenmiştir (RTO < 2 sa; RPO cPanel'de ≤ 1 sa, < 5 dk için PITR'li yönetilen DB gerekir).
- **M4:** Mağaza yayını.

---

## 2. Risk kaydı

| Risk | Olasılık | Etki | Önlem |
|---|---|---|---|
| Apple/Google giriş entegrasyonu ve misafir birleştirme karmaşıklığı | Orta | Yüksek | F1'de erken yapılır, entegrasyon testleri gerçek sandbox token'larıyla |
| Saat dilimi / DST hataları (seri, su, hafta) | Yüksek | Orta | Saf kural fonksiyonları + DST test vakaları. Her kayıtta `local_date` + `tz` |
| AI maliyetinin kontrolden çıkması | Orta | Yüksek | Kotalar, global bütçe sigortası, effort ayarı, prompt cache, kullanıcı başı maliyet izleme |
| AI'nın tehlikeli sağlık tavsiyesi vermesi | Düşük | Çok yüksek | Persona korkulukları, red-team seti, acil durum sınıflandırıcısı, refusal yönetimi |
| Fotoğraf analizi doğruluğu düşük | Orta | Orta | Eval seti, düzenlenebilir sonuç, "tahmini" ibaresi, güven skoru |
| İstemci ve sunucu enum/sözleşme uyumsuzluğu | Yüksek | Orta | OpenAPI'den Dart model üretimi (ileride), sözleşme testleri, enum eşleme tablosu |
| KVKK/sağlık verisi uyumsuzluğu | Orta | Çok yüksek | Rıza akışı F1'de. Hukuk danışmanlığı F10 öncesinde |
| Bildirim yorgunluğu → kaldırma | Orta | Orta | Frekans sınırı, sessiz saatler, kategori anahtarları, yeni kullanıcı sessizliği |
| Push teslim edilememesi (iOS izinleri) | Orta | Düşük | Inbox her zaman kalıcı. İzin isteği değer anlatan bir ekrandan sonra |
| Tek geliştiricide kritik yol tıkanması | Orta | Yüksek | 2 geliştirici planı, F2/F4/F5 paralelleştirilebilir |

## 3. Lansman sonrası (V2 adayları)

- Seri dondurma (premium), rozetler/başarımlar, arkadaş ve davet sistemi (referral linki, Share App).
- Sohbette salt-okunur araçlarla veri sorgulama ve aksiyon kartları.
- İstatistiksel açlık tahmin modeli (Fast Forecast v1).
- HealthKit / Health Connect derin entegrasyon (kilo, uyku, adım çift yönlü).
- OpenAPI'den otomatik Dart istemcisi üretimi.
- Büyük tablolar için partition ve arşivleme (> 200 bin aktif kullanıcı).
- Web hesap paneli (abonelik dışı ayarlar, veri dışa aktarma).
