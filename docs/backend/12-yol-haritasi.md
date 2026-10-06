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
- [ ] `scripts/extract-translations.js`: Flutter `assets/translations/*.json` dosyalarından şu bölümleri çeker ve seed JSON'larını üretir:
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
- [ ] `GET /v1/catalog/plans`, `/plans/:code`, `/stages`, `/struggle`, `/onboarding-options`, `/faq`.
- [ ] `GET /v1/app/config` + `app_config` seed (min sürüm, özellikler, limitler, pazarlama sayıları, yasal metin sürümleri).
- [ ] `GET /v1/insights/categories`, `/articles` (FULLTEXT ngram araması), `/articles/:slug`.
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
- [ ] Migration'lar: `0003` (user_plans, plan_day_checkins), `0004_fasting.sql`, `0007_aggregates.sql` (daily_summaries, user_stats, xp_events).
- [ ] `plans.rules.js`:
  - zamanlama tercihi → yeme penceresi
  - haftalık program doğrulama (5:2 ardışık değil vb.)
  - custom aralıklar
  - premium ve sağlık kontrolleri
- [ ] `GET/PUT /v1/plans/current`, `PUT /v1/plans/days/:date`, `GET /v1/plans/history`. Onboarding'in `planCode`'u aktif plana bağlanır.
- [ ] `fasting.rules.js`:
  - durum makinesi
  - zaman aralığı kontrolleri
  - vücut evresi hesabı
  - yeme penceresi evresi
- [ ] `POST /v1/fasts` (idempotent, tek aktif, çakışma kontrolü `SELECT … FOR UPDATE`).
- [ ] `GET /v1/fasts/active` (canlı `elapsed`, `progress`, `stage`, `serverTime`; negatif cache).
- [ ] `PATCH /v1/fasts/:id`, `POST /:id/finish`, `POST /:id/cancel`, `POST /v1/fasts/manual`, `DELETE /:id`.
- [ ] `Idempotency-Key` eklentisi (MySQL `idempotency_keys` tablosu + migration, gövde hash'i kontrolü, süresi dolanları silen periyodik iş).

**Hafta 2 — Türetilmiş veriler:**
- [ ] `stats.rules.js`: seri (nötr ve zorunlu gün, %80 tolerans), sayaçlar, XP ve seviye.
- [ ] `stats.service`:
  - artımlı `daily_summaries` güncellemesi
  - `recompute(userId, fromDate)`
  - kullanıcı kilidi
- [ ] Domain olay altyapısı (`events.js`). `fast.finished` → özet, seri, XP, cache invalidation.
- [ ] `POST /finish` yanıtı: `isFirstFast`, `streak`, `xpGained`, `levelUp`.
- [ ] `GET /v1/fasts`, `/fasts/:id`, `/fasts/week`, `/fasts/stats`.
- [ ] `GET /v1/user/summary` (ana sayfa birleşik yanıtı; F4'te takipçi alanları eklenir).
- [ ] `GET /v1/user/progress` gerçek veriyle. `GET /v1/user/stats`.
- [ ] İşler:
  - `daily-rollup` (03:30 UTC doğrulama)
  - `day-rollover` (saatlik; yerel 00:05 dilimi; seri kontrolü)
  - `fast-autoclose` (72 sa)
- [ ] `POST /v1/fasts/:id/struggles` (+ `/v1/struggles`).
- [ ] Birim testleri:
  - seri senaryoları: günlük plan, 5:2, nötr gün, bugün sürüyor
  - saat dilimi değişimi
  - gece yarısını geçen oruç
  - yaz saati (DST) geçişi

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
- [ ] Migration `0006_trackers.sql`.
- [ ] **Kilo:**
  - CRUD
  - `/weights/chart` (gün/hafta/ay kovaları, dinamik Y ekseni, yerelleştirilmiş etiketler)
  - `/weights/summary` (BMI kategorisi ve bandı, ilerleme)
  - `PATCH /weights/goal`
  - bitiş ekranından kilo kaydı (`source = fasting_finish`)
- [ ] **Su:**
  - `/water/day`, `POST /water`, `DELETE /water/:id`, `/water/week`
  - hedef günü sayacı
  - `HIGH_WATER_INTAKE` uyarısı
- [ ] **Adım:**
  - `PUT /steps/:date`, `POST /steps/sync` (toplu, kaynak önceliği)
  - `GET /steps` (türetilmiş km/kcal/dk)
- [ ] **Uyku:**
  - CRUD
  - `/sleep/sync`
  - `/sleep/summary` (son gece, hedef, hafta)

**Hafta 2:**
- [ ] **Öğünler:**
  - CRUD (manuel). Aktif oruç varsa `suggestEndFast` önerisi.
  - `GET /meals?date` (zaman çizelgesi)
- [ ] **Beslenme:**
  - `nutrition.rules.js`: BMR, TDEE, kcal hedefi, makrolar, taban değerler, sağlık bayrakları
  - `/nutrition/day`, `/nutrition/week`
  - `/user/goals` içinde `computed` alanı
- [ ] **Açlık:**
  - `hunger.rules.js` (skor tablosu v1, güvenlik bayrağı)
  - `/hunger-checkins/evaluate`, CRUD, `/summary`
- [ ] Tüm takipçiler `daily_summaries`'e bağlanır (artımlı + recompute). `GET /user/summary` `today` alanı tamamlanır.
- [ ] Bildirim kutusu için `weight_update` olayı. Gerçek bildirim F9'da; şimdilik yalnızca olay yayınlanır.
- [ ] Çevrimdışı ve idempotent yazma: tüm POST'larda istemci `id` desteği ve testi.

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
- [ ] Migration `0011_media.sql`.
- [ ] Bunny hesabı kurulumu:
  - `mochifast-private` ve `mochifast-public` storage zone'ları (DE + replikasyon)
  - pull zone'lar, Token Authentication, alan adları ve TLS
  - edge kuralları
- [ ] `infra/bunny.js`: `put`, `delete`, `list(prefix)`, `purge`, `signPrivateUrl` (zaman kovalı). Test için yerel diske yazan sahte implementasyon.
- [ ] `media.service`:
  - multipart limitleri
  - magic byte kontrolü
  - `sharp` hattı: rotate, varyantlar, WebP, metadata temizliği, piksel limiti
  - SHA-256 ile yinelenen yükleme tespiti
  - blurhash
- [ ] `PUT/DELETE /v1/user/me/avatar` (senkron).
- [ ] `POST /v1/media` (`purpose = mealPhoto`) ve öğüne fotoğraf bağlama (`meals.photo_media_id`).
- [ ] Tüm yanıtlarda imzalı URL gömme yardımcısı (`media.presenter`).
- [ ] Temizlik işleri:
  - takılı `processing` kayıtları
  - öğüne bağlanmamış fotoğraflar (24 sa)
  - yumuşak silinmiş öğünlerin medyası (30 gün)
- [ ] Testler:
  - EXIF/GPS temizliği
  - dekompresyon bombası
  - HEIC/SVG/PDF reddi
  - imzalı URL formatı (Bunny'nin örnek değerleriyle doğrulama)

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
- [ ] Migration `0008_ai.sql` (analiz, sohbet, kullanım tabloları).
- [ ] `infra/anthropic.js`:
  - istemci
  - timeout'lar
  - devre kesici
  - fiyat tablosu `app_config`'den
  - `fallbacks: "default"` (beta header)
- [ ] `prompts/meal_analysis.v1.md` + Zod şeması + yerelleştirme talimatı.
- [ ] `POST /v1/meals/photo-analyses` (202) + `GET /:id`. `photo-analysis` worker işi: retry, refusal, doğrulama ([09 §3.3](09-yapay-zeka.md#33-sunucu-tarafı-doğrulama-modele-körü-körüne-güvenme)).
- [ ] Kota servisi:
  - MySQL `ai_quota_daily` (atomik `INSERT … ON DUPLICATE KEY UPDATE`, eski satırları silen periyodik iş)
  - yerel gün
  - başarısız istekte iade
  - global maliyet sigortası
  - `GET /v1/chat/quota`
- [ ] **Eval seti:** 100 öğün + 20 yemek dışı fotoğraf. `scripts/eval-meal-analysis.js` (MAPE, MAE, `isFood` doğruluğu, maliyet raporu).
- [ ] AI rıza kontrolü: `ai_processing` yoksa 403 `CONSENT_REQUIRED`.

**Hafta 2 — Coach Mochi:**
- [ ] `prompts/coach_mochi.v1.md`: persona, kapsam, sağlık korkulukları, biçim kuralları.
- [ ] Bağlam derleyici (`chat.context.js`): profil, plan, aktif oruç, bugün, son açlık sonucu, güvenlik bayrakları, giriş noktası.
- [ ] Sohbet uçları:
  - konuşma CRUD
  - mesaj listeleme (cursor)
  - pin/sil
  - geri bildirim
  - öneriler
- [ ] `POST …/messages` SSE:
  - kilit
  - kota
  - akış
  - bağlantı kopunca iptal (AbortController)
  - `interrupted` durumu
  - heartbeat
  - JSON yedek yolu
- [ ] Prompt cache: sabit sistem öneki + bağlamın birebir saklanması. `cache_read_input_tokens` metriği.
- [ ] Uzun sohbet özeti işi (40+ mesaj).
- [ ] Acil durum sinyali sınıflandırıcısı (anahtar kelime listesi, 7 dil) → `safety: "urgent"` meta verisi.
- [ ] Red-team test seti:
  - prompt enjeksiyonu
  - yeme bozukluğu senaryoları
  - 18 yaş altı
  - tıbbi doz soruları
  - 72 sa oruç isteği
  
  Beklenen davranışlar elle gözden geçirilir ve sonuçlar kaydedilir.

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
- [ ] `world_zone_thresholds` seed ([05 §7](05-is-kurallari.md#7-mochi-world)).
- [ ] `world.rules.js`: bölge seviyesi, `nextThreshold`, `ratioToNext`, `sceneLevel`, `worldProgress`, sağlık hesabı.
- [ ] `user_stats` alanlarının olaylarla beslenmesi:
  - `water_goal_days`, `meals_logged`, `best_weight_lost_kg`
  - `world_health` (gün dönümü işi + `fast.finished`)
- [ ] `GET /v1/world` (cache'li).
- [ ] Seviye atlama ve sağlık değişimi olayları (bildirimler F9'da bağlanır).
- [ ] **Challenge'lar:**
  - katalog seed
  - `GET /challenges`, `/featured`, `join`, `leave`
  - olaylarla ilerleme güncellemesi
  - tamamlanma + XP
  - süresi dolanlar için saatlik iş
  - gerçek katılımcı sayısı ve izinli avatarlar
- [ ] Seri kilometre taşı XP'leri.
- [ ] (Opsiyonel) **Fast Forecast v0** (kural tabanlı): son 14 günün struggle olayları ve açlık check-in saatlerinden açlık zirvesi ve risk aralığı. Veri yetersizse `null` döner.
- [ ] (Opsiyonel) **Günlük ipucu:** Batches API ile gece üretim → `GET /fasts/daily-tip` (premium).

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
- [ ] Migration `0010_subscriptions.sql`.
- [ ] RevenueCat projesi:
  - entitlement `premium`
  - ürünler ve offering
  - webhook URL'si + auth değeri
  - sandbox ve production ayrımı
- [ ] `POST /v1/webhooks/revenuecat`: auth, idempotency, kuyruk.
- [ ] `revenuecat-event` işi: REST teyidi, durum eşlemesi, TRANSFER, cache invalidation, audit.
- [ ] `GET /v1/subscription`, `POST /v1/subscription/sync`.
- [ ] `requirePremium` ve entitlement cache'i. Bağlanacak yerler:
  - premium planlar (402)
  - AI kotaları (premium limitleri)
  - premium içerik
  - challenge'lar
- [ ] Premium kaybı akışı: planın düşürülmesi, bildirim olayı.
- [ ] Admin promosyon premium işlemi (API; panel F10'da).

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
- [ ] Migration `0009_notifications.sql`. Şablon seed'i (7 dil; yeni metinler çevrilecek).
- [ ] Firebase projeleri (staging ve prod). `infra/fcm.js` (`sendEach`, geçersiz token temizliği).
- [ ] `notifications.service`:
  - `schedule`, `cancel`, `createInbox`
  - şablon render (yer tutucular, `Intl`)
- [ ] `notification-dispatch` işi: 30 sn, `SKIP LOCKED`, 500'lük partiler.
- [ ] `push-send` işi:
  - ayar, rıza ve sessiz saat kontrolü
  - frekans sınırı
  - inbox ve push
  - retry
- [ ] Olay bağlamaları:
  - oruç: hedef, yarı yol, evre, overdue
  - yeme penceresi
  - kilo
  - seri: dürtme, kilometre taşı, kayıp
  - dünya
  - challenge
  - abonelik
  - dışa aktarma
- [ ] Günlük planlama işleri: su slotları, kilo hatırlatması, seri dürtmesi (yerel saat dilimine göre).
- [ ] Inbox uçları: liste, okunmamış sayısı, okundu, tümü okundu, sil.
- [ ] (Opsiyonel) widget yenilemesi için sessiz push.

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
- [ ] Migration `0012_compliance_admin.sql`.
- [ ] **Hesap silme:**
  - `DELETE /v1/user/me`, `POST /v1/user/me/restore`
  - `account-delete` işi: Apple revoke, Bunny önek silme ve purge, RevenueCat silme, cascade, audit anonimleştirme
  - Play Store için web silme sayfası (basit form → aynı akış, e-posta/giriş doğrulaması ile)
- [ ] **Veri dışa aktarma:** `POST /v1/user/me/export` → zip (JSON + CSV + fotoğraflar) → private zone → bildirim.
- [ ] **Rıza yönetimi:**
  - yasal metin sürümü değişince yeniden onay (`app/config.legal`)
  - rıza geri çekme davranışları
- [ ] **Saklama (retention) işleri:**
  - inaktif misafir
  - yumuşak silinenler
  - eski bildirimler
  - `push_deliveries`
  - audit
- [ ] **Admin API:**
  - kimlik doğrulama: argon2id, TOTP, kilitleme
  - RBAC, IP allowlist
  - içerik CRUD + çeviriler: planlar, evreler, struggle, insights, FAQ, öneriler, challenge'lar, şablonlar
  - `app_config` düzenleme + `cat:version` artırma
  - medya yükleme (public)
  - kullanıcı arama (maskeli) ve destek işlemleri
  - raporlar: DAU/MAU, kayıt hunisi, oruç tamamlama, AI maliyeti, premium dönüşümü
- [ ] **Ürün analitiği (opsiyonel):** Sunucu tarafı olaylar (anonim ID ile) PostHog/Amplitude'a gönderilir. Rıza kontrolü yapılır.
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
  - OWASP ASVS L2 kontrol listesi
  - harici pentest (API + mobil)
  - bulguların kapatılması
- [ ] **Yük testi (k6):**
  - sabah zirvesi senaryosu, 500 rps
  - hedefler: [07 §8.1](07-cache-performans.md#81-performans-hedefleri-slo)
  - darboğaz analizi: havuz, indeks, cache isabet oranı
- [ ] **Gözlemlenebilirlik:**
  - OpenTelemetry tracing
  - dashboard'lar: HTTP, DB, cache (hit/miss/evict), kuyruk (`jobs` durum sayıları), AI, push
  - alarmlar ve nöbet (on-call) runbook'ları
- [ ] **Yedekleme:**
  - PITR doğrulaması
  - **geri yükleme tatbikatı** (staging'e üretim yedeği, maskeli)
- [ ] **Read replica:** Raporlama ve gece işleri için.
- [ ] **WAF/CDN önü:** Bunny Shield veya Cloudflare.
- [ ] **Uyumluluk:**
  - KVKK: aydınlatma metni, açık rıza metinleri, VERBİS, yurt dışı aktarım sözleşmeleri
  - DPA'lar: Bunny, Anthropic, Google, RevenueCat, Sentry
  - App Store: Privacy Nutrition Label, hesap silme
  - Play Store: Data Safety, silme URL'si
- [ ] **Runbook'lar:**
  - olay müdahalesi
  - anahtar rotasyonu (JWT, alan şifreleme, Bunny, Anthropic)
  - kötü deploy geri alma
  - DB migration geri dönüşü
  - AI maliyet patlaması
- [ ] **Eski yolların takvimi:** prefix'siz yollar ve `PATCH /user/onboarding` için kaldırma takvimi + minimum sürüm.
- [ ] **Üretim kurulumu:** üretim ortamı, gizli bilgiler, alan adları, ilk seed, smoke testleri.
- [ ] **Lansman:** Kademeli açılış (önce TestFlight / iç test, sonra %10 → %100). İlk 72 saat yoğun izleme.

### Kabul kriterleri
- Pentest'te kritik veya yüksek seviye bulgu kalmamıştır.
- Yük testinde SLO'lar sağlanır. 5xx oranı < %0.1.
- Geri yükleme tatbikatı belgelenmiştir (RTO < 2 sa, RPO < 5 dk).
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
