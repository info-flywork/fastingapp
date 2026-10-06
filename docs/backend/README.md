# MochiFast Backend — Analiz & Yol Haritası

> Bu klasör, MochiFast Flutter uygulamasının (`com.flywork.mochifast`) kod tabanı satır satır
> analiz edilerek hazırlanmış backend tasarımı ve geliştirme yol haritasıdır.
> Hedef: **Node.js (saf JavaScript, ESM) + MySQL 8.4 (`mysql2`) + Bunny CDN** üzerinde,
> güvenlik, cache, gözlemlenebilirlik ve KVKK/GDPR açısından üretim kalitesinde bir API.

## Belgeler

| # | Belge | İçerik |
|---|---|---|
| 01 | [Uygulama Analizi](01-uygulama-analizi.md) | 20 modülün mevcut durumu, var olan API sözleşmesi, sabit kodlanmış veri envanteri, istemci tarafı açıklar |
| 02 | [Mimari & Teknoloji](02-mimari.md) | Stack seçimi, klasör yapısı, katmanlar, kodlama standartları, hata modeli, yanıt zarfı, dağıtım topolojisi |
| 03 | [Veri Modeli (MySQL)](03-veri-modeli.md) | ER diyagramı, 68 tablonun tam DDL'i, indeksler, seed verileri, migration stratejisi |
| 04 | [API Sözleşmesi](04-api.md) | Tüm endpoint'ler: istek/yanıt şekilleri, hata kodları, sayfalama, idempotency, SSE |
| 05 | [İş Kuralları & Formüller](05-is-kurallari.md) | Oruç durum makinesi, seri (streak), vücut evreleri, açlık skoru, BMI, kalori/makro, Mochi World seviye & sağlık, XP |
| 06 | [Güvenlik & Uyumluluk](06-guvenlik.md) | Tehdit modeli, kimlik doğrulama, yetkilendirme, şifreleme, rate limit, KVKK/GDPR, App Store/Play şartları |
| 07 | [Cache & Performans](07-cache-performans.md) | Process içi cache, anahtar şeması, TTL/invalidation, HTTP cache, günlük özet tabloları, ölçekleme |
| 08 | [Medya & Bunny CDN](08-medya-bunny.md) | Yükleme hattı, storage/pull zone düzeni, imzalı URL, EXIF temizliği, varyantlar, silme |
| 09 | [Yapay Zekâ](09-yapay-zeka.md) | Coach Mochi sohbeti (SSE), fotoğraftan besin analizi, kota, güvenlik korkulukları |
| 10 | [Bildirimler](10-bildirimler.md) | FCM push, gelen kutusu, zamanlayıcı mimarisi, hatırlatıcı kuralları |
| 11 | [Abonelik (RevenueCat)](11-abonelik.md) | Webhook işleme, entitlement, premium kapıları |
| 12 | [Yol Haritası](12-yol-haritasi.md) | 12 faz, görev listeleri, kabul kriterleri, kilometre taşları, tahmini süreler |
| 13 | [Flutter Entegrasyonu](13-flutter-entegrasyonu.md) | Backend'e bağlanmak için istemcide yapılması gereken her değişiklik |
| 14 | [Açık Kararlar](14-acik-kararlar.md) | Ürün kararı gerektiren konular + önerilen varsayılanlar |

## Yönetici özeti

**Mevcut durum.** Uygulama görsel olarak büyük ölçüde tamam, fakat **neredeyse hiçbir veri kalıcı değil**:

- Oruç seansları, planlar, su, adım, uyku, öğün, açlık check-in'leri, kilo, sohbet ve bildirimler ya yerel `setState`'te ya da sabit kodlanmış değerlerde yaşıyor.
- Onboarding'in 11 adımında toplanan cevapların hiçbiri saklanmıyor ya da gönderilmiyor.
- Girişler sahte (`_fakeLogin`). Onboarding sonunda `local-onboarding-session` adında sahte bir token yazılıyor ve her API isteğinde Bearer olarak gidiyor.
- Kodda tanımlı yalnızca 4 endpoint var: `POST /auth/register`, `GET /user/me`, `PATCH /user/onboarding`, `GET /user/progress`.

**Hedef.** Uygulamanın her ekranını gerçek veriyle besleyen modüler bir monolit:

- ~120 endpoint, 14 domain modülü, ~65 tablo.
- Arka planda MySQL tabanlı iş kuyruğu (`jobs` tablosu, ayrı worker process'i): bildirim, yapay zekâ analizi, görsel işleme, günlük özetler, hesap silme.

**Temel mimari kararlar** (gerekçeleri ilgili belgelerde):

| Konu | Karar |
|---|---|
| Runtime | Node.js 24 LTS, ESM, saf JavaScript (TypeScript yok, derleme yok) |
| HTTP framework | Fastify 5 (JSON Schema doğrulama + hızlı serileştirme + pino log + plugin kapsülleme) |
| Veritabanı | MySQL 8.4 LTS, `mysql2/promise` havuzu, ORM yok; repository katmanı + yalnızca prepared statement |
| Migration | `mysql2` üzerinde çalışan, checksum'lı, sıralı SQL dosyalarından oluşan kendi migration aracımız |
| Cache / kuyruk | **Redis yok** (ADR 0005, `mochifast-backend/docs/adr/0005-redis-yok.md`). Cache: process içi LRU (API tek process). Kuyruk: MySQL `jobs` tablosu, `SKIP LOCKED` ile worker; tekrarlı işler `job_schedules` |
| Kimlik doğrulama | Apple / Google **Firebase Authentication** ile (backend Firebase ID token'ı doğrular), misafir backend'de (cihaz başına tek). Kısa ömürlü JWT (EdDSA, 15 dk) + dönen (rotating) refresh token (60 gün), yeniden kullanım tespiti |
| Medya | Bunny Storage (DE) + 2 pull zone: public (uzun cache) ve private (Token Authentication ile imzalı URL). `sharp` ile yeniden kodlama, EXIF/GPS temizliği |
| Yapay zekâ | Anthropic Claude (`@anthropic-ai/sdk`). Sohbet SSE ile akıyor, fotoğraf analizi yapılandırılmış çıktı (JSON Schema) ile dönüyor, kotalar MySQL'de (`ai_quota_daily`) |
| Push | Firebase Cloud Messaging (HTTP v1, iOS dahil) |
| Abonelik | RevenueCat webhook + REST doğrulama; `premium` entitlement'ı |
| Kimlikler | UUIDv7, `BINARY(16)` saklanır, API'de string. İstemci çevrimdışı oluşturma için kendi UUID'sini gönderebilir |
| Zaman | Her şey UTC `DATETIME(3)`. Kullanıcının IANA saat dilimi ve her kayıtta `local_date` |
| API | `/v1`. Mevcut istemci zarfı korunuyor: `{status, message, data}`. JSON anahtarları camelCase |
| Gözlemlenebilirlik | pino (yapılandırılmış log, PII redaksiyonu), Sentry, Prometheus metrikleri, OpenTelemetry (faz 11) |
| Test | Vitest + `fastify.inject` + gerçek MySQL (`TEST_MYSQL_URL`), k6 yük testi |

**Takvim (özet).** 12 faz. 1 backend geliştirici ile ~18 hafta, 2 geliştirici ile ~10–11 hafta.

| Kilometre taşı | Faz | Ne çalışır hâle gelir |
|---|---|---|
| **M1 — Çekirdek MVP** | 0–3 sonu | Giriş, onboarding, plan seçimi, gerçek oruç takibi, istatistik/seri, ana sayfa özeti |
| **M2 — Tam takip** | 4–5 sonu | Tüm takipçiler (kilo, su, adım, uyku, öğün, açlık) ve fotoğraf yükleme |
| **M3 — Akıllı & ücretli** | 6–9 sonu | Yapay zekâ, Mochi World, abonelik, bildirimler |
| **M4 — Yayın** | 10–11 sonu | Yönetim paneli API'si, sertleştirme |

Ayrıntılar: [12-yol-haritasi.md](12-yol-haritasi.md).

## Okuma sırası önerisi

1. Ürün/yönetim: 01 → 14 → 12.
2. Backend geliştirici: 02 → 03 → 04 → 05, sonra konu belgeleri (06–11).
3. Mobil geliştirici: 04 → 13.
