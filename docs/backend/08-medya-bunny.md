# 08 — Medya & Bunny CDN

## 1. Kullanım alanları

| Amaç (`media.purpose`) | Kaynak | Görünürlük | Varyantlar |
|---|---|---|---|
| `avatar` | Profil düzenleme (image_picker: 1024 px, kalite 85) | **public** (ayrı private pull zone yok) | `md` 512, `thumb` 128 |
| `meal_photo` | Kalori kamerası, öğün kaydı | private | `lg` 1600, `md` 1024, `thumb` 256 |
| `data_export` | Kullanıcı veri dışa aktarma (zip) | private | – |
| `insight_cover`, `challenge_image`, `plan_image` | Yönetim paneli | public | `lg`, `md`, `thumb` |

> Sağlık bağlamındaki fotoğraflar (öğün fotoğrafları da dahil) **asla public değildir**.

## 2. Bunny düzeni

```
Storage Zone: mochifast-private   (Primary: Falkenstein/DE, +1 replikasyon bölgesi AB içinde)
  └─ Pull Zone: media.mochifast.app   → Token Authentication AÇIK, hotlink koruması, yalnızca GET
Storage Zone: mochifast-public    (Primary: DE, replikasyon: 2+ bölge)
  └─ Pull Zone: cdn.mochifast.app     → token yok, uzun cache, immutable dosya adları
```

**Ayrı zone kullanmanın sebepleri:**
1. Token Authentication pull zone seviyesinde açılır veya kapanır.
2. Erişim anahtarları ayrıdır. Admin içerik anahtarı sızsa bile kullanıcı fotoğraflarına erişilemez.
3. Saklama ve replikasyon politikaları ayrı ayarlanabilir.

**Pull zone ayarları:**

| Ayar | Private | Public |
|---|---|---|
| Token Authentication | ✅ | ✗ |
| Cache süresi | 1 gün (URL token'ı süreyi zaten sınırlar) | 1 yıl |
| Origin Shield | ✅ | ✅ |
| Vary cache (query string) | Token parametreleri cache anahtarına **dahil edilmez** (Bunny'nin "ignore query string" + token doğrulaması) | – |
| CORS | Kapalı (mobil) | Kapalı |
| İzin verilen uzantılar | `webp`, `zip` | `webp`, `png`, `svg` |
| Edge Rule | `Content-Disposition` (zip için `attachment`) | `Cache-Control: public, max-age=31536000, immutable` |

### 2.1 Uygulama durumu ve ayarlar (F5)

| Değişken | Zone | Not |
|---|---|---|
| `BUNNY_STORAGE_ZONE`, `BUNNY_STORAGE_PASSWORD`, `BUNNY_STORAGE_HOST`, `BUNNY_PULL_ZONE_HOST` | public | Mevcut `mochifast` zone'u (`mochifast.b-cdn.net`, uygulama görselleri). Token **kapalı** |
| `BUNNY_PRIVATE_STORAGE_ZONE`, `BUNNY_PRIVATE_STORAGE_PASSWORD`, `BUNNY_PRIVATE_STORAGE_HOST`, `BUNNY_PRIVATE_PULL_ZONE_HOST` | private | **Henüz kurulmadı.** Ayrı storage zone + pull zone, Token Authentication açık |
| `BUNNY_TOKEN_AUTH_KEY` | private | Private pull zone'un "Url Token Authentication Key" değeri |
| `BUNNY_API_KEY` | – | Purge |
| `MEDIA_DRIVER` | – | `local` (geliştirme/test: `var/media`, imzalı URL'ler API'nin `/media-files/*` ucuna) \| `bunny` (üretimde zorunlu) |
| `MEDIA_PATH_SECRET` | – | `ownerKey` HMAC sırrı; üretimde ≥ 32 karakter zorunlu |

**Güvenlik kilidi:** `MEDIA_DRIVER=bunny` iken private pull host ya da storage zone public olanla aynıysa API **başlamaz**. Böylece kullanıcı fotoğrafları yanlışlıkla token'sız CDN'e yazılamaz.

## 3. Depolama yolu düzeni (PII içermez)

```
private:
  u/{ownerKey}/avatar/{mediaId}_{variant}.webp
  u/{ownerKey}/meals/{yyyy}/{mm}/{mediaId}_{variant}.webp
  u/{ownerKey}/exports/{exportId}.zip
public:
  p/insights/{sha256[0:16]}_{variant}.webp
  p/challenges/{sha256[0:16]}_{variant}.webp
```

- `ownerKey = HMAC-SHA256(userId, MEDIA_PATH_SECRET)` değerinin ilk 20 hex karakteridir.
  - Kullanıcı ID'si yoldan geri çıkarılamaz.
  - Kararlı olduğu için hesap silmede `u/{ownerKey}/` dizini listelenip **önek bazında tamamen silinebilir**.
- `mediaId` UUIDv7 olduğundan tahmin edilemez. Erişim zaten token ile korunur.
- Public dosya adları içerik hash'idir. İçerik değişince URL de değişir, bu sayede purge gerekmez.

## 4. Yükleme hattı

```
İstemci                              API (veya worker)                          Bunny
───────                              ─────────────────                          ─────
küçült (≤2048 px, JPEG q85)
POST multipart ──────────────► 1. Auth + rate limit + kota (meal_photo için)
                               2. @fastify/multipart: files=1, fileSize≤10MB, fields≤5
                               3. Buffer'a al → file-type magic byte:
                                  jpeg|png|webp kabul; heic/heif → 415 (istemci JPEG'e çevirir)
                               4. sharp(buf, {limitInputPixels: 40e6, failOn:'error'})
                                  .rotate()                       // EXIF yönünü uygula
                                  → her varyant: .resize({width|height ≤ N, fit:'inside',
                                                          withoutEnlargement:true})
                                                 .webp({quality: 80, effort: 4})
                                  (sharp varsayılan olarak tüm metadata'yı ATAR: EXIF/GPS/XMP yok)
                               5. sha256(orijinal) → aynı kullanıcı + aynı hash 24 sa içinde
                                  yüklendiyse mevcut medyayı döndür (çift yükleme)
                               6. blurhash (32×32'den) — liste yer tutucusu için
                               7. Varyantları paralel PUT ──────────────────► Storage API
                                  Header: AccessKey, Content-Type: application/octet-stream,
                                          Checksum: SHA256(varyant) (bütünlük)
                               8. INSERT media(status='ready', variants, bytes, w, h, blurhash)
                               9. Yanıt: {id, url(imzalı), thumbUrl(imzalı), blurhash, expiresAt}
```

**F5 uygulaması:** `src/modules/media/media.pipeline.js` (`file-type` + `sharp` + `blurhash`), `src/infra/bunny.js` (Storage API, imza, yerel sürücü). Dekompresyon bombası hem başlıktaki boyuttan (`w × h > 40M` → 413) hem sharp'ın `limitInputPixels` korumasından yakalanır. Varyant adı uzun kenar pikselidir: `…/{mediaId}_{512|1024|…}.webp`.

**Senkron mu, asenkron mu?**
- **Avatar:** Senkron. Küçük dosya, p95 < 1.5 sn.
- **Öğün fotoğrafı (F5, AI'sız):** `POST /v1/media` senkron işler ve 201 döner (avatar gibi).
- **Öğün fotoğrafı + analiz (F6):** API yalnızca 2–4. adımları yapıp ham görseli **worker'a** devreder.
  - Pratik yol: `lg` varyantını üretip Bunny'ye yükler, ardından AI analiz işini kuyruğa atar ([09](09-yapay-zeka.md)).
  - Böylece istek hızlıca 202 döner.
- **Hata durumu:** Bunny PUT 3 kez üstel geri çekilme (exponential backoff) ile denenir. Hepsi başarısız olursa `media.status = 'failed'` olur ve kullanıcıya 503 döner.

## 5. İmzalı URL (private zone)

Bunny **Token Authentication** (SHA-256 tabanlı gelişmiş şema) kullanılır.

```js
// infra/bunny.js — fikir; formül uygulamada Bunny'nin resmi dokümanı/örnek koduyla birebir doğrulanacak
import { createHash } from 'node:crypto';

export function signPrivateUrl(path, ttlSec = 6 * 3600) {
  const expires = Math.floor(Date.now() / 1000) + ttlSec;
  const hashable = config.bunny.privateTokenKey + path + expires;
  const token = createHash('sha256').update(hashable).digest('base64')
    .replace(/\n/g, '').replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
  return { url: `https://${config.bunny.privateHost}${path}?token=${token}&expires=${expires}`,
           expiresAt: new Date(expires * 1000).toISOString() };
}
```

**Kurallar:**
- **Varsayılan TTL 6 saattir.** Veri dışa aktarma linkleri 7 gün geçerlidir.
- **Zaman kovası:** `expires` değeri saat başına yuvarlanır. Böylece aynı saat içindeki yanıtlarda aynı URL döner, istemci ve edge cache verimli çalışır.
- **IP'ye bağlamak önerilmez.** Bunny token'ı IP'ye bağlamaya izin verse de mobil ağlarda IP sık değişir.
- **Süre dolarsa:** İstemci 403 alır. İlgili kaynağı yeniden çekerek yeni URL alır.
- **İstemci cache anahtarı:** `cached_network_image` için **`cacheKey = mediaId_variant`** verilmelidir. Aksi hâlde token değiştikçe aynı görsel tekrar indirilir ([13](13-flutter-entegrasyonu.md)).

## 6. Silme & yaşam döngüsü

| Durum | Ne olur |
|---|---|
| Kullanıcı öğünü siler | Öğün yumuşak silinir. 30 gün sonra temizlik işi medyayı Bunny'den siler, `media.status = 'deleted'` olur |
| Avatar değişir | Eski medya hemen silinir (Bunny DELETE + **public** zone purge) |
| Fotoğraf analiz edildi ama öğün kaydedilmedi | 24 sa sonra silinir (`meal_photo` olup hiçbir öğüne bağlı değilse) |
| Hesap silme | `u/{ownerKey}/` dizini listelenir → her dosya silinir → pull zone'da `u/{ownerKey}/*` purge edilir → media satırları silinir |
| `processing` durumunda takılan kayıt (> 1 sa) | `failed` olur, varsa yüklenmiş varyantlar silinir |
| Veri dışa aktarma | 7 gün sonra silinir |

**Purge API:** `POST https://api.bunny.net/purge?url=<encoded url>` (header `AccessKey: <hesap API anahtarı>`). Dizin purge'ü için joker karakter (`*`) desteklenir.

## 7. Yönetim içeriği (public)

- Admin panelinden yüklenen görseller aynı hattan geçer. Varyantlar `mochifast-public` zone'una yazılır.
- URL'ler kalıcıdır: `https://cdn.mochifast.app/p/insights/{hash}_md.webp`.
- Bunny Optimizer (dinamik yeniden boyutlandırma) **gerekmez**. Varyantlar önceden üretildiği için ek maliyet ve karmaşıklık çıkmaz.

## 8. İzleme & maliyet

- **Metrikler:**
  - yükleme sayısı ve boyutu
  - `sharp` işleme süresi
  - Bunny PUT hata oranı
  - imzalı URL üretim sayısı
- **Bunny tarafı:** Bunny panelinde bant genişliği ve depolama alarmları kurulur.
- **Tahmini depolama:**
  - Öğün fotoğrafı ≈ 3 varyant × ~120 KB ≈ 360 KB.
  - Kullanıcı başına ayda ~20 fotoğraf × 100 bin kullanıcı ≈ 720 GB/ay.
- **Saklama politikası:** Kullanıcı isterse 1 yılı aşan öğün fotoğraflarının `lg` varyantı silinip yalnızca `md` saklanabilir. Bu bir ürün kararıdır ([14 #12](14-acik-kararlar.md)).

## 9. Test

- **Birim:** EXIF/GPS içeren JPEG → çıktıda metadata **olmadığını** doğrulayan test.
- **Birim:** Dekompresyon bombası (ör. 30000×30000 PNG) → 413 / 422.
- **Birim:** HEIC → 415. SVG → 415. PDF'i JPEG uzantısıyla göndermek → 415.
- **Entegrasyon:** Bunny çağrıları test ortamında `infra/bunny.js` sahte (fake) implementasyonuyla çalışır (yerel diske yazar).
- **Staging:** Gerçek staging zone'ları kullanılır.
