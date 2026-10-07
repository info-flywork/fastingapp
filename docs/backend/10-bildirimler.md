# 10 — Bildirimler

## 1. Kanallar

| Kanal | Teknoloji | Kullanım |
|---|---|---|
| **Push** | Firebase Cloud Messaging HTTP v1 (`firebase-admin`). iOS bildirimleri de FCM → APNs üzerinden gider | Zamanlı hatırlatıcılar, olay bildirimleri |
| **Gelen kutusu** (inbox) | `notifications` tablosu → Profil → Notification Inbox | Kalıcı olay kayıtları (kilo güncellemesi, öğün penceresi bitti, challenge, seviye atlama…) |
| **Sessiz push** (opsiyonel, faz 9+) | FCM data mesajı (`content-available`) | Başka cihazda oruç başlatılınca ana ekran widget'ını yenilemek |

İstemcideki `NotificationManager.syncTags` (OneSignal tarzı etiketler) **gerekmez**. Hedefleme sunucu tarafında yapılır.

## 1b. Uygulama (F9)

- **Günlük planlayıcı (F11):** "yerel saat 0 mı" yerine her saat dilimi için her yerel günü bir kez işler (`zone_day_runs`): gece yarısının yaşanmadığı DST günlerinde (Santiago, Asunción, Havana…) ve worker'ın kapalı olduğu saatlerde de gün kaçmaz. Seri gün dönümü (`dayRollover`) aynı mekanizmayı kullanır.
- **Kod:** `src/modules/notifications/` (`notify.js` planlama/iptal, `notifications.rules.js`, `notifications.service.js` gönderim + inbox, `planner.js` günlük hatırlatıcılar), `src/infra/fcm.js`, `src/jobs/notifications.jobs.js`. Şablonlar `seeds/notifications.json` (20 tür, 7 dil) → `notification_templates` (+ `quiet_hours: defer|silent|send`, `max_delay_min`).
- **Tek yol:** anlık olaylar da `scheduled_notifications`'tan geçer (`fire_at = şimdi`); inbox kaydı gönderim işinde yazılır (push yeniden denenirse kutuda kopya olmaz).
- **Ayar:** `FCM_SERVICE_ACCOUNT_JSON` (ham ya da base64). Yoksa push atlanır (`push_not_configured`), inbox çalışır. Worker kuyruğu `notifications`: dağıtıcı 30 sn, planlayıcı saatlik (yerel 00:xx dilimleri), bakım günlük.
- **Gönderim anında geçerlilik:** oruç bildirimleri oruç hâlâ aktifse; su hatırlatması hedef tutmadıysa ve son 60 dk'da su yoksa; seri dürtmesi seri ≥ 2 ve bugün oruç yoksa; tartı hatırlatması 7 gündür kayıt yoksa; oruç başlatma / yeme penceresi bitiyor aktif oruç yoksa.
- **Ayar anahtarları:** `user_settings.notif_world` eklendi (dünya kategorisi). `system` kategorisi her zaman açık; `marketing` push'u ayrı rıza akışı gelene kadar gönderilmez.
- **Atlama sebepleri** `scheduled_notifications.last_error`'da: `category_off`, `push_disabled`, `quiet_hours`, `quiet_hours_deferred`, `new_user_quiet_period`, `daily_limit`, `category_limit`, `no_device`, `invalid_tokens`, `fast_not_active`, `water_recent`…
- **Bağlı olaylar:** oruç (başlat/düzenle/bitir/iptal/sil/otomatik kapanış), yeme penceresi, kilo (`weight_update`), seri kilometre taşı (yalnızca BUGÜN ulaşılan) ve kaybı, dünya seviye atlama ve kötüleşen sağlık, challenge yarı yol ve tamamlanma, premium kaybı. `subscription_expiring` ve dışa aktarma/hesap silme şablonları hazır; tetikleyicileri F10'da.

## 2. Bildirim tipleri

| Tip | Kanal | Kategori (ayar anahtarı) | Tetikleyici | Derin link |
|---|---|---|---|---|
| `fast_goal_reached` | push + inbox | fasting | `planned_end_at` | `fastingapp://fasting` |
| `fast_halfway` | push | fasting | başlangıç + hedef/2 (yalnızca ≥ 14 sa planlarda) | `fastingapp://fasting` |
| `fast_stage_reached` | push | fasting | 16 sa (ketoz) ve 12 sa (yağ yakımı) evreleri (günde en fazla 1) | `fastingapp://body-status` |
| `fast_start_reminder` | push | fasting | Yeme penceresi bitişi (plan) + aktif oruç yok | `fastingapp://fasting` |
| `eating_window_ending` | push | fasting | Yeme penceresi bitişinden 30 dk önce | `fastingapp://fasting` |
| `meal_window_ended` | inbox (+push) | fasting | Yeme penceresi bitti ("Meal time is ended") — mevcut mock tipi | `fastingapp://fasting` |
| `fast_overdue` | push | fasting | `planned_end_at + 12 sa` hâlâ aktif ([05 §1.3](05-is-kurallari.md#1-oruç-seansı-durum-makinesi)) | `fastingapp://fasting` |
| `weight_update` | inbox | weight | Kilo kaydı ("Weight updates", `{weightKg}`) — mevcut mock tipi | `fastingapp://body-history` |
| `weight_reminder` | push | weight | Haftalık, kullanıcının en son tartıldığı gün/saatte (7 gün kayıt yoksa) | `fastingapp://body-history` |
| `water_reminder` | push | water | Aralıklı (§4) | `fastingapp://water` |
| `streak_nudge` | push | streak | Yerel 20:00, bugün zorunlu gün + henüz oruç yok + seri ≥ 2 | `fastingapp://fasting` |
| `streak_milestone` | push + inbox | streak | 3/7/14/30/60/100 gün | `fastingapp://home` |
| `streak_lost` | inbox | streak | Gün dönümünde seri bozuldu | `fastingapp://home` |
| `world_level_up` | push + inbox | world | Bölge seviye atladı | `fastingapp://mochi-world` |
| `world_health_changed` | push + inbox | world | thriving → wilting / drought | `fastingapp://mochi-world` |
| `challenge_progress` | inbox | challenge | Hedefin %50'si | `fastingapp://home` |
| `challenge_completed` | push + inbox | challenge | Tamamlandı | `fastingapp://home` |
| `subscription_expiring` | inbox | system | Deneme bitimine 2 gün kala (RevenueCat olayı) | – |
| `data_export_ready` | push + inbox | system | Dışa aktarma hazır | `fastingapp://profile` |
| ~~`account_deletion_scheduled`~~ | — | — | Kaldırıldı (F11): silme talebinde oturumlar ve push token'lar hemen kapandığı için gönderilemiyordu; bilgi uygulamadaki onay diyaloğunda ve `DELETE /user/me` yanıtında (`scheduledFor`) | — |

**Gizlilik:**
- Push metinleri **sağlık değeri içermez**. Bunun yerine "Yeni kilo kaydın eklendi 🎉" gibi ifadeler kullanılır. Değerler yalnızca uygulama içi kutuda görünür.
- Kilit ekranında görünen içerik sınırlı tutulur.

## 3. Mimari

```
Domain olayı (fast.started, …)
   │
   ├─► notifications.schedule(userId, type, fireAt, params, dedupeKey)
   │        INSERT scheduled_notifications … ON DUPLICATE KEY UPDATE fire_at, params, status='scheduled'
   │
   └─► notifications.cancel(userId, dedupeKeyPrefix)      // ör. fast iptal edilince 'fast:<id>:*'

worker'ın tekrarlı işi (her 30 sn, `src/schedules.js`) → notification-dispatch işi:
   BEGIN;
   SELECT … FROM scheduled_notifications
    WHERE status='scheduled' AND fire_at <= NOW(3)
    ORDER BY fire_at LIMIT 500 FOR UPDATE SKIP LOCKED;
   UPDATE … SET status='processing';
   COMMIT;
   → her satır için push-send işi kuyruğa (`jobs`, dedupeKey = 'push:<scheduledId>'; worker eşzamanlılığı ile paralel)

push-send işi:
   1. Kullanıcı ayarlarını kontrol et (push_enabled, kategori anahtarı, rıza, sessiz saatler) → değilse 'skipped'
   2. Günlük frekans sınırı (MySQL: kullanıcının yerel gününde status='sent' olan scheduled_notifications
      sayılır, kategori için şablonla join; ≤ 6 push, aynı kategoride ≤ 3) → aşıldıysa 'skipped'
   3. Şablonu kullanıcının locale'iyle render et (yer tutucular)
   4. Kanal 'inbox' içeriyorsa → notifications satırı (unread cache'i API'de TTL ile yenilenir, 07 §2)
   5. Kanal 'push' içeriyorsa → kullanıcının push_enabled cihazlarına FCM sendEach
        - 'messaging/registration-token-not-registered' | 'invalid-argument' → devices.push_token = NULL
   6. status='sent' | 'failed' (attempts++; kuyruk maxAttempts: 3 ile üstel geri çekilme)
```

**Neden her bildirim için gecikmeli iş (`delayMs`) yerine ayrı tablo + dispatcher?**
- **Tek doğru kaynak:** İptal ve yeniden planlama `scheduled_notifications` üzerinde tek bir `UPDATE` ile yapılır. `jobs` tablosunda bekleyen işleri bulup iptal etmek gerekmez.
- **Kolay denetim:** "Bu kullanıcıya hangi bildirimler planlı?" sorusu tek bir SQL ile cevaplanır.
- **Tekrarsız gönderim:** Dispatcher push-send işini bildirim başına `dedupeKey` ile kuyruğa atar. Aynı bildirim iki kez kuyruğa giremez, iki kez gönderilmez.

`jobs` kuyruğu yalnızca gönderim işçisi olarak kullanılır. Dispatcher, worker'ın 30 sn'lik tekrarlı işidir (`src/schedules.js`).

**Dedupe anahtarı örnekleri:**

| Bildirim | Anahtar |
|---|---|
| Hedefe ulaşma | `fast:<sessionId>:goal` |
| Su hatırlatması | `water:<localDate>:<slot>` |
| Seri dürtmesi | `streak_nudge:<localDate>` |

## 4. Hatırlatıcı kuralları

### 4.1 Sessiz saatler
- `user_settings.quiet_hours_start/end` (varsayılan 22:30–08:00) aralığına düşen **hatırlatıcılar** (su, kilo, seri dürtmesi) iptal edilmez, sessiz saatlerin bitişine **ertelenir**. Erteleme sonrası anlamı kalmayanlar atlanır.
- `fast_goal_reached` sessiz saatlerde **sesiz** gönderilir: inbox'a yazılır, push'ta ses çalmaz. Bunun için iOS'ta `interruption-level: passive`, Android'de düşük öncelikli kanal kullanılır.

### 4.2 Su hatırlatmaları (`notif_water = 1` ise)
- **Saatler:** `wake_time + 1 sa` ile `bedtime − 1 sa` arası, `water_reminder_interval_min` aralıklarla.
- **Planlama:** O günün slotları gün dönümü işinde planlanır.
- **Su içtikçe:**
  - Kullanıcı son 60 dakikada su kaydettiyse sıradaki slot atlanır.
  - Günlük hedefe ulaşıldıysa kalan slotlar iptal edilir.

### 4.3 Oruç bildirimleri
- **Oruç başlatılınca planlananlar:** `fast_goal_reached`, varsa `fast_halfway` ve `fast_stage_reached`.
- **Değişikliklerde:**
  - Oruç düzenlenince bu bildirimler yeniden planlanır.
  - Bitirilince veya iptal edilince iptal edilir.
- **Bitirince:** `eating_window_ending` ve `meal_window_ended` planlanır (yeme penceresi = plan yeme süresi).
- **Plan saatine göre hatırlatma:** Planın yeme penceresi bitişinde aktif oruç yoksa `fast_start_reminder` gönderilir. Bu bildirim gün dönümü işinde ertesi gün için planlanır.

### 4.4 Gün dönümü işleri (yerel 00:05, saatlik dilim taraması)
- Seri kontrolü: bozulduysa `streak_lost`.
- Dünya sağlık değişimi kontrolü.
- O günün su ve kilo hatırlatmaları ile `streak_nudge` planlanır.

### 4.5 Sıklık sınırı ve kullanıcı yorgunluğu
- **Günlük sınırlar:** kullanıcı başına en fazla 6 push; aynı kategoride en fazla 3.
- **Yeni kullanıcılar:** İlk 3 gün için oruç bildirimleri dışında push gönderilmez. Bu, kayıttan sonraki erken kopuşu (churn) azaltır.
- **Öncelik:** Bildirimler çakışırsa önce oruç bildirimleri, sonra seri, sonra su gönderilir.

## 5. Şablonlar & yerelleştirme

- `notification_templates` + `notification_template_translations` (7 dil).
- **Yer tutucular:** `{name}`, `{weightKg}`, `{streak}`, `{planName}`, `{zone}`, `{level}`.
- **Format:** Sayı ve tarih biçimleri kullanıcının diline göre `Intl` ile yapılır.
- **Gelen kutusu yanıtı:** `GET /v1/notifications` başlık ve gövdeyi **okuma anında** kullanıcının güncel diliyle render eder. `params` alanı da istemciye ayrıca gönderilir; istemci mevcut tasarımdaki gibi `74kg` değerini vurgulayabilsin diye.
- **Push metni:** Gönderim anında render edilir.

## 6. Cihaz & token yönetimi

- `PUT /v1/devices/current` her açılışta ve token yenilendiğinde (`onTokenRefresh`) çağrılır.
- **Token tekilliği:** Aynı push token başka bir kullanıcıda kayıtlıysa (cihaz el değiştirdi, hesap değişti) eski kayıttan silinir.
- **Push izni:** iOS'ta push izni reddedilirse istemci `pushEnabled: false` gönderir. Gelen kutusu yine çalışır.
- **Temizlik:** 60 gün görünmeyen cihazların push token'ı silinir.

## 7. Test & gözlem

- **Metrikler:**
  - `push_sent_total{type,status}`
  - `notifications_skipped_total{reason}` (ayar, sessiz saat, sınır)
  - dispatcher gecikmesi (`fire_at`'ten gönderime kadar geçen süre, p95 < 60 sn)
- **Staging:** Gerçek cihaz testleri ayrı bir Firebase projesiyle yapılır.
- **Entegrasyon testi:** FCM sahte (fake) implementasyonla, planlama → gönderim → iptal senaryoları test edilir.
