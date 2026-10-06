# 14 — Açık Kararlar

Aşağıdaki konular **ürün, hukuk veya iş kararı** gerektiriyor. Her biri için tasarımda kullanılan **önerilen varsayılan** belirtildi.
Karar verilmezse bu varsayılanla ilerlenir. Çoğu `app_config` üzerinden sonradan değiştirilebilir.
Gereken faz, kararın en geç hangi fazdan önce verilmesi gerektiğini gösterir.

| # | Konu | Önerilen varsayılan | Alternatif | Gereken faz |
|---|---|---|---|---|
| 1 | **18 yaş altı kullanıcılar.** Onboarding 13+ yaşı kabul ediyor | 13–17 yaş: yalnızca 12:12–14:10 planları, kalori açığı yok, AI'da kilo verme önerisi yok | 18 yaş altını tamamen engellemek (en güvenli; mağaza ve hukuk açısından en temiz) | F1 |
| 2 | **Gece yarısını geçen orucun güne atanması** | Tüm süre **bitiş gününe** yazılır | Süreyi gece yarısında bölmek (iki güne dağıtır; hafta şeridi daha "gerçekçi" ama seri hesabı karmaşıklaşır) | F3 |
| 3 | **Unutulan aktif oruç** | +12 sa'te hatırlatma. 72 sa'te otomatik kapanış (`ended_at = planned_end_at`, `completed`, `auto_closed`), kullanıcıya düzeltme bildirimi | 72 sa'te `endedEarly` olarak kapatmak ya da hiç kapatmamak | F3 |
| 4 | **Seri toleransı** | Hedefin %80'i tutulursa gün sayılır | %100 (katı) ya da %50 | F3 |
| 5 | **Mochi World metrikleri** | Göl = su hedefi günleri. Zirve = ulaşılmış **en iyi** kilo kaybı (görsel geri gitmez). Eşikler: [05 §7](05-is-kurallari.md#7-mochi-world) | Göl = mevcut seri (seri bozulunca küçülür); zirve = güncel kayıp | F7 |
| 6 | **AI model ve maliyet** | `claude-opus-5-5`: sohbet `effort: low`, analiz `effort: medium`. Lansman sonrası eval + maliyet verisiyle yeniden değerlendirilir | Sohbet için `claude-sonnet-5-5` veya `claude-haiku-4-5` (daha düşük maliyet; kalite eval ile ölçülmeli) | F6 |
| 7 | **AI kotaları** | Ücretsiz: sohbet 3/gün, fotoğraf 2/gün. Premium: 100/gün ve 30/gün | Sohbeti tamamen premium yapmak (FAQ metniyle birebir uyumlu) | F6 |
| 8 | **Abonelik bitince premium plan** | Ertesi gün ücretsiz eşdeğerine düşer (20:4 → 16:8) + bildirim | Mevcut planı korumak, yalnızca değiştirmeyi kilitlemek | F8 |
| 9 | **Seri dondurma (streak freeze)** | V2: premium kullanıcılara ayda 2 dondurma hakkı | Hiç olmaması | V2 |
| 10 | **Challenge katılımcı sayısı** | **Yalnızca gerçek sayı** (8954 gibi sahte rakam yok). Avatarlar yalnızca izin veren kullanıcılardan, aksi hâlde maskot görselleri | Pazarlama tabanı eklemek (tüketici mevzuatı ve mağaza politikası riski) | F7 |
| 11 | **İnaktif hesap saklama süresi** | Misafir: 90 gün. Kayıtlı: 24 ay sonra uyarı + 30 gün sonra silme | Süresiz saklama (KVKK ölçülülük ilkesine aykırı olabilir) | F10 |
| 12 | **Öğün fotoğraflarının saklanması** | Öğün yaşadıkça saklanır. 1 yıldan eski fotoğrafların yalnızca `md` varyantı tutulur | Fotoğrafları 90 gün sonra silmek (maliyet ve gizlilik), değerleri tutmak | F5 |
| 13 | **TestFlight / sandbox satın alımları** | Production DB'de sandbox olaylar premium vermez. İç test kullanıcılarına admin'den promosyon premium verilir | Sandbox'ı production'da da kabul etmek | F8 |
| 14 | **22 planın çevirileri** | Ürün dokümanı İngilizce. tr/de/es/fr/it/ru çevirileri profesyonel çeviri veya ekip incelemesiyle | Lansmanda yalnızca en + tr | F2 |
| 15 | **Premium plan dağılımı** | Ücretsiz: 12:12, 13:11, 14:10, 15:9, 16:8. Premium: 17:7+, OMAD, haftalık, Early/Late, özel | Özel planları da ücretsiz yapmak (dokümanda "mutlaka bulunmalı" deniyor; bulunması ücretsiz olmasını gerektirmez) | F2 |
| 16 | **Hesap silme bekleme süresi** | 7 gün (yanlışlıkla silmeye karşı; uygulamada açıkça yazılır) | Anında silme (Apple ikisini de kabul ediyor) | F10 |
| 17 | **Açlık skorlama ağırlıkları** | [05 §5](05-is-kurallari.md#5-açlık-check-in-skorlaması) tablosu (v1) | Bir diyetisyen tarafından gözden geçirilmesi **önerilir** | F4 |
| 18 | **Sağlık durumu onboarding adımı** | Eklenir (hamilelik, emzirme, yeme bozukluğu, diyabet, ilaç, kalp, hiçbiri) | Eklenmez (yalnızca genel uyarı); ürün dokümanının güvenlik notuyla çelişir | F1 |
| 19 | **Barındırma sağlayıcısı** | AB (Frankfurt). Tek VPS (PM2 + Nginx) + MySQL; Redis yok (ADR 0005) | Türkiye'de barındırma (KVKK yurt dışı aktarım yükünü azaltır, ancak Anthropic/FCM yine yurt dışıdır) | F0 |
| 20 | **Admin paneli arayüzü** | Ayrı proje: React + Refine (veya AdminJS) | Basit sunucu taraflı panel | F10 |
| 21 | **Ürün analitiği** | PostHog (AB bulutu), sunucu tarafı olaylar, rıza ile | Firebase Analytics / Amplitude | F10 |
| 22 | **HealthKit / Health Connect** | V1'de manuel giriş; sync uçları hazır. İstemci entegrasyonu M2 sonrası | Lansmanda zorunlu | F4 |
| 23 | **Çevrimdışı mod** | Su, öğün, kilo ve açlık kayıtları için yerel kuyruk (sunucu zaten idempotent) | Yalnızca çevrimiçi | F4 |
| 24 | **E-posta ile giriş** | Yok (Apple, Google — Firebase üzerinden — ve misafir yeterli). Firebase'de e-posta/şifre açmak kolay; backend `FIREBASE_SIGN_IN_PROVIDERS`'a `password` eklenince kabul eder | Magic link (Android'de Google hesabı olmayanlar için) | – |

## Hukuk danışmanlığı gerektirenler

- **KVKK:**
  - Aydınlatma metni ve açık rıza metinleri (sağlık verisi, AI işleme, yurt dışı aktarım).
  - VERBİS kaydı.
  - Standart sözleşmeler: Anthropic, Google, RevenueCat ve Sentry ile.
- **Tıbbi feragatname metni:** Uygulama ve AI yanıtları için.
- **18 yaş altı politikası** (#1).
- **Pazarlama ifadeleri:** "2M+ active squishes", "4.8 rating", "Trusted by 200K+". Gerçek veriye dayanmayan sayılar yanıltıcı reklam riski taşır; lansmanda gerçek değerlerle değiştirilmeli veya kaldırılmalıdır.
