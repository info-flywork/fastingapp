# 05 — İş Kuralları & Formüller

Bu belgedeki her kural kodda `src/modules/<modül>/<modül>.rules.js` içinde **saf fonksiyon** olarak yazılır.
Hepsi tablo tabanlı birim testlerle %100 kapsanır. Parametreler (eşikler, puanlar) mümkün olduğunca
`app_config` tablosundan okunur, böylece deploy gerekmeden ayarlanabilir.

## 1. Oruç seansı durum makinesi

```
                 POST /fasts                       POST /fasts/:id/finish
   (yok) ───────────────────────► active ─────────────┬─────────────────► completed   (süre ≥ hedef)
                                    │                 └─────────────────► ended_early (1 dk ≤ süre < hedef)
                                    │ POST /fasts/:id/cancel
                                    ├────────────────────────────────────► cancelled   (istatistiğe girmez)
                                    │ 72 sa dolunca (sistem)
                                    └────────────────────────────────────► completed + auto_closed
```

### 1.1 Başlatma
- Kullanıcı başına **en fazla 1** `active` seans olabilir. DB'de `uq_fasting_one_active` ile garanti altında.
- `targetMinutes` verilmezse aktif plandan alınır. Haftalık planlarda o günün `weeklySchedule` girdisi kullanılır.
- `startedAt` geçerli aralığı: `[now − 7 gün, now + 5 dk]`. İstemci −30 güne izin veriyor; geçmiş için `POST /fasts/manual` kullanılır.
- Kullanıcının mevcut seanslarıyla `[startedAt, plannedEndAt]` aralığı çakışamaz (`FAST_OVERLAP`).
- `plannedEndAt = startedAt + targetMinutes`.

### 1.2 Bitirme
- `endedAt` geçerli aralığı: `[startedAt + 1 dk, now + 5 dk]`.
- `durationMinutes = floor((endedAt − startedAt) / 60 sn)`.
- `goalReached = durationMinutes ≥ targetMinutes`. Buna göre durum `completed` ya da `endedEarly` olur.
- `endedAt` hedefin çok ötesindeyse (> hedef + 12 sa) yanıtta `warnings: ["LONG_OVERRUN"]` döner. İstemci "Gerçekten bu saatte mi bitirdin?" diye sorabilir.
- Bitiş ekranında kilo girildiyse `weight_entries` kaydı (`source = fasting_finish`) oluşturulur ve seansa bağlanır.
- `isFirstFast = (user_stats.first_fast_completed_at IS NULL)` ve bu seans `completed`. Bu durumda ilk oruç kutlaması gösterilir.

### 1.3 İptal ve otomatik kapanış
- **İptal (10 dk kuralı):** Başlangıçtan sonraki 10 dk içinde iptal edilirse satır fiziksel olarak silinir. Daha sonra ise `cancelled` olarak işaretlenir.
- **Otomatik kapanış:**
  - `planned_end_at + 12 sa` anında "Orucunu bitirmeyi unuttun mu?" bildirimi gönderilir.
  - `started_at + 72 sa` anında seans `completed` + `auto_closed = 1` olur. `ended_at = planned_end_at` (hedefe ulaşıldığı varsayılır), kullanıcıya düzeltmesi için bildirim gider (F9). `fast-autoclose` işi 15 dakikada bir çalışır. Otomatik kapanan seans XP ve seriye sayılır, en uzun oruç rekoruna sayılmaz.
  - Davranış [14 #3](14-acik-kararlar.md)'e göre değiştirilebilir.

### 1.4 Seansın güne atanması
- Seansın **tüm süresi bitiş gününe** (`end_local_date`, seansın `tz`'sine göre) yazılır. Hafta şeridi ve seri bu değere bakar.
- Bu yaklaşım "bugün 16 sa oruç tuttun" diliyle örtüşür. Alternatif (süreyi gece yarısından bölmek) için bkz. [14 #2](14-acik-kararlar.md).
- Aktif (bitmemiş) seans, hafta şeridinde bugüne **canlı** olarak eklenir. Değer DB'ye yazılmaz, yanıt anında hesaplanır.

### 1.5 Sayaçlar
| Sayaç | Tanım |
|---|---|
| `completed_fasts` | `status = completed` |
| `total_fasts` | `completed + ended_early` ve `duration ≥ 60 dk` |
| `total_fasted_minutes` | `completed + ended_early` seansların süre toplamı |
| `longest_fast_minutes` | max süre (`auto_closed` seanslar hariç) |
| `avg_fast_minutes` | `total_fasted_minutes / total_fasts` |

### 1.6 Düzenleme ve silme
- Tamamlanmış seans düzenlendiğinde veya silindiğinde `stats.recompute(userId, fromLocalDate = min(eski, yeni gün))` çalışır.
- Bu işlem `daily_summaries`, seri, dünya ve XP'yi yeniden hesaplar ([07 §5](07-cache-performans.md#5-günlük-özetler-rollup)).

## 2. Planlar

### 2.1 Günlük planlar (12:12 … 23:1, OMAD)
- `fastMinutes = fast_hours × 60`. OMAD için 23 sa.
- Zamanlama tercihine göre yeme penceresi:

| Tercih | Yeme penceresi (varsayılan) |
|---|---|
| `skipBreakfast` | `[12:00, 12:00 + eat]` |
| `skipDinner` | `[08:00, 08:00 + eat]` |
| `earlyWindow` | `[07:00, 07:00 + eat]` |
| `lateWindow` | `[14:00, 14:00 + eat]` |
| `custom` | Kullanıcının seçtiği başlangıç. Bitiş = başlangıç + eat. İstemci bitişi de gönderebilir; bu durumda `fastMinutes = 1440 − pencere` olur ve `[12 sa, 23 sa]` aralığında olmalıdır |

> Not: İstemcideki plan detay ekranı kahvaltı/akşam tonları için yeme süresini sabit **6 saat** gösteriyor (Figma kalıntısı).
> Backend her zaman planın gerçek `eat_hours` değerini döner; istemci bunu düzeltmelidir ([13](13-flutter-entegrasyonu.md)).

### 2.2 Haftalık planlar
| Plan | Program |
|---|---|
| 5:2 | Haftada 2 "azaltılmış alım" günü (`reduced_day_kcal`, varsayılan 500), diğer 5 gün normal. Kullanıcı hangi günler olduğunu seçer (`weeklySchedule`). **Ardışık olmamalı** (doğrulama) |
| 6:1 | 1 azaltılmış gün |
| Alternate-Day | Gün aşırı: oruç günü = **azaltılmış alım** (≈ 500 kcal). Ürün notu ≥24 sa açlığı teşvik etmememizi söylüyor; o yüzden ADF bir 24 sa sayaç olarak modellenmez |
| Crescendo | Haftada 2–3 ardışık olmayan gün **12–16 sa** oruç; diğer günler serbest |

- **Azaltılmış gün nasıl "tutuldu" sayılır?** Kullanıcı gün sonunda işaretler (`PUT /v1/plans/days/:date {status:"done"}`) ya da o gün kayıtlı kalori ≤ `reduced_day_kcal + 100` ise sistem otomatik "done" önerir.
- Bu işaretler `plan_day_checkins` tablosunda tutulur ([03 §3.3](03-veri-modeli.md#33-plan-kataloğu--kullanıcı-planı-0003_planssql)).

### 2.3 Özel planlar
- **Custom Daily:** `fastMinutes ∈ [720, 1380]`. Pencere başlangıcı serbest.
- **Custom Weekly:** Gün başına `type ∈ {fast, normal, reduced}`. `fast` günler için `fastMinutes ∈ [720, 1380]`.

### 2.4 Plan değişimi
- Yeni plan **bir sonraki** oruçtan itibaren geçerli olur. Aktif oruç bozulmaz.
- Plan geçmişi `user_plans` tablosunda kalır. Geçmiş günlerin hedefleri `daily_summaries.fast_goal_minutes` anlık görüntüsünden okunur.

### 2.5 Premium
- `fasting_plans.is_premium = 1` olan bir plan seçilirken entitlement yoksa 402 döner.
- **Abonelik biterse:**
  - Mevcut premium plan **hemen kesilmez**. Aktif oruç ve o gün etkilenmez.
  - Ertesi gün hesaplamasında plan ücretsiz eşdeğerine düşer (ör. 18:6 → 16:8) ve kullanıcıya bildirim gider.
  - Davranış [14 #8](14-acik-kararlar.md)'e göre değiştirilebilir.

### 2.6 Sağlık güvenliği kuralları

Ürün dokümanı uygun güvenlik mesajlarını açıkça istiyor. Kurallar **sunucuda zorunlu olarak uygulanır**, istemci yalnızca gösterir.

| Koşul | Kural |
|---|---|
| Yaş < 18 (`birth_year`'dan) | Yalnızca `min_age ≤ yaş` planları (öneri: 12:12–14:10). Weekly/Advanced → 422 `UNSAFE_REQUEST`. AI koç kilo verme hedefi önermez. Ürün kararı: 18 yaş altını tamamen engellemek ([14 #1](14-acik-kararlar.md)) |
| `pregnant` / `breastfeeding` | Yalnızca 12:12 ve 13:11. Kalıcı uyarı. Kalori açığı hesaplanmaz (kcal hedefi = TDEE) |
| `eating_disorder_history` | Advanced/Weekly kapalı. Kalori hedefi **gösterilmez** (null). AI koç yeme bozukluğu korkuluğuyla çalışır. Profilde destek kaynakları |
| `diabetes` / `medication` / `heart_condition` | > 14 sa planlarda `requiresSafetyAck` zorunlu + "doktoruna danış" mesajı |
| Hedef kilo BMI < 18.5 | Uyarı (`GOAL_BMI_BELOW_18_5`). BMI < 17.5 → 422 |
| Haftalık kayıp hedefi | En fazla 1.0 kg/hafta (varsayılan 0.4) |
| Oruç hedefi > 24 sa | Yalnızca manuel/özel girişte, `safetyAcknowledged` ile. **Ek XP veya bonus yok** ("daha zor = daha iyi" teşvik edilmez). > 48 sa → ek uyarı. Mutlak üst sınır 72 sa |
| Açlık check-in güvenlik bayrağı | §5.3 |

> Onboarding'e önerilen yeni adım: **"Sağlık durumu"** (çoklu seçim + "Hiçbiri").
> Bu adım olmadan `health_flags` boş kabul edilir ve yalnızca yaş kuralı uygulanır.

## 3. Seri (streak)

### 3.1 Gün durumu

Her yerel gün **D** için:

| Durum | Koşul |
|---|---|
| **zorunlu gün** | Günlük planlarda her gün. Haftalık/özel planlarda `weeklySchedule[D].type ∈ {fast, reduced}` |
| **nötr gün** | Haftalık planlarda `normal` gün |
| **tutulmuş gün** | Zorunlu oruç günü ise `fasted_minutes(D) ≥ 0.8 × fast_goal_minutes(D)`. Azaltılmış gün ise `plan_day_checkins(D).status = done` |

%80 toleransı `app_config.streak.keep_ratio` ile ayarlanır. Kullanıcı 16 saatlik planda 13 sa tutarsa seri bozulmaz; motivasyon için daha affedicidir.

### 3.2 Hesaplama

```
streak = 0
D = bugün
eğer bugün zorunlu ve henüz tutulmadıysa → D = dün      // bugün hâlâ sürüyor, seriyi bozmaz
döngü:
  eğer D nötr ise → streak += 1, D = D − 1               // planına uyuyor sayılır
  aksi hâlde eğer D tutulmuş → streak += 1, D = D − 1
  aksi hâlde dur
  (D, kullanıcının ilk plan gününden önceyse dur)
best_streak = max(best_streak, streak)
```

- Hesap `daily_summaries` + `plan_day_checkins` üzerinden yapılır (tek sorgu). Uygulama (`stats.rules.js#computeStreaks`) aynı kuralı ilk günden bugüne **ileri doğru** yürütür; böylece tek geçişte `current`, `best_streak` ve geçmişteki her seri için kilometre taşları bulunur. Kullanıcı başına birkaç yüz gün, bellekte mikrosaniyeler sürer.
- Boş günün tipi (zorunlu/nötr) ve hedefi, o gün geçerli plandan çözülür: `started_on ≤ D` olan en son plan (aynı gün değiştiyse yenisi). Hiç plan yoksa günlük 16 sa.
- Haftalık planın oruç (`fast`) günü, %80 kuralı **ya da** `done` check-in ile tutulur.
- Tetikleyiciler:
  - `fast.finished`
  - düzenleme veya silme
  - gün dönümü işi (yerel 00:05)

**Seri bozulduğunda:** bildirim gider (`streak_lost`), dünyanın sağlığı etkilenir (§7).

**Seri kilometre taşları:** 3, 7, 14, 30, 60, 100 gün. Her birinde XP verilir (§10) ve bildirim gider (F9). Taş **her seri için bir kez** verilir (`ref_key = "<gün>:<serinin ilk günü>"`): seri bozulup yeniden 7'ye ulaşırsa XP yine kazanılır. Düzenleme/silme seriyi geriye dönük bozarsa ilgili taşın XP'si de düşer (deterministik yeniden hesaplama).

**Seri dondurma (streak freeze):** Premium için faz 2 özelliği, [14 #9](14-acik-kararlar.md).

## 4. Vücut evresi

```
stage(elapsedHours) = son evre e öyle ki e.start_hour ≤ elapsedHours
nextStageAt = startedAt + nextStage.start_hour
```

Eşikler: 0, 2, 5, 8, 12, 16, 18, 24, 48 sa (katalogdan okunur).

**Yeme penceresi evresi.** Bitişten sonra, `eatMinutes` = plan yeme süresi olmak üzere:

| Evre | Pencerenin zaman dilimi |
|---|---|
| `break` | İlk %20 (en az 30 dk) |
| `nourish` | Ortası |
| `next` | Son 60 dk |

Bir sonraki orucun önerilen başlangıcı: `endedAt + eatMinutes` ya da planın yeme penceresi bitişi (hangisi daha yakınsa).

## 5. Açlık check-in skorlaması

İstemcideki `Random().nextBool()` kaldırılır. Sonuç **sunucuda** hesaplanır.

### 5.1 Puan tablosu (v1)

| Soru / cevap | Fiziksel (P) | Duygusal (E) |
|---|---|---|
| Q1 basit yemek: `yes` | +2 | |
| Q1: `notReally` | | +2 |
| Q2 başlangıç: `gradually` | +2 | |
| Q2: `suddenly` | | +2 |
| Q3: her biri `stomachGrowling`, `lowEnergy`, `fatigue` | +1 (toplam en fazla +2) | |
| Q3: `dizziness`, `nausea` | +1 her biri | |
| Q3: `nothingPhysical` | | +2 |
| Q4 istek: `almostAnything` | +2 | |
| Q4: `somethingSweet` | | +2 |
| Q4: `fastFood` | | +1 |
| `notSure` cevapları | 0 | 0 |
| Bağlam: aktif oruç ≥ planın %75'i ve P ≥ 1 | +1 | |

### 5.2 Sonuç
- `resultType = P ≥ E ? physical : emotional`.
- Eşitlikte `physical` seçilir. Gerçek açlığı "duygusal" diye geçiştirmemek daha güvenlidir.
- `scoring_version` her kayıtla saklanır. Tablo değişirse eski kayıtlar etkilenmez.
- Öneriler: `physical` → `physical_1..3`, `emotional` → `emotional_1..4` (`catalog_labels`, ad alanı `hunger_rec`; metinler uygulamanın `hunger_result_page.*_rec_*` çevirilerinden çıkarılır). Dile göre döner.
- Bağlam, kayıt anındaki aktif orucun süresi ve hedefidir; kayıtla birlikte saklanır (`fasting_session_id`, `fasted_minutes`).

### 5.3 Güvenlik bayrağı
`safetyFlag = true` olur, eğer:
- Q3'te (`dizziness` **ve** `nausea`), ya da
- (`dizziness` **veya** `nausea`; Q3'te ya da belirtilerde) **ve** aktif oruç > 16 sa, ya da
- belirtilerde `dizziness` + `weakness`.

Bayrak açıkken yanıtta öncelikli öneri olarak "Kendini iyi hissetmiyorsan orucunu bitirmen tamamen normal" (`hunger.safety_end_fast`) döner. İstemci bu öneriyle birlikte "Orucu bitir" kısayolunu gösterir.

## 6. Beslenme hedefleri

### 6.1 Bazal metabolizma (Mifflin–St Jeor)
```
BMR = 10·kg + 6.25·cm − 5·yaş + s
s = +5 (man), −161 (woman), −78 (nonBinary / preferNotToSay — ortalama)
```

### 6.2 Günlük harcama
`TDEE = BMR × 1.2 + adım_kcal` (adım_kcal: §8)

### 6.3 Kalori hedefi (`user_goals.kcal_goal` NULL ise hesaplanır)
| Koşul | Hedef |
|---|---|
| `goal = loseWeight` | `TDEE − açık`. `açık = weekly_loss_target_kg × 7700 / 7` (0.4 kg → 440 kcal), en fazla 750 |
| Diğer hedefler veya hamilelik/emzirme | `TDEE` |
| Taban | woman 1200, man 1500, diğer 1350 |
| `eating_disorder_history` | `null` (hedef gösterilmez) |

### 6.4 Makrolar
- **Protein:** `1.2 g × kg`. BMI ≥ 30 ise hedef kiloya göre hesaplanır. En fazla 160 g.
- **Kalan kalori** diyete göre dağıtılır:

| Diyet | Karbonhidrat | Yağ |
|---|---|---|
| `lowCarb` | %20 | %80 |
| `mediterranean` | %50 | %50 |
| diğer | %60 | %40 |

- **Dönüşüm:** karb = kcal/4, yağ = kcal/9.

### 6.5 Gösterim değerleri
- `overKcal = max(0, yenen − hedef)`
- `burnedKcal = BMR × (geçen_dakika / 1440) + adım_kcal` (bugün için)

### 6.6 Hesaplama girdileri
- **Yaş:** `bu_yıl − birth_year`.
- **Kilo:** Son kilo kaydı. Yoksa `start_weight_kg`.

## 7. Mochi World

### 7.1 Bölge metrikleri (birikimli, geri düşmez)

| Bölge | Metrik | Kaynak | Eşikler (seviye 1→4) |
|---|---|---|---|
| Orman (forest) | Tamamlanan oruç | `user_stats.completed_fasts` | 3, 10, 25, 50 |
| Göl (lake) | Su hedefinin tutturulduğu gün | `user_stats.water_goal_days` | 3, 7, 14, 30 |
| Zirve (summit) | Ulaşılan **en iyi** verilen kilo | `user_stats.best_weight_lost_kg = max(start − min(kilo))` | 1, 2, 5, 10 kg |
| Bahçe (garden) | Kaydedilen öğün | `user_stats.meals_logged` | 3, 10, 30, 60 |

- Eşikler `world_zone_thresholds` tablosunda tutulur ve yönetilebilir (`seeds/gamification.json`).
- **Uygulama (F7):** metrikler ham veriden deterministik hesaplanır (`best_weight_lost_kg` = başlangıç − en düşük ölçüm; silinen ölçüm metriği düşürür). Görselin geri gitmemesi `user_world_zones.max_level_reached` ile sağlanır: gösterilen seviye = max(ulaşılan, güncel). Senkron her oruç/takipçi yazmasında aynı transaction'da; seviye yükselişi `levelUps` olarak döner.
- Göl metriği ve zirvenin "en iyi değer" yaklaşımı ürün kararıdır ([14 #5](14-acik-kararlar.md)). Ada görsel olarak **geri gitmez**; gerileme "sağlık" ile ifade edilir.
- Mevcut mock verisi bu tabloyla uyumlu: forest 3/10 → seviye 1.
- `goal` yönü kilo almak (ör. `buildHabit` + hedef > başlangıç) ise zirve metriği "hedefe yaklaşılan kg" olur.

```
zoneLevel = eşiklerden kaç tanesine ulaşıldı (0–4)
nextThreshold = ulaşılmamış ilk eşik (4'te: null)
ratioToNext = (current − öncekiEşik) / (nextThreshold − öncekiEşik)
sceneLevel = max(zoneLevel)                         // istemcideki mevcut davranış
worldProgress = ortalama( min(1, (zoneLevel + ratioToNext) / 4) )
```

İstemci şu an `round(oran × 4)` kullanıyor. Backend bölge seviyesini **doğrudan** döndüğü için istemci yalnızca `level` değerini kullanmalı ([13](13-flutter-entegrasyonu.md)).

### 7.2 Sağlık (thriving / wilting / drought)

```
sonTutulanGün = en son "tutulmuş" zorunlu gün (§3.1)
boşluk = (bugün − sonTutulanGün) içindeki ZORUNLU gün sayısı (bugün hariç)

boşluk ≤ 1  → thriving
boşluk 2–3  → wilting
boşluk ≥ 4  → drought
Yeni kullanıcı (ilk plan gününden < 2 gün) → thriving
```

- **Toparlanma:** Tek bir tutulmuş gün `boşluk = 0` yapar ve ada hemen `thriving` olur. Bu bilinçli bir seçim: geri dönüşü ödüllendirir.
- **Görsel türetmeler** (istemcide kalabilir, sözleşme): `lushness`, kelebek, kuş, gökkuşağı, hava durumu, taban görseli. Bunlar `sceneLevel` ve `health` değerlerinden türetilir ([01 §2.9](01-uygulama-analizi.md#29-mochi-world-presentationmochi_world)).
- **Tetikleyiciler:** `world_health` her gün dönümü işinde ve `fast.finished` olayında yeniden hesaplanır. Değişince bildirim gider (ör. "Adan kurumaya başladı 🥀", ayarla kapatılabilir).

## 8. Adım & kalori türetmeleri

İstemcideki sabit katsayılar (0.04 / 0.0007 / 0.01) yerine kişiselleştirilmiş formüller:

```
adım_uzunluğu_m = boy_cm × 0.415 / 100          (boy yoksa 0.70 m)
mesafe_km       = adım × adım_uzunluğu_m / 1000
adım_kcal       = adım × 0.04 × (kilo_kg / 70)   (kilo yoksa ×1)
süre_dk         = adım / 100                     (ortalama 100 adım/dk)
```

**Kaynak önceliği** (`step_daily.source`):
- `appleHealth`/`googleFit` > `manual`.
- Sağlık senkronu manuel değerin üzerine yazar.
- Manuel giriş, senkronlanmış bir günün üzerine yazamaz (409).

## 9. Kilo, BMI, projeksiyon

```
BMI = kg / (boy_m)²   (1 ondalık)
```

| BMI | `bmiCategory` | `bmiBand` (istemci uyumu) |
|---|---|---|
| < 18.5 | underweight | low |
| 18.5–24.9 | normal | normal |
| 25–29.9 | overweight | high |
| 30–34.9 | obese1 | high |
| 35–39.9 | obese2 | high |
| ≥ 40 | obese3 | high |

**İlerleme:** `progress = clamp((start − current) / (start − goal), 0, 1)`. Hedef > başlangıç ise işaretler ters çevrilir; `start = goal` ise `progress = 1`.

**Projeksiyon:**
```
weeks = ceil(|current − goal| / weeklyLossKg)
targetDate = today + clamp(weeks × 7, 7, 730) gün
```

**Hedef tarihi (onboarding sebebi):**

| Sebep | Gün sayısı |
|---|---|
| specialDate | 45 |
| trip | 90 |
| healthLongevity | 180 |
| confidence | 120 |

**Grafik kovaları (`/weights/chart`):**

| Aralık | Kovalar |
|---|---|
| day | Son 7 gün; her günün son ölçümü |
| week | Son 7 ISO hafta; haftanın son ölçümü |
| month | Son 7 ay; ayın son ölçümü |

- Ölçüm olmayan kova `null` döner. İstemci çizgiyi atlar.
- `yAxis.min = floor((min − 2) / 5) × 5`, `yAxis.max = ceil((max + 2) / 5) × 5`.
- Etiketler sunucuda `Accept-Language` ile yerelleştirilir (ay kısaltmaları).

## 10. XP ve seviye

**Puan tablosu:**

| Olay | XP | Günlük üst sınır |
|---|---|---|
| Oruç bitirildi (≥ 60 dk, completed/endedEarly) | 10 | – |
| Hedefe ulaşıldı bonusu (hedef ≤ 24 sa ise) | +5 | – |
| Öğün kaydı (öğün ya da ara öğün) | 2 | 5 öğün |
| Su hedefi günü | 5 | 1 |
| Kilo kaydı (onboarding kilosu hariç) | 3 | 1 |
| Açlık check-in | 2 | 3 |
| Challenge tamamlama | `challenges.reward_xp` | – |
| Seri kilometre taşı 3 / 7 / 14 / 30 / 60 / 100 | 20 / 50 / 100 / 200 / 300 / 500 | – |

**Seviye:**
```
gerekenXP(n) = 50 · n · (n − 1)        // L1=0, L2=100, L3=300, L4=600, L5=1000 …
level = gerekenXP(n) ≤ xp koşulunu sağlayan en büyük n
```

**İdempotency:** `xp_events (user_id, reason, ref_key)` birincil anahtardır. Silme veya düzenlemede ilgili XP olayı silinir ve XP yeniden toplanır. Seviye de toplamdan türetilir: silme XP'yi eşiğin altına düşürürse seviye geri iner.

**İlk oruç:** `user_stats.first_fast_completed_at` bir kez yazılır (canlı bitirme ya da elle girilen tamamlanmış oruç), sonra silme/düzenleme ile değişmez; kutlama ekranı iki kez gösterilmez.

## 11. Misafir hesap birleştirme (yok) ve hesaba geçiş

Misafir kullanıcı (`is_guest = 1`) Apple/Google ile giriş yaptığında:

1. **Sosyal kimlik hiçbir hesaba bağlı değilse** → misafir hesabın kendisi yükseltilir:
   - `auth_identities` satırı eklenir.
   - `is_guest = 0`, isim ve e-posta doldurulur.
   - Kullanıcı ID'si **değişmez**, RevenueCat app_user_id aynı kalır.
2. **Sosyal kimlik mevcut bir hesaba bağlıysa:**
   - O hesaba geçilir (soru sorulmaz). **Hesap birleştirme yoktur** (ürün kararı, 2026-10-08): misafirin verisi taşınmaz.
   - Misafir hesap **silinmez**, yalnızca oturumları iptal edilir. Misafir cihazda kalıcı, ayrı bir hesaptır: "Misafir olarak
     devam et" aynı misafiri (verisiyle) açar.
   - Abonelik: RevenueCat'te hesaplar ayrıdır; misafirde satın alma varsa RevenueCat `TRANSFER` olayıyla taşınır.

3. **Misafirler süreyle silinmez** (ürün kararı, 2026-10-08): kullanılmasa da kalır; yalnızca kullanıcı uygulamadan silebilir (Hesabı Sil). Aydınlatma metninde yazılır.

## 12. Su

- Günlük toplam = `SUM(amount_ml)`. Koşullar: `local_date = D AND deleted_at IS NULL`.
- **Gece yarısı sıfırlaması otomatiktir.** Toplam yerel güne göre hesaplandığı için istemcideki sıfırlanmama hatası backend ile ortadan kalkar.
- **Hedef günü:** `water_ml(D) ≥ water_goal_ml(D)` ise `daily_summaries.water_goal_ml` anlık görüntüsü ile karşılaştırılır. Anlık görüntü, o güne yapılan her su/adım/uyku/kilo yazmasında güncel hedefle yenilenir; yazma olmayan geçmiş gün değişmez.
  - Gün ilk kez hedefi geçince `water_goal_days += 1`.
  - Kayıt silinip hedefin altına düşülürse günlük özetten yeniden hesaplanır.
- **Güvenlik:**
  - Tek kayıt en fazla 5000 ml.
  - Günlük toplam 6000 ml'yi aşınca yanıtta `warnings: ["HIGH_WATER_INTAKE"]` döner. İstemci bilgilendirici ipucu gösterir.
- **Hatırlatıcılar:** [10 §4](10-bildirimler.md#4-hatırlatıcı-kuralları).

## 13. Challenge'lar

- **Pencereler:**
  - `rolling`: katılım anında `window_start = now`, `window_end = now + duration_days`.
  - `fixed`: `starts_at` – `ends_at`.
- **İlerleme:** Pencere içindeki ilgili olaylar sayılır.

  | Metrik | Sayılan olay |
  |---|---|
  | `meals_logged` | meals |
  | `fasts_completed` | completed seanslar |
  | `water_goal_days` | su hedefi günleri |
  | `streak_days` | pencere içindeki seri (F7: güncel seri, pencerede geçen gün sayısıyla sınırlı) |
  | `hunger_checkins` | açlık check-in'leri |

  Olaylar artımlı güncellenir. Silmede yeniden sayılır.
- **Tamamlanma:** `progress_count ≥ target_count` olunca `completed`. Ödüller: XP, bildirim, (ileride) rozet.
- **Başarısızlık:** `window_end` geçtiyse ve hedef tutmadıysa saatlik iş `failed` yapar.
- **Katılımcı sayısı:** **Gerçek sayı** gösterilir (`participants_count`). Sahte veya şişirilmiş sayılar tüketici mevzuatı açısından risklidir ([14 #10](14-acik-kararlar.md)).
- **Katılımcı avatarları:** Yalnızca açıkça izin veren kullanıcılar gösterilir. Yoksa jenerik maskot avatarları kullanılır.

## 14. Yeniden hesaplama (recompute) garantisi

Tüm türetilmiş veriler ham tablolardan **deterministik** olarak yeniden üretilebilir. Türetilmiş veriler:
- `daily_summaries`
- `user_stats`
- `user_world_zones`
- XP
- challenge ilerlemeleri

```
stats.recompute(userId, fromLocalDate):
  1. fromLocalDate..bugün için daily_summaries satırlarını ham tablolardan yeniden yaz
  2. user_stats sayaçlarını tam toplamla yeniden hesapla (tek GROUP BY sorgusu)
  3. seri + best_streak (§3)
  4. dünya bölgeleri + sağlık (§7)
  5. XP toplamı + seviye (§10)
  6. aktif challenge ilerlemeleri (§13)
  7. ilgili cache anahtarlarını sil (07)
```

**Tetikleyiciler:**
- Günde bir: son 26 saatte oruç kaydı değişen kullanıcılar için tam yeniden hesaplama (`daily-rollup` işi). Zamanlayıcı yalnızca aralık destekler (`every_ms`); iş, worker'ın ilk açılışından itibaren 24 saatte bir çalışır, sabit 03:30 UTC değil.
- Saatte bir: yerel gece yarısını yeni geçen saat dilimlerindeki serili kullanıcılar (`day-rollover` işi). Okuma uçları da bayat seriyi kendisi yeniler; iş, F9'da `streak_lost` bildirimini zamanında göndermek içindir.
- Elle: `npm run stats:recompute [-- <userId>]` (kural değişikliği, veri düzeltmesi, ilk kurulum).
- Her bitirme, elle kayıt, düzenleme, silme, check-in ve plan değişimi: anında, yazmayla **aynı transaction'da**. Kullanıcı satırı `SELECT … FOR UPDATE` ile kilitlidir; aynı kullanıcının eşzamanlı yeniden hesaplamaları sıraya girer (process içi kilit gerekmez, birden çok API kopyasında da doğru çalışır).
- Maliyet: ~12 sorgu. DB gecikmesi baskın etkendir (yerel ağda ~10–30 ms; geliştirmedeki uzak DB'de ~50 ms × sorgu ≈ 1 sn).
