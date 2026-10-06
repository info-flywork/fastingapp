# 07 — Cache & Performans

## 1. İlkeler

1. **Doğruluk önce gelir.** Kullanıcının kendi yazdığı veri, bir sonraki okumada **mutlaka** görünür (read-your-writes).
   - Kullanıcıya özel cache'ler yazma anında **silinir**. TTL'in dolmasını beklemek yeterli değildir.
2. **Pahalı hesaplar önceden yapılır.** Grafikler, seri, hafta şeridi ve dünya her istekte ham tablodan toplanmaz.
   - Bunların kaynağı `daily_summaries` ve `user_stats` tablolarıdır (rollup). Cache bunların önünde ince bir katmandır.
3. **Katalog içerik "neredeyse statik"tir.** Uzun TTL, sürüm anahtarı, HTTP ETag ve CDN dostu header'larla sunulur.
4. **Cache boşken de sistem doğru çalışır.** Cache process belleğindedir; deploy ve yeniden başlatmada boşalır. İlk istekler DB'den yüklenir, sadece miss metriği artar.
   - Kota MySQL'de tutulur (DB erişilemezse istek zaten başarısız olur, doğal olarak fail-closed). Rate limit sayaçları bellektedir ve yeniden başlatmada sıfırlanır (kabul edilebilir).

## 2. Cache katmanı (process içi) ve kuyruk

Redis kullanılmıyor: ADR 0005 (`mochifast-backend/docs/adr/0005-redis-yok.md`).

| Bileşen | Uygulama | İçerik |
|---|---|---|
| Cache | Process içi LRU (`src/infra/cache.js`): `get/set/del/delPrefix/getOrSet`. TTL + ≤%10 jitter, single-flight, değerler JSON olarak saklanır. En fazla `CACHE_MAX_ENTRIES` (varsayılan 10.000) anahtar; aşılınca en uzun süredir kullanılmayan atılır | §3'teki tüm anahtarlar (katalog, config, kullanıcı özetleri, entitlement, JWKS, oturum durumu) |
| Kuyruk | MySQL `jobs` + `job_schedules` tabloları (`src/infra/queue.js`, [02 §2](02-mimari.md#2-süreçler-process-ve-dağıtım-topolojisi)) | Arka plan işleri ve tekrarlı işler. MySQL yedeklerine dahil, iş kaybı yok |

- **API tek process** (PM2 fork) çalışır. Bu yüzden invalidation (`cache.del` / `cache.delPrefix`) anında ve tutarlıdır.
- Cache deploy/yeniden başlatmada boşalır. Bu kabul edilebilir: tüm değerler DB'den yeniden yüklenebilir.
- **Worker'daki yazmalar:** Cache yalnızca API process'inin belleğindedir; worker'dan `cache.del` çağırmak API cache'ini etkilemez. Worker'ın değiştirdiği veriler (RevenueCat webhook işi, gece rollup'ı, worker'ın oluşturduğu bildirimler) API'de ilgili anahtarın TTL'i dolunca görünür (ör. `ent` 5 dk, `notif:unread` 5 dk). Kullanıcının kendi yazmaları API'den geçtiği için read-your-writes ilkesi etkilenmez. Daha hızlı yansıma gerekirse API'ye yalnızca 127.0.0.1'den erişilen bir iç invalidation ucu eklenir ve worker onu çağırır.
- Metrik: `cache_requests_total{result=hit|miss|evict}`.
- **Yatay ölçek** (birden çok API process'i veya sunucu) gerekirse cache ve rate limit için paylaşımlı bir store (Redis) yeniden değerlendirilir. `cache.js` API'si async olduğu için çağıranlar değişmez.

## 3. Anahtar şeması

Biçim: `<alan>:<kapsam>:<anahtar>`. Cache process'e özel olduğu için ortam öneki gerekmez.

| Anahtar | İçerik | TTL | Invalidation |
|---|---|---|---|
| `cat:v{n}:plans:{locale}` | Plan kataloğu (kilitsiz; premium kilidi her istekte uygulanır). `n` = `app_config.catalog.version`, `npm run seed` artırır | 24 sa | Admin değişikliğinde `cat:version` artar, eski anahtarlar ölü kalıp düşer |
| `cat:v{n}:stages:{type}:{locale}` | Evreler | 24 sa | Aynı |
| `cat:v{n}:struggle:{locale}` | Zorlanma içeriği | 24 sa | Aynı |
| `cat:v{n}:insights:cats:{locale}` | Insight kategorileri | 1 sa | Aynı |
| `cat:v{n}:insights:article:{slug}:{locale}` | Makale | 1 sa | Aynı |
| `cat:v{n}:faq:{locale}` | SSS | 24 sa | Aynı |
| `cfg:app:rows` | `app_config` satırları (platform birleştirmesi istekte); katalog sürümü de buradan okunur | 60 sn | Admin güncellemesinde silinir |
| `u:{uid}:ent` | Entitlement (`isPremium`, `expiresAt`) | 5 dk | Webhook, sync |
| `u:{uid}:summary` | `GET /user/summary` yanıtı (dile bağlı alanlar hariç) | 30 sn | Aşağıdaki **olay tablosu** |
| `u:{uid}:fast:active` | Aktif oruç (veya `none`) | 10 dk | Başlat, düzenle, bitir, iptal |
| `u:{uid}:week:{mondayDate}` | Hafta şeridi | 10 dk | Oruç olayları |
| `u:{uid}:world` | Dünya yanıtı | 10 dk | Oruç, kilo, öğün, su, recompute |
| `u:{uid}:goals` | Hesaplanmış hedefler (kcal/makro) | 1 sa | Profil, kilo, hedef değişimi |
| `u:{uid}:notif:unread` | Okunmamış bildirim sayısı | 5 dk | Bildirim oluşturma, okuma |
| `sess:{uid}:{sid}` | Oturum + kullanıcı durumu (`{active, status, isGuest}`; auth kancası) | 60 sn | Çıkış, `reuse_detected`, hesap değişimi, durum değişikliği → `delPrefix('sess:{uid}:')` |
| `jwks:{provider}` | Apple/Google anahtarları | 6 sa | – |

**Cache dışında tutulan kısa ömürlü durum:**

| İhtiyaç | Yer |
|---|---|
| Rate limit sayaçları | `@fastify/rate-limit` bellek içi store ([06 §7](06-guvenlik.md#7-rate-limit--kötüye-kullanım)) |
| AI kotası | MySQL `ai_quota_daily`, kullanıcının yerel günü ([09 §4](09-yapay-zeka.md#4-kotalar)) |
| `Idempotency-Key` kayıtları | MySQL `idempotency_keys`, 24 sa; süresi dolanlar periyodik işle silinir |
| Kısa kilitler: sohbet tek akış (`chat:{conversationId}`, akış bitince), recompute tekilleştirme (`recompute:{uid}`, 30 sn), düzenleme tekilleştirme | Process içi kilit (`Map`/`Set`). API tek process olduğu için yeterli (ADR 0005) |
| Paralel refresh toleransı | Verilen yeni çift process belleğinde 10 sn tutulur ([06 §2](06-guvenlik.md#2-kimlik-doğrulama)) |

### 3.1 Olay → invalidation tablosu

| Olay | Silinen anahtarlar |
|---|---|
| Oruç başlat, düzenle, bitir, iptal, sil | `u:{uid}:fast:active`, `u:{uid}:summary`, `u:{uid}:week:*`, `u:{uid}:world` |
| Kilo kaydı | `summary`, `world`, `goals` |
| Su kaydı | `summary` (+ hedef günü değiştiyse `world`) |
| Öğün kaydı | `summary`, `world` |
| Profil / hedef değişimi | `summary`, `goals`, `auth` |
| Abonelik değişimi | `ent`, `summary` |
| Bildirim oluşturma, okuma | `notif:unread`, `summary` |

**Uygulama ayrıntıları:**
- Tüm anahtarlar `invalidateUser(uid, ['fast','summary',…])` yardımcısıyla tek bir `cache.del(...)` çağrısında silinir.
- `week:*` gibi joker silme için `cache.delPrefix('u:{uid}:week:')` kullanılır (bellek içi tarama; tek kullanıcının önekiyle sınırlı).

## 4. Cache okuma deseni

```js
// infra/cache.js — cache-aside + single-flight + jitter
// Process içi LRU; değerler JSON olarak saklanır (çağıran dönen nesneyi değiştirse de cache bozulmaz).
async getOrSet(key, ttlSec, loader) {
  const hit = read(key);                          // süresi dolmuşsa siler, null döner
  if (hit !== null) return hit;                   // metrik: hit
  return singleFlight(key, async () => {          // aynı anahtar için eşzamanlı yüklemeyi tekleştir
    const value = await loader();
    if (value != null) await this.set(key, value, ttlSec);   // set: TTL + ≤%10 jitter, LRU sınırı
    return value;
  });
}
```

- **Thundering herd koruması:**
  - Process içinde `singleFlight`. API tek process olduğu için ayrıca dağıtık kilit gerekmez.
- **Negatif cache:** Aktif oruç yoksa `"none"` değeri yazılır. Sık sorulan "aktif oruç var mı?" sorusu DB'ye gitmez.

## 5. Günlük özetler (rollup)

`daily_summaries`, kullanıcı başına gün başına **tek satırdır**. Hafta şeridi, grafikler, seri, dünya sağlığı ve challenge ilerlemesinin hepsi buradan okunur.

### 5.1 Artımlı güncelleme (yazma yolunda)

Ham kayıt yazıldıktan sonra, aynı transaction'da ilgili gün satırı atomik olarak güncellenir:

```sql
INSERT INTO daily_summaries (user_id, local_date, water_ml, water_goal_ml)
VALUES (?, ?, ?, ?)
ON DUPLICATE KEY UPDATE water_ml = water_ml + VALUES(water_ml);
```

**Neden yeniden toplama?** Silme ve düzenleme işlemlerinde artımlı güncelleme hata biriktirebilir. Bu yüzden bu işlemler artı/eksi değer uygulamaz; o günü ham tablodan **yeniden toplar** (`SUM … WHERE user_id=? AND local_date=?`). Bu tek indeksli bir sorgudur ve hızlıdır.

### 5.2 Gece doğrulama işi
- **Ne zaman:** her gece 03:30 UTC.
- **Kapsam:** son 48 saatte değişen kullanıcılar için son 3 günü yeniden hesaplar.
  - Kapsam tespiti: `users.last_active_at` (`ix_users_status_last_active`).
- **Rol:** Artımlı güncellemedeki olası sapmaların kendi kendini düzelten güvenlik ağıdır.

### 5.3 Gün dönümü işleri (saat dilimine göre)
- **Ne zaman:** saatlik iş. Yerel saati 00:05 olan saat dilimlerinin kullanıcılarını seçer: `users.timezone IN (…)`. Bu liste bellekte `luxon` ile hesaplanır.
- **Ne yapar:**
  1. Dünkü günü kapatır.
  2. Seriyi kontrol eder; bozulduysa `streak_lost` bildirimi gönderir.
  3. Dünya sağlığını günceller.
  4. Bugünün hedef anlık görüntülerini (`*_goal`) içeren boş `daily_summaries` satırını oluşturur.
- **Ölçek:** Kullanıcılar 1.000'lik gruplar halinde kuyruğa atılır.

## 6. HTTP cache

| Uç türü | Header |
|---|---|
| Katalog (oturumsuz) | `Cache-Control: public, max-age=300, stale-while-revalidate=86400`, `ETag` (yanıt gövdesinin hash'i), `Vary: Accept-Language` |
| Katalog (oturumlu, kişisel kilit bilgisi) | `Cache-Control: private, max-age=60`, `ETag` |
| Kullanıcı verisi | `Cache-Control: private, no-store` |
| Medya (public zone) | Bunny tarafında `Cache-Control: public, max-age=31536000, immutable` (dosya adları içerik-adreslidir) |
| Medya (private zone) | Bunny edge cache açık, ancak URL token'lı ve süreli. İstemciye `Cache-Control: private, max-age=3600` |

- **304 desteği:** İstemci `If-None-Match` gönderdiğinde `@fastify/etag` 304 döner. Dio'da `dio_cache_interceptor` ile katalog yanıtları yerelde cache'lenebilir ([13](13-flutter-entegrasyonu.md)).
- **Sıkıştırma:** Ters proxy katmanında yapılır (Caddy/Nginx: br/gzip, > 1 KB). Node process'i sıkıştırma ile meşgul edilmez.

## 7. Veritabanı performansı

- **Bağlantı havuzu:**
  - `connectionLimit = 20` process başına. 1 API + 1 worker ≈ 40 bağlantı (+ migrate ve yönetim bağlantıları).
  - MySQL `max_connections ≥ 150`.
  - Havuz metrikleri (bekleyen istek sayısı) alarmlıdır.
- **Sıcak sorgular ve indeksleri:**

  | Sorgu | İndeks |
  |---|---|
  | Aktif oruç | `uq_fasting_one_active (user_id, active_marker)`: eşitlik araması, O(1) |
  | Hafta şeridi | `daily_summaries PK (user_id, local_date)` aralık taraması, 7 satır |
  | Günün suyu | `ix_water_user_date` |
  | Öğün zaman çizelgesi | `ix_meals_user_date` |
  | Bildirim kutusu | `ix_notif_user_list` + cursor |
  | Sohbet mesajları | `ix_msgs_conv_time` + cursor |
  | Zamanlayıcı | `ix_sched_due (status, fire_at)` + `FOR UPDATE SKIP LOCKED LIMIT 500` |

- **N+1 yok:** Liste uçları ilişkili veriyi tek bir `IN (…)` sorgusuyla getirir (ör. öğün listesi → medya varyantları).
- **Sayfalama:** Cursor `(created_at, id)`. `WHERE (created_at, id) < (?, ?) ORDER BY created_at DESC, id DESC LIMIT ?`.
- **Özet ucu:** `GET /user/summary` en fazla 6 paralel ve indeksli sorgu çalıştırır (`Promise.all`). Sonuç 30 sn cache'lenir. Hedef p95 < 120 ms.
- **InnoDB ayarları:**
  - `innodb_buffer_pool_size` RAM'in ~%70'i.
  - `innodb_flush_log_at_trx_commit=1`.
  - Yavaş sorgu logu > 200 ms.
- **Replika:** Raporlama, admin istatistikleri ve gece işleri faz 11'de read replica'ya yönlendirilir. Kullanıcıya dönük okumalar replika gecikmesinden etkilenmemesi için primary'de kalır.

## 8. Uygulama performansı

- **Serileştirme:** Fastify yanıt şemaları fast-json-stringify kullanır. `JSON.stringify`'dan 2–3 kat hızlıdır.
- **Ağır CPU işleri** (görsel işleme, zip, şifreleme döngüleri) API process'inde değil, **worker** process'inde çalışır.
  - Avatar yükleme senkrondur ama küçüktür. `sharp`'ın libuv thread havuzunu kullanır, `UV_THREADPOOL_SIZE=8`.
- **Dış çağrılar** (Anthropic, RevenueCat, Bunny, FCM):
  - Hepsinde `AbortSignal.timeout` vardır.
  - Hata veren servise karşı devre kesici (circuit breaker) uygulanır: art arda 5 hatada 30 sn açık kalır.
- **SSE akışları:**
  - API process'i başına en fazla 500 eşzamanlı akış.
  - Ters proxy ayarları: `proxy_buffering off`, okuma timeout'u 120 sn.

### 8.1 Performans hedefleri (SLO)

| Metrik | Hedef |
|---|---|
| Okuma uçları p95 | < 150 ms (cache'li < 50 ms) |
| Yazma uçları p95 | < 250 ms |
| `GET /user/summary` p95 | < 120 ms |
| Fotoğraf analizi uçtan uca p95 | < 12 sn |
| Sohbet ilk token gecikmesi p95 | < 2.5 sn |
| Uptime (aylık) | %99.9 |
| 5xx oranı | < %0.1 |

## 9. Ölçekleme planı

| Aşama | Aktif kullanıcı | Altyapı |
|---|---|---|
| Lansman | < 20 bin | Tek VPS: 1 API process + 1 worker (PM2), MySQL aynı sunucuda. Redis yok |
| Büyüme | 20–200 bin | Önce dikey ölçek (daha büyük VPS, `WORKER_CONCURRENCY` artışı). Kuyruk yükü için ek worker process'leri (kuyruk çoklu worker'la zaten çalışır). MySQL ayrı sunucuya / yönetilen MySQL'e, gerekirse + 1 read replica. Birden çok API process'i ya da sunucu gerekirse cache ve rate limit için paylaşımlı store şart: Redis yeniden değerlendirilir (ADR 0005) |
| Ölçek | > 200 bin | Büyük tablolar için aylık partition (`water_entries`, `chat_messages`, `notifications`). Arşiv tabloları. Kuyruk türüne göre ayrılmış worker havuzları (AI ayrı) |

**Yük testi (k6, faz 11):**
- **Senaryo:** Sabah zirvesi. %60 summary + aktif oruç, %20 su/öğün yazma, %10 sohbet, %10 katalog.
- **Hedef:** Lansman altyapısında 500 istek/sn, p95 hedefleri tutmalı.
