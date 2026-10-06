# 02 — Mimari & Teknoloji

## 1. Teknoloji yığını

| Alan | Seçim | Neden |
|---|---|---|
| Runtime | **Node.js 24 LTS** | Ekim 2026 itibarıyla aktif LTS. Yerleşik `fetch`, `node:test`, `--env-file`, `AbortSignal.timeout` |
| Dil | **Saf JavaScript, ESM** (`"type": "module"`) | İstenen bu. TypeScript ve tip denetimi yok; güvence ESLint, JSON Schema doğrulaması ve testlerden gelir. Derleme adımı yok |
| HTTP | **Fastify 5** | JSON Schema ile doğrulama (ajv) ve yanıt serileştirme (fast-json-stringify). Yanıt şeması aynı zamanda **istenmeyen alan sızıntısını engeller**. pino log yerleşik, plugin kapsülleme ile modüler monolit, `inject()` ile hızlı test |
| DB sürücüsü | **mysql2/promise** | İstenen bu. `pool.execute()` ile sunucu tarafı prepared statement |
| DB | **MySQL 8.4 LTS**, InnoDB, `utf8mb4_0900_ai_ci` | CTE, window function, `SKIP LOCKED`, generated column, `JSON` |
| Cache | **Process içi LRU** (`src/infra/cache.js`) | TTL + jitter, single-flight. API tek process olduğu için invalidation anında ve tutarlı. **Redis yok:** ADR 0005 (`mochifast-backend/docs/adr/0005-redis-yok.md`) |
| Kuyruk | **MySQL `jobs` tablosu** (`src/infra/queue.js`) | Gecikmeli/tekrarlı işler, retry/backoff, `SKIP LOCKED` ile ayrı worker process. İş, iş verisiyle aynı transaction'da kuyruğa atılabilir |
| Doğrulama | Fastify JSON Schema (ajv, `allErrors:false`, `removeAdditional:false`) + `@fastify/type-provider-json-schema-to-ts` gereksiz (JS) | Tek kaynak: aynı şemalar OpenAPI'ye dönüşüyor |
| Auth | `jose` | JWT imzalama (EdDSA), Firebase ID token doğrulama (securetoken JWKS, `createRemoteJWKSet`, cache'li) |
| Görsel | `sharp` + `file-type` | Yeniden kodlama, EXIF temizleme, yeniden boyutlandırma, magic-byte kontrolü |
| Zaman | `luxon` | IANA saat dilimi ile `local_date` hesaplama |
| UUID | `uuid` (v7) | Zaman sıralı birincil anahtarlar |
| AI | `@anthropic-ai/sdk` | Claude: sohbet (stream), görüntü analizi (yapılandırılmış çıktı) |
| Push | `firebase-admin` | FCM HTTP v1 (iOS dahil) |
| Hata takibi | `@sentry/node` | Release ve ortam etiketli istisnalar |
| Metrik | `prom-client` | `/metrics` (yalnızca iç ağ) |
| İzleme | OpenTelemetry (faz 11) | HTTP ve mysql2 enstrümantasyonu |
| Fastify eklentileri | `@fastify/helmet`, `@fastify/cors`, `@fastify/rate-limit`, `@fastify/multipart`, `@fastify/swagger`, `@fastify/swagger-ui` (yalnızca dev/staging), `@fastify/under-pressure`, `@fastify/etag`, `@fastify/sensible` | |
| Test | Vitest (gerçek MySQL: `TEST_MYSQL_URL`), k6 | |
| Kalite | ESLint (flat config), Prettier, husky + lint-staged, commitlint (Conventional Commits) | |
| Süreç yönetimi | PM2: `api` (tek process, fork modu), `worker` (kuyruk + tekrarlı iş zamanlayıcısı); `migrate` deploy adımı | Docker kullanılmıyor |

### Bilinçli olarak kullanmadıklarımız

- **ORM yok** (Sequelize/Prisma/TypeORM). İstenen `mysql2`. Repository katmanı ile SQL bilinçli ve görünür.
- **Express yok.** Fastify'ın şema tabanlı doğrulama ve serileştirmesi güvenlik ve performans için daha uygun.
- **GraphQL yok.** Mobil ekranlara özel "özet" endpoint'leri ile REST yeterli.

## 2. Süreçler (process) ve dağıtım topolojisi

```
                 ┌──────────────────────── Bunny CDN ────────────────────────┐
                 │ cdn.mochifast.app (public)   media.mochifast.app (signed)  │
                 └────────────▲───────────────────────────▲──────────────────┘
                              │                           │ (imzalı URL)
Mobil uygulama ──HTTPS──► Nginx (TLS: certbot, HSTS, gzip)
                              │
                 ┌────────────┴─────────────┐
                 │ api (1 process, PM2)     │  Fastify, process içi cache
                 └────────────┬─────────────┘   ve rate limit
             ┌────────────────┼────────────────┐
             ▼                ▼                ▼
        MySQL 8.4        Bunny Storage    Anthropic / FCM /
        (iş verisi +     (DE)             RevenueCat / Apple /
         jobs kuyruğu)                    Google
             ▲
             │ SELECT … FOR UPDATE SKIP LOCKED
        ┌────┴─────────────────────┐
        │ worker (PM2)             │  kuyruk tüketicileri +
        │                          │  tekrarlı iş zamanlayıcısı
        └──────────────────────────┘
   (api, worker ve MySQL aynı VPS'te; uygulama 127.0.0.1'de dinler)
```

| Process | Giriş noktası | Görev |
|---|---|---|
| `api` | `src/server.js` | HTTP API. Uzun işleri kuyruğa atar |
| `worker` | `src/worker.js` | Kuyruk tüketicileri: görsel işleme, AI analizi, push gönderimi, webhook işleme, hesap silme, dışa aktarma. Ayrıca **tekrarlı işleri** çalıştırır: tanımlar `src/schedules.js` içinde (bildirim dispatcher 30 sn, saat dilimi tabanlı günlük işler saatlik, temizlikler), durum `job_schedules` tablosunda. Ayrı bir zamanlayıcı süreci yok |
| `migrate` | `scripts/migrate.js` | Tek seferlik deploy adımı (sürekli süreç değil) |

Hepsi **aynı kod tabanından** çalışıyor. Sadece komut farklı.

- **API tek process** (PM2 fork modu) çalışır. Cache ve rate limit sayaçları process belleğinde tutulduğu için bu bir ön koşuldur (ADR 0005).
- **İş kuyruğu:** API ve service'ler `jobs.enqueue(queue, name, payload, { delayMs, maxAttempts, dedupeKey, conn })` çağırır. `conn` verilirse iş, iş verisiyle **aynı transaction'da** kuyruğa girer (iş kaybı yok). Worker `SELECT … FOR UPDATE SKIP LOCKED` ile iş kapar (`WORKER_CONCURRENCY`, varsayılan 5; boş kuyrukta `WORKER_POLL_MS`, varsayılan 1000 ms aralıkla bakar). Hata → üstel geri çekilmeyle yeniden deneme (taban 2 sn, her seferde iki katı, en fazla 10 dk, ≤%20 jitter), varsayılan `maxAttempts` 5. Sonra `failed` + `last_error`. Çöken worker'ın işi `locked_until` dolunca kuyruğa döner (en az bir kez teslim → handler'lar idempotent olmalı). `dedupeKey` (kuyruk başına tekil) aynı mantıksal işin iki kez atılmasını engeller. Biten işler 7 gün, başarısızlar 30 gün saklanır; saatlik `system-jobs-cleanup` temizler.
- **Tekrarlı işler:** Worker açılışta `job_schedules` tablosunu `src/schedules.js` tanımlarıyla eşitler ve her saniye vadesi gelenleri kuyruğa atar. Birden çok worker ile güvenlidir (`SKIP LOCKED` + `next_run_at` aynı transaction'da ilerletilir).

**Ortamlar:**

| Ortam | Kullanım |
|---|---|
| `local` | Yerel MySQL 8 (ör. Homebrew) |
| `staging` | Üretimin küçük kopyası. RevenueCat sandbox, Bunny ayrı zone'lar |
| `production` | Canlı ortam |

**Barındırma önerisi:** AB bölgesi (Frankfurt), KVKK/GDPR ve Bunny DE storage ile yakınlık için. Seçenekler:
- Tek VPS: Nginx (TLS, certbot) → `127.0.0.1` üzerinde PM2 ile `api` + `worker`, MySQL aynı sunucuda. Redis ve Docker yok.
- Deploy: `npm run deploy` (rsync → `npm ci --omit=dev` → migrate → `pm2 startOrReload` → `/health/ready` kontrolü).

## 3. Proje (repo) yapısı

Ayrı bir repo önerilir: `mochifast-backend`.

```
mochifast-backend/
├── package.json                 # "type": "module", engines.node >= 24
├── eslint.config.js
├── .env.example                 # tüm değişkenler, açıklamalı (gerçek değer yok)
├── migrations/                  # 0001_create_jobs.sql, 0002_...sql (yalnızca ileri)
├── seeds/                       # plans.json, body_stages.json, insights/*.json, faq.json ...
├── scripts/
│   ├── migrate.js               # migration runner (mysql2)
│   ├── seed.js
│   └── create-admin.js
├── src/
│   ├── server.js                # api giriş noktası (graceful shutdown)
│   ├── worker.js                # kuyruk tüketicisi + tekrarlı iş zamanlayıcısı
│   ├── schedules.js             # tekrarlı iş tanımları ({ id, queue, jobName, everyMs })
│   ├── app.js                   # buildApp(): plugin & modül kaydı (testte de kullanılır)
│   ├── config/
│   │   ├── index.js             # env okuma + şema doğrulama (başlangıçta fail-fast)
│   │   └── constants.js         # enum listeleri, limitler
│   ├── infra/                   # dış dünya adaptörleri (iş mantığı yok)
│   │   ├── db.js                # mysql2 pool, withTransaction(), query helpers
│   │   ├── queue.js             # MySQL iş kuyruğu (enqueue, worker) + tekrarlı iş zamanlayıcısı
│   │   ├── cache.js             # process içi LRU: get/set/del/delPrefix/getOrSet (single-flight)
│   │   ├── bunny.js             # storage PUT/DELETE, purge, signUrl
│   │   ├── anthropic.js         # Claude istemcisi
│   │   ├── fcm.js
│   │   ├── revenuecat.js
│   │   ├── firebase-auth.js     # Firebase ID token doğrulama
│   │   ├── logger.js            # pino ayarları, redaction
│   │   └── crypto.js            # AES-256-GCM alan şifreleme, hash yardımcıları
│   ├── plugins/                 # fastify eklentileri
│   │   ├── auth.js              # request.user, requireAuth, requirePremium
│   │   ├── errors.js            # hata → zarf eşlemesi
│   │   ├── envelope.js          # {status,message,data} sarmalama
│   │   ├── idempotency.js
│   │   ├── request-context.js   # requestId, locale, timezone, appVersion
│   │   ├── rate-limit.js
│   │   └── swagger.js
│   ├── shared/
│   │   ├── errors.js            # AppError sınıfları + kod kataloğu
│   │   ├── ids.js               # uuidv7, toBin/fromBin
│   │   ├── time.js              # localDate(tz, instant), week ranges
│   │   ├── i18n.js              # sunucu tarafı şablon çevirileri
│   │   ├── pagination.js        # cursor encode/decode
│   │   └── schemas.js           # ortak JSON schema parçaları
│   ├── modules/                 # domain modülleri (her biri aynı iç yapıda)
│   │   ├── auth/
│   │   │   ├── auth.routes.js       # route tanımları + şemalar
│   │   │   ├── auth.schemas.js
│   │   │   ├── auth.service.js      # iş mantığı (transaction sınırları burada)
│   │   │   ├── auth.repository.js   # yalnızca SQL
│   │   │   └── auth.test.js
│   │   ├── users/  profile/  devices/  catalog/  plans/  fasting/  stats/
│   │   ├── weight/  water/  steps/  sleep/  meals/  nutrition/  hunger/
│   │   ├── media/  ai/  chat/  world/  challenges/  insights/
│   │   ├── notifications/  subscriptions/  admin/  compliance/
│   └── jobs/                    # iş handler'ları (jobs kuyruğu)
│       ├── image-process.job.js
│       ├── photo-analysis.job.js
│       ├── push-send.job.js
│       ├── notification-dispatch.job.js
│       ├── daily-rollup.job.js
│       ├── streak-check.job.js
│       ├── revenuecat-event.job.js
│       ├── account-delete.job.js
│       └── data-export.job.js
└── test/
    ├── setup/                   # test altyapısı (TEST_MYSQL_URL), fixture'lar
    ├── integration/
    └── load/                    # k6 senaryoları
```

### 3.1 Katman kuralları

```
route  ──►  service  ──►  repository  ──►  mysql2
  │            │
  │            ├──► başka modülün service'i (asla repository'si değil)
  │            ├──► infra (cache, queue, bunny, anthropic…)
  │            └──► domain olayı yayınla (events bus, process içi)
  └──► yalnızca: şema, auth kancası, service çağrısı, yanıt
```

- **Route:** HTTP'ye özgü her şey (şema, durum kodu, header). İş mantığı içermez.
- **Service:** iş kuralları, yetki kontrolü (sahiplik), transaction sınırı, cache invalidation, olay yayınlama.
- **Repository:** yalnızca SQL. Parametreli `execute`. Satırları domain nesnesine çevirme (`BINARY(16)` → string UUID, `DECIMAL` → number).
- Modüller arası erişim **service üzerinden**. Bir modül başka bir modülün tablosuna doğrudan SQL atmaz. İstisna: raporlama/rollup işleri, okuma amaçlı.
- **Domain olayları** (process içi `EventEmitter` sarmalayıcısı, ağır işler kuyruğa):

  | Olay | Yan etkileri |
  |---|---|
  | `fast.started` | bildirim planla |
  | `fast.finished` | rollup, seri, dünya, challenge, XP, bildirim iptal/planlama |
  | `weight.logged` | özet, dünya (zirve), bildirim kutusu |
  | `meal.logged` | özet, dünya (bahçe), challenge |
  | `water.logged` | özet, su hedefi günü, dünya (göl) |
  | `user.deleted` | silme işi |

### 3.2 Veritabanı erişim standartları

```js
// src/infra/db.js (özet)
import mysql from 'mysql2/promise';

export const pool = mysql.createPool({
  host, port, user, password, database,
  connectionLimit: 20,           // process başına; MySQL max_connections'a göre ayarla
  waitForConnections: true,
  queueLimit: 0,
  enableKeepAlive: true,
  timezone: 'Z',                 // tüm DATETIME'lar UTC
  dateStrings: false,
  decimalNumbers: true,          // DECIMAL → number (kilo, makro)
  supportBigNumbers: true,
  namedPlaceholders: true,
  charset: 'utf8mb4_0900_ai_ci',
  ssl: config.db.ssl,            // üretimde zorunlu
  multipleStatements: false,     // SQL enjeksiyon yüzeyini daralt (migration runner ayrı bağlantı kullanır)
});

export async function withTransaction(fn) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const result = await fn(conn);
    await conn.commit();
    return result;
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
}
```

**Kurallar:**
- Kullanıcı girdisi **her zaman** placeholder ile geçer. ESLint kuralı (custom `no-restricted-syntax`), SQL içinde `${}` interpolasyonu olan template literal'i yasaklar. Dinamik `ORDER BY`/kolon adı gerekirse **whitelist** sözlüğünden seçilir.
- Kullanıcıya ait her sorgu `WHERE user_id = :userId` içerir (IDOR koruması). Repository fonksiyon imzaları `userId`'yi zorunlu ilk parametre olarak alır.
- Okuma ağırlıklı ve gecikme toleranslı sorgular (istatistik, grafik) `replicaPool`'a gidebilir (faz 11).
- Yavaş sorgu logu açık (>200 ms). `EXPLAIN` incelemesi PR şablonunda var.
- `SELECT *` yasak. Kolonlar açıkça yazılır.

### 3.3 Migration aracı (mysql2 tabanlı)

- `migrations/NNNN_aciklama.sql`, yalnızca ileri yönlü. Geri dönüş yeni bir migration ile yapılır.
- `schema_migrations(version, name, checksum, applied_at, duration_ms)` tablosu.
- Runner:
  1. `GET_LOCK('schema_migrations', 60)` ile eşzamanlı çalışmayı engeller.
  2. Uygulanmış dosyaların checksum'ını doğrular. Değişmişse **hata** verir.
  3. Bekleyenleri sırayla uygular. Her dosya bir transaction'dır (DDL otomatik commit ettiği için dosyalar küçük ve tek amaçlı tutulur).
- Büyük tablolarda DDL: `ALGORITHM=INSTANT/INPLACE, LOCK=NONE`. Gerekirse `gh-ost`/`pt-online-schema-change` (lansman sonrası).
- CI'da: boş DB'ye tüm migration'lar → seed → testler.

### 3.4 Kimlik (ID) stratejisi

- **Kullanıcı verisi tabloları:** `id BINARY(16)` = UUIDv7. Zaman sıralı olduğu için B-tree dostu.
- **API'de** standart string UUID. Dönüşüm `shared/ids.js` içinde (`uuid.parse` / `uuid.stringify`).
- **İstemci ID üretebilir** (`POST /v1/water {id, …}`). Sunucu ID'nin geçerli bir UUIDv7 olduğunu ve zaman bileşeninin makul olduğunu (±7 gün) doğrular. Böylece çevrimdışı kuyruk ve yeniden denemeler **doğal olarak idempotent** olur (`INSERT … ON DUPLICATE KEY` yerine `INSERT IGNORE` + sahiplik kontrolü).
- **Katalog tabloları** (plan, evre, kategori): `SMALLINT UNSIGNED AUTO_INCREMENT` + kararlı `code`/`slug`. API'de **her zaman `code`** kullanılır.

### 3.5 Zaman & saat dilimi

- Tüm anlık zamanlar `DATETIME(3)` olarak **UTC** saklanır. API'de ISO-8601 (`2026-10-06T08:15:00.000Z`).
- `users.timezone` (IANA, ör. `Europe/Istanbul`) her istekteki `X-Timezone` header'ı ile güncellenir. Değişim loglanır.
- **Her takip kaydı** iki ek alan taşır:
  - `local_date`: kaydın yapıldığı andaki kullanıcı saat dilimine göre hesaplanmış gün.
  - `tz`: kaydın saat dilimi.

  Kullanıcı seyahat ettiğinde geçmiş günler yeniden hesaplanmaz.
- **Hafta Pazartesi başlar** (istemci ile uyumlu).
- "Bugün" = `localDate(user.timezone, now)`.

### 3.6 Konfigürasyon

`src/config/index.js`, başlangıçta tüm ortam değişkenlerini JSON Schema ile doğrular. Eksik veya hatalı değer varsa process **başlamaz**. `.env.example`:

```
NODE_ENV=production
PORT=3000
PUBLIC_BASE_URL=https://api.mochifast.app
TRUST_PROXY=true

DB_HOST= DB_PORT=3306 DB_USER= DB_PASSWORD= DB_NAME=mochifast DB_SSL=true DB_POOL_SIZE=20
DB_REPLICA_HOST=

CACHE_MAX_ENTRIES=10000     # process içi LRU cache'in en fazla anahtar sayısı
WORKER_CONCURRENCY=5        # worker'ın aynı anda çalıştırdığı iş sayısı
WORKER_POLL_MS=1000         # boş kuyrukta jobs tablosuna bakma aralığı

JWT_PRIVATE_KEY_PEM=        # Ed25519, base64
JWT_PUBLIC_KEYS_JSON=       # kid → public key (anahtar rotasyonu)
JWT_ACCESS_TTL=900          # sn
REFRESH_TTL_DAYS=60

FIREBASE_PROJECT_ID=        # Firebase Console → Project settings
FIREBASE_SIGN_IN_PROVIDERS=apple.com,google.com

FIELD_ENCRYPTION_KEYS_JSON= # {"k1":"base64-32byte"} — aktif anahtar FIELD_ENCRYPTION_ACTIVE_KID
FIELD_ENCRYPTION_ACTIVE_KID=k1

BUNNY_STORAGE_ZONE_PRIVATE= BUNNY_STORAGE_KEY_PRIVATE= BUNNY_STORAGE_HOST=storage.bunnycdn.com
BUNNY_STORAGE_ZONE_PUBLIC=  BUNNY_STORAGE_KEY_PUBLIC=
BUNNY_PULL_PRIVATE_HOST=media.mochifast.app BUNNY_PULL_PRIVATE_TOKEN_KEY=
BUNNY_PULL_PUBLIC_HOST=cdn.mochifast.app
BUNNY_API_KEY=              # purge için (hesap API anahtarı)

ANTHROPIC_API_KEY=
AI_CHAT_MODEL=claude-opus-5-5
AI_VISION_MODEL=claude-opus-5-5

FCM_SERVICE_ACCOUNT_JSON=   # base64
REVENUECAT_SECRET_API_KEY= REVENUECAT_WEBHOOK_AUTH=
SENTRY_DSN=
ADMIN_ALLOWED_ORIGINS=https://admin.mochifast.app
```

Üretimde gizli değerler bir **secret manager** üzerinden enjekte edilir (platformun secret'ları / Doppler / AWS Secrets Manager). Repoda gerçek değer bulunmaz.

## 4. HTTP sözleşme standartları

### 4.1 Yanıt zarfı (mevcut istemciyle uyumlu)

```jsonc
// Başarılı
{ "status": "success", "message": "OK", "data": { /* nesne */ } }

// Liste (data HER ZAMAN nesne)
{ "status": "success", "message": "OK",
  "data": { "items": [ ... ], "pageInfo": { "nextCursor": "eyJ...", "hasMore": true } } }

// Hata
{ "status": "error", "message": "Bu plan Premium gerektiriyor.",
  "error": { "code": "PREMIUM_REQUIRED", "details": { "planCode": "20_4" }, "requestId": "01J…" } }
```

- `message`, `Accept-Language`'e göre yerelleştirilmiş, kullanıcıya gösterilebilir bir metindir.
- `error.code` makine tarafından okunur ve kararlıdır. İstemci mantığı **yalnızca koda** bakar.
- HTTP durum kodları anlamlıdır: 200/201/202/204, 400, 401, 402 (premium), 403, 404, 409, 410, 413, 415, 422, 429, 500, 503.

### 4.2 Hata kodu kataloğu (`shared/errors.js`)

| Kod | HTTP | Anlam |
|---|---|---|
| `VALIDATION_FAILED` | 400 | Şema ihlali (`details.fields[]`) |
| `UNAUTHENTICATED` | 401 | Token yok veya geçersiz |
| `TOKEN_EXPIRED` | 401 | Access token süresi doldu → istemci refresh eder |
| `REFRESH_REUSED` | 401 | Refresh token yeniden kullanıldı → tüm aile iptal, yeniden giriş |
| `PREMIUM_REQUIRED` | 402 | Entitlement gerekli |
| `FORBIDDEN` | 403 | Yetki yok |
| `NOT_FOUND` | 404 | Kayıt yok veya başkasına ait (aynı yanıt, sızıntı yok) |
| `CONFLICT` | 409 | Ör. zaten aktif oruç var (`ACTIVE_FAST_EXISTS`) |
| `FAST_OVERLAP` | 409 | Seans zaman aralıkları çakışıyor |
| `IDEMPOTENCY_KEY_REUSED` | 409 | Aynı anahtar farklı gövdeyle |
| `ACCOUNT_LINK_CONFLICT` | 409 | Sosyal hesap başka kullanıcıya bağlı |
| `GONE` | 410 | Silinmiş hesap |
| `PAYLOAD_TOO_LARGE` | 413 | |
| `UNSUPPORTED_MEDIA_TYPE` | 415 | |
| `NOT_FOOD` | 422 | Fotoğraf analizi: yemek tespit edilmedi |
| `UNSAFE_REQUEST` | 422 | Sağlık güvenliği kuralı (ör. 18 yaş altı ileri plan) |
| `QUOTA_EXCEEDED` | 429 | AI kotası (`details.resetAt`) |
| `RATE_LIMITED` | 429 | `Retry-After` header'ı |
| `APP_UPDATE_REQUIRED` | 426 | `X-App-Version` minimum sürümün altında |
| `INTERNAL` | 500 | Detay asla sızdırılmaz, `requestId` döner |
| `UNAVAILABLE` | 503 | Bakım veya aşırı yük (`under-pressure`) |

### 4.3 Standart istek header'ları

| Header | Zorunlu | Amaç |
|---|---|---|
| `Authorization: Bearer <jwt>` | Korumalı uçlar | |
| `Accept-Language` | Evet | Uygulamada seçilen dil (`en`, `tr`, `de`, `fr`, `es`, `it`, `ru`). Yedek: `en` |
| `X-Timezone` | Evet | IANA saat dilimi |
| `X-App-Version` | Evet | Semver. Minimum sürüm kontrolü ve uyumluluk |
| `X-Platform` | Evet | `ios` \| `android` |
| `X-Install-Id` | Evet | Uygulama kurulumu başına UUID (cihaz kimliği) |
| `Idempotency-Key` | POST'larda önerilir | UUID. Sunucu 24 saat saklar |
| `X-Request-Id` | Hayır | Yoksa sunucu üretir ve yanıtta döner |

### 4.4 Sayfalama, filtre, sıralama

- **Cursor tabanlı:** `?limit=20&cursor=<opaque>`. Cursor `(sort_key, id)` çiftinin base64url hâlidir. Offset kullanılmaz.
- `limit` en fazla 100, varsayılan 20.
- **Tarih aralıkları:** `?from=2026-10-01&to=2026-10-07` (yerel gün, kapsayıcı) veya `?range=day|week|month`.

### 4.5 Sürümleme ve kullanımdan kaldırma

- URL ile sürüm: `/v1`. Kırıcı değişiklik `/v2` ile gelir. Eski sürüm en az 6 ay desteklenir.
- **Geçiş dönemi için eski yollar:** `/auth/register`, `/user/me`, `/user/progress` gibi önek (prefix) olmayan yollar, istemci güncellenene kadar `/v1` karşılıklarına yönlendirilir. Yanıtta `Deprecation: true` header'ı bulunur.
- Minimum sürüm zorlama: `app_config.min_app_version.{ios,android}` → 426 `APP_UPDATE_REQUIRED`.

### 4.6 OpenAPI

- Fastify şemalarından `@fastify/swagger` ile otomatik üretilir.
- `/docs` yalnızca dev/staging'de ve basic auth arkasında.
- CI'da `openapi.json` üretilip artifact olarak saklanır. İleride Dart istemci modelleri buradan üretilebilir.

## 5. Gözlemlenebilirlik

- **Log:** pino JSON. Her satırda `requestId`, `userId` (varsa), `route`, `statusCode`, `responseTimeMs`, `appVersion`, `platform`.
  - **Redaksiyon:** `req.headers.authorization`, `*.idToken`, `*.refreshToken`, `*.accessToken`, `*.notes`, `*.content`, `*.email`, `*.pushToken` ve görsel gövdeleri.
- **Metrikler:**
  - HTTP histogramları (route bazında)
  - DB havuzu: kullanımda / boşta / bekleyen
  - Cache hit/miss/evict (`cache_requests_total{result}`)
  - Kuyruk derinliği (`jobs` tablosunda duruma göre sayılar: `SELECT status, COUNT(*) FROM jobs GROUP BY status`) ve iş süreleri
  - AI token ve maliyet sayaçları
  - Push başarı/hata oranları
  - Aktif oruç sayısı
- **Sağlık uçları:**
  - `GET /health/live`: process ayakta.
  - `GET /health/ready`: yalnızca MySQL ping (kuyruk da MySQL'de). Deploy sonrası kontrol ve dış izleme bu ucu kullanır.
- **Alarmlar:** 5xx oranı >%1 (5 dk), p95 > 800 ms, DB havuz bekleme >0 (2 dk), kuyruk derinliği eşiği, AI hata oranı, webhook hataları, disk ve replikasyon gecikmesi.
- **Graceful shutdown:** `SIGTERM` gelince sırayla:
  1. Readiness false.
  2. Yeni bağlantıları reddet.
  3. Açık istekleri bitir (en fazla 25 sn), SSE akışlarını bitir.
  4. Havuzları kapat.
- **Denetim izi (audit):** Kimlik, hesap, abonelik, admin işlemleri ve veri dışa aktarma `audit_logs` tablosuna yazılır.

## 6. Kodlama standartları

- **Async hata yönetimi:** Service'ler `AppError` alt sınıfları fırlatır. Global hata eklentisi bunları zarfa çevirir. Bilinmeyen hata 500 olur ve Sentry'ye gider.
- **Saf fonksiyonlar:** İş kuralı formülleri (seri, evre, skor, BMI, dünya seviyesi) `*.rules.js` dosyalarında saf fonksiyon olarak yazılır ve %100 birim test kapsamındadır.
- **Sihirli sayı yok:** Limitler `config/constants.js`, ürün parametreleri `app_config` tablosundadır.
- **PR şablonu:**
  - Şema
  - Yetki/sahiplik testi
  - Migration gözden geçirme
  - Cache invalidation
  - Log/metrik
  - OpenAPI farkı
  - Geri alma planı
