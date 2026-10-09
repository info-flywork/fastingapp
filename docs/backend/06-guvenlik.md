# 06 — Güvenlik & Uyumluluk

MochiFast; kilo, beslenme, uyku, açlık belirtileri ve sağlık durumu gibi **sağlık verisi** işler.
Bu veri KVKK m.6 ve GDPR m.9 kapsamında **özel nitelikli kişisel veridir**.

Güvenlik bu yüzden "olsa iyi olur" değil, **yayın ön koşuludur**.

## 1. Tehdit modeli (özet)

| Varlık | Tehdit | Ana kontrol |
|---|---|---|
| Kullanıcı hesabı | Token hırsızlığı, oturum ele geçirme | Kısa ömürlü JWT, rotating refresh + yeniden kullanım tespiti, cihaz bağlama |
| Kullanıcı verisi | IDOR (başkasının kaydını okuma) | Her sorguda `user_id` kapsamı, sahiplik testleri, 404 ile sızıntısız yanıt |
| Veritabanı | SQL enjeksiyonu | Yalnızca prepared statement, lint kuralı, en az yetkili DB kullanıcısı |
| Sağlık verisi | Sızıntı (log, yedek, CDN) | Alan şifreleme, log redaksiyonu, imzalı medya URL'si, şifreli yedek |
| Fotoğraflar | Konum sızıntısı (EXIF GPS), zararlı dosya | `sharp` ile yeniden kodlama, metadata silme, magic-byte kontrolü, piksel limiti |
| AI | Prompt enjeksiyonu, zararlı tavsiye, maliyet saldırısı | Sistem/kullanıcı ayrımı, sağlık korkulukları, kota + rate limit |
| Ödeme | Sahte premium | Entitlement yalnızca sunucuda; RevenueCat webhook doğrulama + REST teyidi |
| Altyapı | DoS, kaba kuvvet | Katmanlı rate limit, `under-pressure`, gövde limitleri, CDN/WAF |
| Yönetim paneli | Yetkisiz içerik/kullanıcı erişimi | Ayrı kimlik, TOTP MFA, IP allowlist, RBAC, tam denetim izi |
| Tedarik zinciri | Zararlı paket | Lockfile, `npm ci`, Renovate, `npm audit` / OSV taraması, minimal bağımlılık |

## 2. Kimlik doğrulama

### 2.1 Sağlayıcı token doğrulama (Firebase Authentication)

Apple ve Google girişini istemcideki **Firebase Authentication** SDK'sı yapar (Apple nonce, Google OAuth akışı Firebase'de).
Backend yalnızca Firebase'in imzaladığı **ID token**'ı doğrular ve karşılığında kendi oturumunu (§2.2) açar.
Doğrulama yereldir: Google'ın açık anahtarları (`securetoken@system.gserviceaccount.com` JWKS) önbelleklenir, istek başına ağ çağrısı yoktur (`src/infra/firebase-auth.js`).

| Kontrol | Beklenen |
|---|---|
| `alg` | `RS256` |
| `iss` | `https://securetoken.google.com/<FIREBASE_PROJECT_ID>` |
| `aud` | `<FIREBASE_PROJECT_ID>` |
| `exp`, `iat` | ±60 sn tolerans |
| `auth_time` | Geçmişte (±60 sn) |
| `sub` | Boş olmayan, ≤ 128 karakter. **Kimlik Firebase `uid`'dir**, e-posta değil |
| `firebase.sign_in_provider` | `FIREBASE_SIGN_IN_PROVIDERS` listesinde (`apple.com`, `google.com`). `anonymous` reddedilir: misafir backend'de |
| `email` / `email_verified` / `name` | Bilgi amaçlı |

- `auth_identities`: `provider = 'firebase'`, `provider_subject = uid`, `sign_in_provider` son kullanılan yöntem. Aynı uid'ye Firebase'de hem Apple hem Google bağlanabilir; ikisi de aynı hesaba girer.
- Apple adı yalnızca ilk girişte ve yalnızca istemciye verilir; istemci `fullName` alanıyla iletir.
- **Apple token iptali** (hesap silmede App Store şartı) istemcide Firebase SDK ile yapılır (`revokeTokenWithAuthorizationCode`); sunucuda Apple token'ı saklanmaz.
- `FIREBASE_PROJECT_ID` boşsa Firebase girişi kapalıdır (400 `provider_disabled`).

**Misafir (backend'de, Firebase anonim girişi kullanılmaz):**
- **Cihaz başına tek misafir:** `installId` ile hesap oluşturulur; aynı `installId` her zaman aynı misafire yeni oturum açar (yeni hesap açılmaz).
- `installId` misafirin tek kimlik bilgisidir: istemci **kriptografik rastgele** UUID v4 üretir ve güvenli depoda (iOS Keychain, Android Keystore/EncryptedSharedPreferences) saklar; cihazdan türetilen kimlik (`ANDROID_ID` vb.) kullanılmaz ([13](13-flutter-entegrasyonu.md)). Uygulama `DeviceManager` bunu yapar. Ayrıca **misafir sırrı** (F11): misafir oluşturulurken sunucu `gs_…` (256 bit) sır üretip bir kez döner, `auth_identities.secret_hash`'te SHA-256'sı tutulur; aynı `installId` ile sonraki girişlerde `guestSecret` zorunludur (`401 guest_secret_invalid`). Eski sırsız misafirlere ilk girişte sır verilir. İstemci sırrı kaybederse yeni `installId` ile yeni misafir açar.
- Misafir sosyal hesaba yükseltilince misafir kimliği silinir (hesap artık sosyal hesaptır; sonraki misafir girişi yeni misafir açar). Başka hesaba geçilince misafir kimliği ve hesabı kalır; aynı cihazda misafir girişi onu açar.
- **Rate limit:**
  - IP başına 10/saat
  - installId başına 5/saat
  - Global eşik alarmı
- Misafirler premium satın alabilir (RevenueCat app_user_id = user id). Hesap bağlanınca abonelik korunur.

### 2.2 Token'lar

| Token | Biçim | Ömür | Saklama |
|---|---|---|---|
| Access | JWT, **EdDSA (Ed25519)**, `kid` header'lı | 15 dk | İstemci: secure storage |
| Refresh | Opak, 256 bit rastgele (`rt_` + base64url) | 60 gün (kayan) | Sunucu: yalnızca SHA-256 hash'i (`sessions.token_hash`) |

**Access token claim'leri** (rol ve premium bilgisi bilinçli olarak token'a konmaz; her istekte cache'li kontrol edilir):

| Claim | Değer |
|---|---|
| `sub` | userId |
| `sid` | sessionId |
| `iat`, `exp` | |
| `iss` | `api.mochifast.app` |
| `aud` | `mochifast-app` |

**Doğrulama:**
- İmza ve `exp` kontrol edilir.
- `sid` iptal edilmemiş olmalı. Bu, `sessions.revoked_at` ile kontrol edilir. Sonuç process içi cache'te kısa süre (ör. 60 sn) tutulur. İptal (çıkış, `reuse_detected`, hesap silme) cache kaydını hemen siler. API tek process olduğu için etki anındadır (ADR 0005).
- `users.status = active` olmalı (process içi cache'te 60 sn).

**Rotasyon ve yeniden kullanım tespiti:**

```
refresh(rt):
  s = sessions WHERE token_hash = sha256(rt)                (FOR UPDATE)
  yoksa / süresi dolmuşsa → 401 UNAUTHENTICATED
  s.revoked_at doluysa:
      eğer revoke_reason='rotated' ve s.revoked_at > now-10sn → aynı yeni çifti döndür (paralel istek toleransı; verilen çift process belleğinde 10 sn tutulur)
      aksi hâlde → AYNI family_id'deki tüm oturumları 'reuse_detected' ile iptal et, audit + 401 REFRESH_REUSED
  yeni oturum satırı (aynı family), s.revoked_at=now, reason='rotated', replaced_by_id=yeni
```

- **Anahtar rotasyonu:** `JWT_PUBLIC_KEYS_JSON` birden çok `kid` içerir. Yeni anahtar eklenir, eski anahtar access ömrü (15 dk) kadar doğrulamada kalır, sonra çıkarılır.
- **Çıkış:** İlgili oturum iptal edilir (`revoked_at`), `sid`'in cache kaydı silinir, cihazın push token'ı silinir.

## 3. Yetkilendirme

- **Kullanıcı kapsamı:**
  - Repository fonksiyonları `userId`'yi zorunlu parametre olarak alır, sorgular `WHERE user_id = ?` içerir.
  - Başkasına ait kayıt için **404** döner (403 değil). Böylece kaydın varlığı sızdırılmaz.
- **Premium:**
  - `requirePremium` kancası kullanılır.
  - Entitlement kaynağı `subscriptions` tablosudur (process içi cache'te 5 dk, webhook geldiğinde invalidate).
  - İstemcinin gönderdiği `isPremium` hiçbir zaman dikkate alınmaz.
- **Toplu atama (mass assignment):**
  - JSON Schema `additionalProperties: false`.
  - Service'ler yalnızca whitelist alanları DB'ye yazar.
  - `status`, `user_id`, `is_guest`, `xp` gibi alanlar istemciden asla gelmez.
- **Admin:**
  - Ayrı JWT kitlesi: `aud = mochifast-admin`.
  - Roller: `owner`, `editor` (içerik), `support` (kullanıcı arama, maskeli PII), `analyst` (salt-okunur rapor).
  - İzinler route seviyesinde deklaratif olarak tanımlanır.

## 4. Girdi doğrulama & çıktı kontrolü

- **Fastify JSON Schema** her route'ta zorunludur: `body`, `querystring`, `params`, `headers` ve **`response`**.
  - Yanıt şeması fast-json-stringify ile **yalnızca tanımlı alanları** serileştirir. Yanlışlıkla `token_hash` veya `notes_enc` gibi bir alanın sızması yapısal olarak engellenir.
- **Sayısal aralıklar şemada tanımlıdır:**

  | Alan | Aralık |
  |---|---|
  | kilo | 25–350 |
  | boy | 100–250 |
  | yaş | 13–100 |
  | su miktarı | 1–5000 |
  | oruç hedefi | 60–4320 |
  | not uzunluğu | ≤ 1000 karakter |
  | sohbet mesajı | ≤ 2000 karakter |

- **String normalizasyonu:**
  - Unicode NFC.
  - Kontrol karakterleri temizlenir.
  - Görünen ad için emoji serbesttir, en fazla 60 karakter.
- **Gövde limitleri:**
  - JSON varsayılan 64 KB.
  - Multipart 10 MB (yalnızca medya uçlarında).
  - `bodyLimit` route bazında ayarlanır.
- **Tarih doğrulama:**
  - ISO-8601 formatı.
  - Gelecek tarih toleransı 5 dk.
  - Geçmiş limitleri iş kuralına göre ([05](05-is-kurallari.md)).

## 5. SQL güvenliği

- Yalnızca `pool.execute(sql, params)` kullanılır (sunucu tarafı prepared statement). `query()` yalnızca migration aracında kullanılabilir.
- ESLint kuralı, SQL string'lerinde `${…}` interpolasyonunu yasaklar. Dinamik sıralama veya filtre gerekirse whitelist eşleme kullanılır.
- `multipleStatements: false`.
- **DB kullanıcıları:**

  | Kullanıcı | Yetki |
  |---|---|
  | `app_rw` | Yalnızca DML |
  | `app_migrator` | DDL (yalnızca CI/CD'de) |
  | `app_ro` | Raporlama ve replica |
  | root | Uygulamada asla kullanılmaz |

- MySQL bağlantısı TLS ile yapılır (`ssl: { rejectUnauthorized: true }`).

## 6. Şifreleme

| Katman | Uygulama |
|---|---|
| Aktarım | TLS 1.2+ (tercihen 1.3). HSTS `max-age=63072000; includeSubDomains`. Mobil istemcide sertifika pinning **önerilmez** (operasyonel risk); bunun yerine güçlü TLS kullanılır |
| Disk (at rest) | MySQL verisi (VPS diski) ve yedeklerde sağlayıcı disk şifrelemesi (AES-256). Bunny Storage sağlayıcı şifrelemesi |
| Alan seviyesi | AES-256-GCM (`infra/crypto.js`). Format: `kid \| iv(12) \| tag(16) \| ciphertext`. Kapsam aşağıda |
| Anahtar yönetimi | Anahtarlar secret manager'da tutulur. Rotasyonda yeni `kid` ile yazılır, eskiler okunabilir kalır. Arka planda `re-encrypt` işi eski kayıtları dönüştürür |
| Hash | Refresh token: SHA-256. Admin şifresi: argon2id (`m=19456, t=2, p=1`). Medya: SHA-256 (yineleme tespiti) |

**Alan seviyesinde şifrelenen veriler:**
- `fasting_sessions.notes_enc`
- `meals.notes_enc`
- `hunger_checkins.notes_enc`
- `chat_messages.content_enc`
- `chat_conversations.rolling_summary_enc`
- `admin_users.totp_secret_enc`

> Yapılandırılmış sağlık alanları (kilo, öğün makroları) sorgulanabilir olmaları gerektiği için alan seviyesinde şifrelenmez.
> Bunlar disk şifrelemesi, erişim kontrolü ve log redaksiyonu ile korunur.

## 7. Rate limit & kötüye kullanım

`@fastify/rate-limit` bellek içi store ile kullanılır (API tek process; sayaçlar yeniden başlatmada sıfırlanır). Anahtar: geçerli access token varsa `userId` (limit kimlik doğrulamadan önce çalıştığı için token anahtar üretiminde doğrulanır; sahte token başkasının sayacını tüketemez), yoksa IP; IPv6 adresleri /64 ağına indirgenir.

| Kapsam | Limit |
|---|---|
| Global (kullanıcı ya da IP) | `RATE_LIMIT_GLOBAL_MAX` (600)/dk |
| `POST /auth/*` (IP) | 20/dk, 100/saat |
| `POST /auth/refresh` (oturum ailesi) | 30/saat; mutlak oturum ömrü `REFRESH_ABSOLUTE_DAYS` (180 gün) |
| Yeni misafir (`/auth/guest` ya da `/auth/register provider=guest`) | IP 10/saat (hangi uçtan olursa olsun), installId 5/saat |
| Medya yükleme | 30/saat |
| Fotoğraf analizi | Kota ([09](09-yapay-zeka.md#4-kotalar)) + 10/dk |
| Sohbet mesajı | Kota + 1 eşzamanlı + 20/dk |
| Veri dışa aktarma | 1/gün |
| Webhook | IP allowlist yok (RevenueCat), yalnızca auth header |
| Yönetici girişi | IP 20/15 dk; hesap 5 hata → 15 dk kilit (genel hata döner) |

**Yanıt ve ek korumalar:**
- Limit aşımında 429 `RATE_LIMITED` ve `Retry-After` header'ı döner.
- `@fastify/under-pressure`: event loop gecikmesi > 1 sn veya heap > %90 olursa 503 döner (istemci geri çekilerek yeniden dener).
- **Ön katman:** Bunny Shield veya Cloudflare (WAF + bot koruması + DDoS) önerilir. API'nin önüne yalnızca proxy olarak konur, cache'lenmez.

## 8. KVKK & GDPR

### 8.1 Hukuki dayanak & rıza

| Veri | Dayanak |
|---|---|
| Hesap, kimlik, cihaz | Sözleşmenin ifası |
| Sağlık verisi (kilo, öğün, açlık belirtileri, sağlık bayrakları, uyku) | **Açık rıza** (`consent_type = health_data`) |
| Yapay zekâ işleme (sohbet, fotoğraf analizi) | **Açık rıza** (`ai_processing`). Kullanıcı reddederse AI özellikleri kapalı kalır |
| Pazarlama push'u | Açık rıza (`marketing_push`), varsayılan kapalı |
| Analitik | Meşru menfaat + ayarlardan kapatma (opt-out) |

- Rıza kayıtları `user_consents` tablosunda tutulur: yalnızca ekleme, sürüm ve IP ile.
- Aydınlatma metni veya gizlilik politikası güncellendiğinde `app_config.legal.*Version` artırılır. İstemci yeniden onay ister.
- **Rıza geri çekilirse:**
  - `health_data`: takip özellikleri durur. Kullanıcıya verilerini silme seçeneği sunulur.
  - `ai_processing`: AI uçları 403 `CONSENT_REQUIRED` döner.

### 8.2 Veri sahibi hakları
| Hak | Uygulama |
|---|---|
| Erişim / taşınabilirlik | `POST /v1/user/me/export` → JSON + CSV + fotoğraflar (zip). Private zone'da saklanır, 7 gün geçerli imzalı link |
| Düzeltme | Profil ve kayıt düzenleme uçları |
| Silme | `DELETE /v1/user/me` (aşağıda) |
| İtiraz / kısıtlama | Ayarlar: pazarlama, analitik, AI |

### 8.3 Hesap silme akışı
1. Kullanıcı uygulamada siler: **Profil → Hesabı sil**. App Store Guideline 5.1.1(v) bunu uygulama içinde zorunlu kılıyor.
2. Talep oluşturulur:
   - `account_deletion_requests` (`scheduled_for = now + 7 gün`)
   - kullanıcı `pending_deletion` olur
   - **tüm oturumlar anında iptal edilir**
   - push token'lar silinir
   - RevenueCat'e bilgi gider (abonelik iptali **kullanıcının mağazadan yapması gereken** bir işlemdir, uygulama bunu açıkça söyler)
3. Kullanıcı süre içinde tekrar giriş yaparsa "Silme talebin var, geri almak ister misin?" sorusu gelir (`/user/me/restore`).
4. Süre dolunca `account-delete` işi sırayla:
   1. Firebase Authentication kullanıcısı silinir (Admin SDK, push ile aynı servis hesabı). Apple token iptali **istemcide** yapılır: silme onayında `FirebaseAuth.revokeTokenWithAuthorizationCode` (Apple yeniden yetkilendirme kodu ile). Sunucu Apple refresh token'ı tutmaz (0004'te kolon kaldırıldı).
   2. Bunny'deki tüm medya silinir ve purge edilir.
   3. RevenueCat `DELETE /subscribers/{id}` çağrılır (müşteri verisini silmek için).
   4. `DELETE FROM users WHERE id = ?` çalışır. FK cascade ile tüm kişisel tablolar gider.
   5. `audit_logs` kayıtları anonimleştirilir (`actor_id` NULL olur).
   6. Talep `completed` olur. Sentry ve log retention zaten süreli olduğundan ayrıca bir işlem yapılmaz.
5. **Yedekler:** Silinen veri yedeklerde en fazla 30 gün kalır (saatlik şifreli yedek, 30 gün saklama; `scripts/backup-db.sh`). Bu, aydınlatma metninde yazılır.

### 8.4 Saklama süreleri (retention)
| Veri | Süre |
|---|---|
| Aktif hesap verisi | Hesap yaşadıkça |
| Misafir hesap | Süreyle silinmez (cihazda kalıcı; ürün kararı 2026-10-08). Kullanıcı uygulamadan silebilir |
| İnaktif kayıtlı hesap | 24 ay sonra uyarı e-postası/push, 30 gün sonra silme ([14 #11](14-acik-kararlar.md)). **Henüz uygulanmadı** (e-posta kanalı yok) |
| Yumuşak silinmiş kayıtlar | 30 gün |
| Okunmuş bildirimler | 90 gün |
| `push_deliveries` | 30 gün |
| `audit_logs` | 13 ay |
| Uygulama logları | 30 gün (PII redakte) |
| Fotoğraf analizinde kaydedilmeyen fotoğraflar | 24 saat sonra silinir |
| Veri dışa aktarma dosyası | 7 gün |

### 8.5 Yurt dışına aktarım ve tedarikçiler (veri işleyenler)

| Tedarikçi | Veri | Not |
|---|---|---|
| Barındırma (AB) | Tümü | AB bölgesi |
| Bunny.net (AB, DE storage) | Fotoğraflar | DPA imzalanacak |
| OpenAI (ABD) | Sohbet metni, fotoğraf (analiz anında) | DPA. API verisi varsayılan olarak model eğitiminde kullanılmaz (API şartları). KVKK yurt dışı aktarım: standart sözleşme + Kurul'a bildirim |
| Google Firebase (FCM) | Push token, bildirim metni | Bildirim metinlerine sağlık detayı konmaz (ör. "Kilonu güncelledik" yazılır, kilo değeri yazılmaz) |
| RevenueCat (ABD) | app_user_id (UUID), satın alma | E-posta veya isim gönderilmez |
| Sentry | Hata bağlamı | PII scrubbing açık, `sendDefaultPii: false` |

- **VERBİS kaydı:** Türkiye'de yerleşik veri sorumlusu olarak yapılmalı.
- **Aydınlatma metni:** Türkçe ve İngilizce hazırlanmalı.

### 8.6 Mağaza şartları
- **Apple:**
  - Uygulama içinden hesap silme.
  - Sign in with Apple token revoke (istemcide Firebase SDK ile).
  - Sağlık verisi reklam veya veri madenciliği için kullanılamaz (5.1.3).
  - Privacy Nutrition Label.
  - HealthKit eklenirse HealthKit verisi iCloud'a ve üçüncü taraflara aktarılamaz; amaç beyanı gerekir.
- **Google Play:**
  - Data Safety formu.
  - Hesap silme için web URL'si de gerekli: basit bir `https://mochifast.app/delete-account` sayfası, giriş yap → talep oluştur.
  - Health Connect eklenirse izin beyanı.
- **Tıbbi feragatname:** Onboarding ve FAQ'ta "MochiFast tıbbi tavsiye vermez". AI yanıtlarında bağlama uygun hatırlatma.

## 9. Medya güvenliği

Ayrıntı: [08](08-medya-bunny.md).
- Dosya türü **magic byte** ile kontrol edilir. Uzantıya veya `Content-Type`'a güvenilmez.
- `sharp(input, { limitInputPixels: 40_000_000, failOn: 'error' })` kullanılır. Dekompresyon bombası korumalıdır.
- **Her görsel yeniden kodlanır** (WebP). EXIF, GPS ve ICC dışındaki tüm metadata atılır. Orijinal dosya hiçbir zaman saklanmaz.
- Depolama yollarında PII yoktur (kullanıcı ID'si yerine rastgele bir prefix kullanılır).
- Özel medya yalnızca **imzalı ve süreli** URL ile erişilebilir (varsayılan 6 sa).

## 10. AI güvenliği

Ayrıntı: [09 §5](09-yapay-zeka.md#5-güvenlik-korkulukları).
- Kullanıcı içeriği yalnızca `user` rolünde gider. Sistem promptunda gizli bilgi yoktur. Kullanıcı bağlamı veri olarak etiketlenir.
- **Sağlık korkulukları:**
  - Teşhis ve ilaç dozu verilmez.
  - Tehlikeli uzun oruç teşvik edilmez.
  - Yeme bozukluğu sinyallerinde destekleyici yanıt ve kaynak gösterilir.
  - 18 yaş altı kurallarına uyulur.
- **Refusal yönetimi:** `stop_reason = refusal` yakalanır, kullanıcıya nazik bir yanıt gösterilir.
- **PII minimizasyonu:** Modele e-posta, gerçek ad veya cihaz bilgisi gönderilmez. Yalnızca takma ad ve gerekli sağlık bağlamı gider.
- **Maliyet koruması:** kota, eşzamanlılık limiti, `max_tokens` ve günlük maliyet alarmı.

## 11. Webhook güvenliği (RevenueCat)

- `Authorization` header'ı, RevenueCat panelinde tanımlanan gizli değerle **sabit zamanlı** karşılaştırılır (`crypto.timingSafeEqual`).
- **İdempotency:** `revenuecat_events.event_id` birincil anahtardır. Tekrar gelen olaya 200 dönülür, işlenmez.
- **Kaynak teyidi:** Gelen olaya körü körüne güvenilmez. İşleyici RevenueCat REST API'den `GET /subscribers/{app_user_id}` ile **güncel durumu** çeker ve onu yazar. Bu yaklaşım sıra dışı (out-of-order) olayları da çözer.
- Webhook gövdesi DB'ye yazıldıktan **sonra** 200 dönülür. İşleme kuyruğa alınır.

## 12. Yönetim paneli güvenliği

- Ayrı alan adında çalışır (`admin.mochifast.app`).
- **CORS:** API'de yalnızca bu origin'e izin verilir. Mobil istemci CORS kullanmaz.
- **Kimlik doğrulama:**
  - Şifre argon2id ile saklanır.
  - **TOTP MFA zorunludur.**
  - 5 hatalı girişte hesap 15 dk kilitlenir.
  - Oturum 1 saattir, yenileme yoktur. Tekrar MFA ile giriş yapılır.
- **Erişim:** IP allowlist (ofis veya VPN).
- **Veri koruma:**
  - Destek rolü PII'yi maskeli görür (`a***@g***.com`).
  - Ham sağlık verisi görüntüleme ayrı bir izin gerektirir ve gerekçe alanı ile loglanır.
- **Denetim:** Her yönetici işlemi `audit_logs` tablosuna yazılır.
- **Uygulama notları (F10):**
  - argon2id Node'un yerleşik `crypto.argon2`'si ile (Node ≥ 24.7, ek bağımlılık yok); PHC biçimi.
  - TOTP RFC 6238 (SHA1, 6 hane, 30 sn, ±1 adım); son kabul edilen adım saklanır, aynı kod tekrar kullanılamaz. Sır alan şifrelemesiyle saklanır.
  - Bilinmeyen e-postada da şifre doğrulaması kadar süre harcanır (zamanlamadan hesap varlığı sızmaz); IP başına 15 dk'da 20 giriş denemesi.
  - IP allowlist `ADMIN_IP_ALLOWLIST` (adres/CIDR, IPv4-mapped IPv6 dahil). Üretimde boşsa admin API **kapalı** (`403 admin_disabled`); bilinçli olarak her IP'ye açmak: `ADMIN_ALLOW_ANY_IP=true`.
  - Token iptali: `admin_users.tokens_valid_after` — çıkış, şifre değişimi, sıfırlama, pasifleştirme ve rol değişikliğinde öncesinde verilmiş token'lar geçersiz.
  - Geçici şifre (oluşturma/sıfırlama) ile girişte yalnızca `me`, şifre değiştirme ve çıkış açık (`403 password_change_required`).
  - Kilitli hesap ayrı hata döndürmez (bilinmeyen hesapla aynı yanıt ve süre).
  - Kullanıcı araması POST gövdesiyle (e-posta URL'de ve erişim loglarında görünmez).
  - Kullanıcı arama yalnızca tam kimlik/e-posta ile (kısmi arama ile PII taraması yapılamaz); destek işlemleri gerekçe ister.

## 13. Tedarik zinciri & operasyon güvenliği

- **Bağımlılıklar:**
  - `package-lock.json` zorunlu, CI'da `npm ci`.
  - Renovate ile haftalık bağımlılık güncellemesi.
  - Kritik güvenlik açıkları (CVE) 48 saat içinde yamalanır.
- **CI:**
  - `npm audit --audit-level=high` + OSV-Scanner çalışır, yüksek seviye bulgu build'i kırar.
  - Gizli bilgi taraması: gitleaks (pre-commit + CI).
- **Sunucu süreci:**
  - Root olmayan kullanıcıyla çalışır (PM2/systemd).
  - `.env` dosya izni `600`; yalnızca uygulama kullanıcısı okuyabilir.
  - API önünde Nginx (TLS, gövde limiti); Node portu dışarıya açılmaz.
- **Yedekleme:**
  - Saatlik şifreli mantıksal yedek (mysqldump → AES-256 → Bunny, ayrı zone), 30 gün; cPanel MariaDB'de binlog/PITR yok → RPO ≤ 1 sa. Tatbikat: `scripts/restore-drill.sh`, kayıt: `docs/runbooks.md` (backend reposu).
  - Yedekler şifreli ve ayrı bir hesapta tutulur.
  - **Ayda bir geri yükleme tatbikatı** yapılır (runbook).
- **Erişim:**
  - Üretim DB'sine doğrudan erişim yalnızca bastion veya SSM üzerinden, kayıtlı oturum ve iki kişi kuralıyla yapılır.
- **Olay müdahalesi:**
  - Runbook hazır olmalı: token iptali, anahtar rotasyonu, kullanıcı bilgilendirme.
  - KVKK'ya ihlal bildirimi **72 saat** içinde yapılır.
- **Sızma testi:** Yayından önce harici bir pentest (OWASP ASVS L2 + MASVS) yaptırılır. Ayrıca yılda bir tekrarlanır.
