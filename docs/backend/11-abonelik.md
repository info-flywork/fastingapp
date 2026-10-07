# 11 — Abonelik (RevenueCat)

## 1. Model

| Kavram | Değer |
|---|---|
| Entitlement | `premium` (tek entitlement; tüm premium özellikler buna bağlı) |
| Ürünler (öneri) | `mochifast_premium_monthly`, `mochifast_premium_yearly` (deneme süreli), ileride `lifetime` |
| Offering | `default` (paywall), A/B için ek offering'ler RevenueCat panelinden |
| `app_user_id` | **Bizim kullanıcı UUID'miz**. İstemci giriş/misafir oturumu sonrası `Purchases.logIn(userId)` çağırır |
| Doğruluk kaynağı | RevenueCat (mağaza makbuz doğrulaması orada). Bizim DB'miz **yansıtılmış** durumdur |

> Misafir kullanıcı da UUID'ye sahip olduğu için satın alma yapabilir.
> Misafir hesap sosyal hesaba yükseltildiğinde **ID değişmez** ve abonelik korunur ([05 §11](05-is-kurallari.md#11-misafir-hesap-birleştirme)).

## 1b. Uygulama (F8)

- **Paywall:** tamamen RevenueCat (Paywalls, `purchases_ui_flutter`); sunucuda paywall kodu yok.
- **Ayarlar:** `REVENUECAT_SECRET_API_KEY` (v1 REST, `sk_…`), `REVENUECAT_WEBHOOK_AUTH` (panelde webhook "Authorization header" değeriyle **birebir** aynı), `REVENUECAT_ENTITLEMENT=premium`, `REVENUECAT_ALLOW_SANDBOX` (boş: üretim dışında true, üretimde false).
- **Kod:** `src/infra/revenuecat.js` (REST + `mapSubscriber` + `grantsAccess`), `src/modules/billing/` (entitlement önbelleği 30 sn, senkron, webhook, olay işi, premium kaybı, promosyon), `scripts/grant-premium.js` (`npm run premium:grant -- <userId> monthly`; panel F10'da).
- **Durum eşlemesi:** iade → `refunded`; süresiz ya da süresi gelmemiş → `active` (ödeme sorunu varsa `billing_issue`, erişim sürer); süre geçmiş ama grace içinde → `in_grace` (erişim sürer); değilse `expired`. RevenueCat'te entitlement hiç yoksa kayıt `expired` yapılır.
- **Bekleyen plan:** onboarding'de seçilip premium olmadığı için bekleyen plan (`pendingPlanCode`), premium gelir gelmez senkronda etkinleşir.
- **Premium kaybı:** saatlik `premiumDowngrade` işi; aboneliği `expired`/`refunded` ve bitişi kullanıcının yerel gününe göre dün ya da önce olan kullanıcıların premium planı 16:8'e düşer, `notifications` tablosuna `premium_expired` kaydı (`{fromPlan, toPlan}`) yazılır. Push F9'da.
- **TRANSFER:** olaydaki `transferred_from` / `transferred_to` kullanıcılarının hepsi senkronlanır. `$RCAnonymousID:` olayları `anonymous_user` notuyla kapanır (istemci sync ile düzeltir).

## 2. Premium özellik matrisi

FAQ metnine ve mevcut UI'a göre:

| Özellik | Ücretsiz | Premium | Uygulama noktası |
|---|---|---|---|
| Oruç zamanlayıcı, temel takip (su, kilo, öğün, açlık, adım, uyku) | ✅ | ✅ | – |
| Planlar: 12:12, 13:11, 14:10, 15:9, 16:8 | ✅ | ✅ | `fasting_plans.is_premium` |
| Planlar: 17:7 ve üstü, OMAD, haftalık, Early/Late, özel | ❌ | ✅ | `PUT /plans/current` → 402 |
| Coach Mochi sohbeti | Günde 3 mesaj | Günde 100 | Kota ([09 §4](09-yapay-zeka.md#4-kotalar)) |
| Fotoğraftan kalori analizi | Günde 2 | Günde 30 | Kota |
| "Deeper insights": premium makaleler, detaylı istatistik (aylık/yıllık, tahmin kartı) | Kısıtlı | ✅ | `insight_articles.is_premium`, `/fasts/forecast` |
| Günlük Mochi planı | ❌ | ✅ | `/fasts/daily-tip` |
| Premium challenge'lar | ❌ | ✅ | `challenges.is_premium` |
| Seri dondurma (faz 2) | ❌ | ✅ | – |

Bu tabloya yönetim panelinden `app_config.premium.features` ile ince ayar yapılabilir.

## 3. Webhook işleme

```
POST /v1/webhooks/revenuecat
  1. Authorization header == REVENUECAT_WEBHOOK_AUTH (timingSafeEqual) değilse → 401
  2. INSERT IGNORE revenuecat_events(event_id, type, app_user_id, environment, payload)
     - satır zaten varsa → 200 (tekrar)
  3. kuyruk: revenuecat-event {eventId}
  4. 200 (RevenueCat 5 sn içinde yanıt bekler; işleme asenkron)

Worker (revenuecat-event.job.js):
  1. app_user_id bizim users tablosunda yoksa:
       - '$RCAnonymousID:' önekli ise → yoksay (istemci logIn çağırmadan satın almış; sync ile düzelecek)
       - aksi hâlde → error kaydı, alarm
  2. RevenueCat REST: GET /v1/subscribers/{app_user_id} (secret API key) — GÜNCEL tam durum
  3. entitlements.premium → subscriptions upsert:
       status: aktif & expires_at > now → active
               billing_issue/grace → in_grace (grace_expires_at)
               unsubscribe_detected_at dolu + aktif → active (will_renew=false)
               süresi geçmiş → expired, iade → refunded
  4. Değişiklik varsa:
       - u:{uid}:ent ve summary cache'i: worker API cache'ini silemez, TTL ile yenilenir (07 §2)
       - audit_logs ('subscription.changed')
       - premium kaybı → §5 akışı
       - event_type TRANSFER → eski kullanıcının aboneliğini de yeniden senkronla
  5. revenuecat_events.processed_at = now
```

**Olay tiplerine göre davranış:**

| Olay | Davranış |
|---|---|
| `INITIAL_PURCHASE`, `RENEWAL`, `UNCANCELLATION`, `NON_RENEWING_PURCHASE`, `PRODUCT_CHANGE`, `SUBSCRIPTION_EXTENDED`, `TEMPORARY_ENTITLEMENT_GRANT` | Senkronla (premium aktif) |
| `CANCELLATION` | Senkronla. `will_renew = false`, süre sonuna kadar aktif kalır. Opsiyonel olarak kazanma bildirimi (win-back) |
| `BILLING_ISSUE` | `in_grace` durumuna geçer. Uygulama içi uyarı gösterilir ("Ödeme yönteminde sorun var") |
| `EXPIRATION` | `expired` olur, premium kaybı akışı başlar |
| `TRANSFER` | Her iki kullanıcıyı da senkronla |
| `SUBSCRIBER_ALIAS` (eski) | Senkronla |
| `TEST` | Logla |

**Neden REST ile teyit?** Webhook'lar sıra dışı (out-of-order) gelebilir ve tekrar edilebilir. Her olayda güncel tam durumu çekip yazmak tutarlılığı garanti eder.

## 4. İstemci senkronu

- `POST /v1/subscription/sync`: Satın alma veya geri yükleme (restore) sonrası istemci çağırır. Sunucu REST'ten çeker ve hemen günceller. Webhook gecikmesine karşı bir güvencedir.
- `GET /v1/subscription` ve `/user/me.isPremium` **yalnızca sunucu durumunu** döner.
- **Yetkilendirme kararı:** İstemcideki RevenueCat `CustomerInfo` yalnızca UI'ı anında güncellemek için kullanılır. Yetki kararını sunucu verir.
- **Paywall:** `purchases_ui_flutter` ile gösterilir. Tetiklenme noktaları:
  - 402 `PREMIUM_REQUIRED`
  - 429 `QUOTA_EXCEEDED` (`upgradeAvailable: true`)
  - "Get Premium" butonları

## 5. Premium kaybı akışı

- **Aktif premium plan:** Oruç bozulmaz. Ertesi gün plan ücretsiz eşdeğerine düşer (ör. 20:4 → 16:8). Inbox bildirimi gider ([14 #8](14-acik-kararlar.md)).
- **Sohbet:** Ücretsiz kotaya düşer. Geçmiş sohbetler **okunabilir** kalır.
- **Premium içerik:** Kilitli görünür.
- **Veri:** Hiçbir veri silinmez.

## 6. Promosyon & destek

- **Admin işlemi:** "Premium tanımla" → RevenueCat REST `promotional` entitlement (süreli) + senkron. İşlem audit'e yazılır.
- **Ortam ayrımı:** `environment = sandbox` olaylar staging'e yönlendirilir. Production DB'de sandbox olayları yalnızca loglanır, premium vermez (TestFlight kullanıcıları için ayar: [14 #13](14-acik-kararlar.md)).

## 7. Raporlama

- **Kaynak:** Gelir ve dönüşüm metrikleri öncelikle RevenueCat panelinden izlenir.
- **Sunucu tarafı raporlar:**
  - premium kullanıcı başına AI maliyeti
  - özellik kullanımı (premium planlar, sohbet)
  - deneme süresinden dönüşüm ile uygulama içi davranış ilişkisi
