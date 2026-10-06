# 13 — Flutter Entegrasyonu (istemcide yapılacaklar)

Backend'in değer üretebilmesi için mobil uygulamada yapılması gereken değişiklikler aşağıda dosya referanslarıyla listelenmiştir.
Fazlar [12-yol-haritasi.md](12-yol-haritasi.md) ile hizalıdır.

## 1. Ağ katmanı (F1)

| # | Değişiklik | Dosya |
|---|---|---|
| 1 | `baseUrl` flavor/ortam bazlı olmalı (`--dart-define=API_BASE_URL`). Yollar `/v1` önekiyle | `lib/core/utils/constants/string_constants.dart` |
| 2 | `LanguageInterceptor` cihaz dilini değil **uygulamada seçili dili** (`context.locale` / `LocalizationManager`) göndermeli | `lib/core/network/interceptors/language_interceptor.dart` |
| 3 | Yeni `ContextInterceptor`: `X-Timezone` (`flutter_timezone`), `X-App-Version` (`package_info_plus`), `X-Platform`, `X-Install-Id` | yeni |
| 4 | POST isteklerine `Idempotency-Key` (UUID). İstemcinin ürettiği `id` alanı da gönderilir (UUIDv7, `uuid` paketi) | `NetworkManager` |
| 5 | `ExpiredTokenInterceptor` tamamlanmalı (aşağıdaki listeye bakın) | `expired_token_interceptor.dart` |
| 6 | `NetworkException`: `error.code`, `error.details`, `requestId` alanları parse edilir. UI kararları **koda** göre verilir | `network_exception.dart` |
| 7 | `BaseResponse`: liste yanıtları `data.items` + `data.pageInfo` biçiminde gelir. Ortak `PagedResponse<T>` modeli eklenir | `base_response.dart` |
| 8 | Hata kodlarına özel davranış (aşağıdaki listeye bakın) | yeni `ErrorHandler` |
| 9 | Zaman: Tüm `DateTime`'lar ISO-8601 UTC olarak gönderilir/alınır (`toUtc().toIso8601String()`), UI'da `toLocal()` | modeller |
| 10 | Katalog uçları için `dio_cache_interceptor` (ETag/304) | `dio_client.dart` |
| 11 | SSE ve fotoğraf analizi için uygun timeout'lar: sohbet `receiveTimeout` 120 sn veya stream modu | `dio_client.dart` |

**#5 — Refresh akışı:**
- 401 `TOKEN_EXPIRED` geldiğinde **tek uçuşlu** (single-flight) refresh yapılır: diğer istekler kuyrukta bekler.
- Refresh başarılıysa kuyruktaki istekler yeni token ile tekrar denenir.
- `REFRESH_REUSED` veya `UNAUTHENTICATED` gelirse `AuthLoggedOut` tetiklenir.

**#8 — Hata kodlarına göre davranış:**

| Kod | Davranış |
|---|---|
| `PREMIUM_REQUIRED` | Paywall göster |
| `QUOTA_EXCEEDED` | Kota ekranı + paywall |
| `APP_UPDATE_REQUIRED` | Zorunlu güncelleme diyaloğu |
| `UNSAFE_REQUEST` / `SAFETY_ACK_REQUIRED` | Güvenlik ekranı |

## 2. Kimlik doğrulama (F1)

| # | Değişiklik | Dosya |
|---|---|---|
| 1 | **Firebase Authentication:** `firebase_core`, `firebase_auth` + `sign_in_with_apple`, `google_sign_in`; `flutterfire configure`. Apple/Google ile Firebase'e giriş → `user.getIdToken()` → `POST /v1/auth/register {provider:"firebase", idToken, fullName?, deviceId}` → **backend token'ları** (access/refresh) saklanır. Firebase anonim girişi KULLANILMAZ | `pubspec.yaml`, `auth_repository.dart` |
| 2 | `WelcomeBloc._fakeLogin()` ve login ekranındaki sahte akış → `AuthRepository.login(...)` | `welcome_bloc.dart`, `login_view*` |
| 3 | **`local-onboarding-session` kaldırılır.** Onboarding'in ilk adımında `POST /v1/auth/guest` çağrılır, gerçek token saklanır | `good_company_view_mixin.dart`, entry akışı |
| 4 | `DeviceManager.getDeviceId()`: **cihaz başına sabit** `installId` (cihaz başına tek misafir). iOS: Keychain'de saklanan UUID (yeniden kurulumda korunur). Android: `ANDROID_ID`'den türetilen UUID | `device_manager.dart` |
| 5 | `AuthBloc` başlangıçta önbellekteki kullanıcıyı (`getUser()`) yükler, ardından `/v1/user/me` ile doğrular. Splash token varsa `/home`'a yönlendirir (şu an hep `/entry`) | `auth_bloc.dart`, splash |
| 6 | Router `_protectedPaths` doldurulur (oturumsuz kullanıcı korumalı ekranlara giremez) | `app_router.dart` |
| 7 | Misafirden sosyal hesaba geçişte `409 ACCOUNT_LINK_CONFLICT` diyaloğu: "Bu Apple hesabı başka bir MochiFast hesabına bağlı. O hesaba geç / verilerimi taşı" | yeni |
| 8 | Çıkış: `POST /v1/auth/logout` + `FirebaseAuth.signOut()` + yerel temizlik. Hesap silmede Apple için `revokeTokenWithAuthorizationCode` (F10) | `auth_repository.dart` |
| 9 | Girişten sonra RevenueCat `Purchases.logIn(user.id)` (F8) | `revenue_cat_service.dart` |

## 3. Onboarding (F1)

- Onboarding BLoC'ları `registerFactory` olduğundan cevaplar ekrandan çıkınca kayboluyor. Çözüm: Onboarding boyunca yaşayan **tek bir `OnboardingCubit`** (ShellRoute scope'unda veya `registerLazySingleton`). Bu cubit tüm adımların cevaplarını toplar.
- GoodCompany ekranında `POST /v1/user/onboarding` çağrılır. Yanıttaki `projection`, `plan` ve `targetDate`, BuildingPlan ve WeightProjection ekranlarındaki **sabit değerlerin** (74 kg, 172 cm, 0.4 kg/hafta) yerine kullanılır.
- **Engeller (obstacles):** Çoklu seçime çevrilir (metin "Pick all that ring true" diyor).
- **Öğün penceresi:** Doğrulama eklenir (bitiş ≠ başlangıç; plan yeme süresiyle tutarsızsa uyarı).
- **Yeni adım önerisi — "Sağlık durumu":** hamilelik, emzirme, yeme bozukluğu öyküsü, diyabet, ilaç kullanımı, kalp rahatsızlığı, hiçbiri. Ayrıca açık rıza ekranları (sağlık verisi, AI işleme) eklenir. Bkz. [05 §2.6](05-is-kurallari.md#26-sağlık-güvenliği-kuralları), [06 §8](06-guvenlik.md#8-kvkk--gdpr).
- **Enum ve değer eşlemeleri** (`@JsonValue`):

  | İstemci | API |
  |---|---|
  | `OnboardingFastingPlan.twentyFour` | `"20_4"` |
  | `sixteenEight` | `"16_8"` |
  | `superMood` / `superFeeling` | `"super"` |

  Plan kodları katalogdan gelir; enum'lar zamanla kaldırılabilir.

## 4. Ekran bazında sabit kodlanmış veriler → API

| Ekran / dosya | Kaldırılacak | Yerine |
|---|---|---|
| `home_bloc.dart` | Hata yedeği `Squish`, streak 3 | `GET /v1/user/summary` + hata durumu UI'ı |
| `home_loaded_body.dart` | `streakDays > 0 ? … : 3` | `progress.streakDays` |
| `home_week_strip.dart` | Bugün `10` sa | `summary.week[]` |
| `home_fasting_card.dart` | `6:12:39` | `summary.activeFast` (+ `serverTime` saat kayması düzeltmesi) |
| `home_metric_cards.dart` | 600/2500, 1000/8000 | `summary.today` |
| `home_weight_card.dart` | 102.5 / 112.2 / 75.2 | `summary.weight` |
| `home_meal_records_card.dart` | "July 1, 12:53" | `summary.today.lastMeal` |
| `home_challenge_card.dart` | 8954, Join no-op | `summary.featuredChallenge`, `POST /challenges/:code/join` |
| `home_metabolic_card.dart` | 0.72 / 0.45 / 0.88 | Faz 7+ (şimdilik kart gizlenebilir) |
| `fasting_view.dart` | `_progress 0.10`, `01:44:14`, streak 3, plan varsayılanı | `GET /v1/fasts/active`, `GET /v1/plans/current` |
| `fasting_finish_view.dart` | Kilo 102.5…, kaydetmeme | `POST /v1/fasts/:id/finish` (feeling, notes, weightKg) |
| `fasting_first_time_view.dart` | Her seferinde göster | `finish.isFirstFast` |
| `fasting_body_status_view.dart` | Elle seçilen evre | `activeFast.stage` + `GET /catalog/stages` |
| `fasting_fast_forecast_card.dart` | %87, 14:00… | `GET /v1/fasts/forecast` (yoksa kartı gizle) |
| `fasting_mochi_plan_card.dart` | Sabit metin | `GET /v1/fasts/daily-tip` |
| `plans_catalog.dart`, `fasting_plan_options_catalog.dart` | Yerel kataloglar | `GET /v1/catalog/plans`. Plan detayı "Start this plan" → `PUT /v1/plans/current` (özel saatler dahil). Kahvaltı/akşam tonunda sabit 6 sa yeme süresi hatası düzeltilir |
| `water_view*`, `water_widget_sync.dart` | 100/2500, yerel toplam, gece yarısı sıfırlanmama | `GET/POST /v1/water…`, widget sunucu toplamından |
| `water_reminder_view.dart` | 2000 varsayılan | `GET /v1/user/goals` |
| `steps_view*` | Haftalık mock | `GET /v1/steps` |
| `sleep_view.dart` | Tamamen mock | `GET /v1/sleep/summary` (+ giriş ekranı yeni) |
| `calories_tracker_view*` | 3143, 273, makrolar, 651 | `GET /v1/nutrition/day` |
| `calories_result_view.dart` | Çeviri dosyasındaki sonuç | Fotoğraf analizi akışı (F6) |
| `protein_tracker_view.dart` | 75/120, 3 sabit öğün | `GET /v1/nutrition/day`, `/week?metric=protein` |
| `meal_records_view*`, `meal_detail_view*` | Mock zaman çizelgesi, kaydetmeme | `GET/POST/PATCH/DELETE /v1/meals` |
| `hunger_fourth_question_view_mixin.dart` | `Random().nextBool()` | `POST /v1/hunger-checkins/evaluate`. Q1–Q4 cevapları `HungerFlowArgs` ile taşınır |
| `hunger_history_log_view*` | Mock | `GET /v1/hunger-checkins`, `/summary` |
| `body_history_view*` | Mock + sabit Y ekseni + Türkçe ay harfleri | `GET /v1/weights/chart`, `/summary` |
| `profile_view.dart` | `Atilla E.`, `AE`, streak 3, premium true | `summary.user` + `progress` |
| `edit_profile_view_mixin.dart` | Tüm mock alanlar | `GET/PATCH /v1/user/profile`, `PUT /v1/user/me/avatar` |
| `notifications_view_mixin.dart` | 2 mock kayıt | `GET /v1/notifications` |
| `chat_session_cubit.dart` | Hazır cevaplar, seed geçmiş | `/v1/chat/*` + SSE |
| `insights_*` | Çeviri JSON içeriği | `/v1/insights/*` |
| `mochi_world_view.dart` | `_zones`, `_worldProgress`, `_health`, "Level 1" | `GET /v1/world` (istemci `level` alanını kullanır, `round(oran·4)` kaldırılır) |
| `good_company`, premium kartı | 2M+, 4.8, 200K+ | `GET /v1/app/config.marketing` |
| `fasting_widget_sync.dart` | Hafta yedeği `[0.75,0,…]` | `GET /v1/fasts/week` |

## 5. Medya (F5)

- Kamera ve galeri çıktısı **≤ 2048 px uzun kenar, JPEG kalite 85** olmalı (`flutter_image_compress` veya `image_picker` parametreleri). HEIC gönderilmez.
- Yükleme `multipart/form-data` (`FormData`) ile yapılır. İlerleme göstergesi için `onSendProgress` kullanılır.
- `cached_network_image` → `cacheKey: '${mediaId}_${variant}'`. Böylece imzalı URL değişse bile cache korunur.
- Görsel yüklenemezse (403, süre dolmuş) ilgili kaynak yeniden çekilir.

## 6. Sohbet (F6)

- SSE istemcisi: `dio.post(..., options: Options(responseType: ResponseType.stream, headers: {'Accept': 'text/event-stream'}))`.
  - Gelen veri `utf8.decoder` + `LineSplitter` ile ayrıştırılır.
  - `event:` / `data:` satırlarına göre `delta`, `message.completed` ve `error` olayları işlenir.
- `ChatMessage` modeline şu alanlar eklenir: `createdAt`, `status`, sunucu ID'si.
- Geçmiş konuşmaya dokununca mesajları yükleme özelliği eklenir (şu an çalışmıyor).
- "Typing" göstergesi `message.created` ile `message.completed` arasında açık kalır.
- `safety: "urgent"` meta verisi gelirse acil durum kartı gösterilir.

## 7. Bildirimler (F9)

- `firebase_messaging` kurulur. İzin istemi onboarding'den hemen sonra değil, ilk oruç başlatıldığında "hedefe ulaşınca haber verelim mi?" bağlamında gösterilir.
- Token alındığında ve yenilendiğinde `PUT /v1/devices/current` çağrılır.
- Derin linkler: `fastingapp://fasting|water|body-history|mochi-world|home|profile|body-status` → go_router eşlemesi.
- Inbox: `hoursAgo` yerine `createdAt`. Gün bazında gruplama ("Today", "Yesterday", tarih).
- Profil → Push Notifications anahtarı ve kategori ayarları → `PATCH /v1/user/settings`.

## 8. Lokalizasyon

- `LocalizationManager.supportedLocales` listesine `it` ve `ru` eklenir (dosyaları mevcut).
- Dil seçim ekranındaki dosyası olmayan diller (pt, ko, hi, ja) ya kaldırılır ya da "yakında" olarak işaretlenir.
- Dil değişince `PATCH /v1/user/me {locale}` çağrılır. Böylece push ve inbox dili de değişir.

## 9. Çevrimdışı dayanıklılık (opsiyonel, F4 sonrası)

- Su, öğün, kilo ve açlık kayıtları çevrimdışıyken yerel bir kuyrukta (Hive/Isar/sqflite) tutulur.
- Her kayıt istemcide üretilen UUIDv7 ile oluşturulur. Ağ gelince sırayla gönderilir.
- Sunucu idempotent olduğu için yeniden denemeler güvenlidir.
- Aktif oruç çevrimdışı başlatılırsa yerel saat kaydedilir ve sonra `POST /fasts {id, startedAt}` gönderilir.

## 10. Sözleşme güvenliği

- Backend CI her build'de `openapi.json` üretir.
- Kısa vade: Dart modelleri elle yazılır, ama bir **sözleşme testi** (OpenAPI şemasına karşı örnek yanıt doğrulama) eklenir.
- Orta vade: `openapi-generator` (dart-dio) veya `swagger_parser` ile model üretimine geçilir.
