# 15 — Mağaza gizlilik formları (App Store · Google Play)

Backend'in gerçekte topladığı ve işlediği verilere göre hazırlanmış cevaplar (F11). Uygulamaya
analitik/reklam SDK'sı eklenirse (Firebase Analytics, Facebook SDK vb.) bu tablo **güncellenmelidir**.

Kaynak: veri modeli ([03](03-veri-modeli.md)), KVKK ([06 §8](06-guvenlik.md#8-kvkk--gdpr)).

## Genel cevaplar

| Soru | Cevap |
|---|---|
| Takip (tracking, ATT) | **Hayır.** Reklam yok, veri broker'a/üçüncü tarafa reklam amaçlı veri yok → ATT istemi gerekmez |
| Veriler aktarımda şifreli mi | Evet (HTTPS/TLS, HSTS) |
| Kullanıcı verisinin silinmesini isteyebilir mi | Evet: uygulama içi (Profil → Profili Düzenle → Hesabı Sil) ve web: `https://mochifast-api.fly-work.com/account/delete` |
| Hesap oluşturmadan kullanılabilir mi | Evet (misafir) |
| Veri paylaşımı (Play tanımıyla) | **Hayır.** Aşağıdaki hizmet sağlayıcılar yalnızca bizim adımıza işler (Play'de "paylaşım" sayılmaz) |

Hizmet sağlayıcılar (veri işleyenler): Barındırma (AB), Bunny.net (fotoğraf depolama, AB),
Anthropic (fotoğraf analizi: fotoğraf + öğün bilgisi), OpenAI (sohbet metni), Google Firebase
(giriş, push), RevenueCat (satın alma), Sentry (hata raporu, PII'siz).

## App Store — App Privacy ("Data Used to Track You": yok)

Hepsi **kullanıcıya bağlı (Linked to You)**; amaç aksi yazılmadıkça **App Functionality**.

| Kategori → Tür | Toplanıyor mu | Not |
|---|---|---|
| **Health & Fitness → Health** | Evet | Kilo, boy, oruç süreleri, açlık belirtileri, uyku |
| **Health & Fitness → Fitness** | Evet | Adım (Apple Health senkronu açıksa) |
| **Contact Info → Email Address** | Evet | Apple/Google girişinde sağlayıcıdan (Apple private relay olabilir) |
| **Contact Info → Name** | Evet | Apple/Google'dan ya da kullanıcı girerse |
| **User Content → Photos or Videos** | Evet | Öğün fotoğrafları, profil fotoğrafı |
| **User Content → Other User Content** | Evet | Koç sohbet mesajları, öğün/oruç notları |
| **Identifiers → User ID** | Evet | Hesap kimliği (UUID) |
| **Identifiers → Device ID** | Evet | Uygulama kurulum kimliği (rastgele UUID) + push token |
| **Purchases → Purchase History** | Evet | Abonelik durumu (RevenueCat) |
| **Usage Data → Product Interaction** | Evet | Son etkinlik günü — amaç: **Analytics** + App Functionality (DAU/MAU raporu) |
| **Diagnostics → Crash Data** | Evet (Sentry açıksa) | Amaç: App Functionality; PII'siz |
| Location, Financial Info, Contacts, Browsing/Search History, Sensitive Info, Other Data | Hayır | — |

Not: Sağlık verisi açık rıza ile işlenir; HealthKit verisi reklam/pazarlama için kullanılmaz
(App Store 5.1.3).

## Google Play — Data Safety

**Toplanan veriler** (hepsi: zorunlu değil — kullanıcı özelliği kullanırsa; işleme amacı: Uygulama
işlevselliği, Hesap yönetimi; aktarımda şifreli; silinebilir):

| Play kategorisi → Tür | Toplanıyor | İsteğe bağlı mı | Amaç |
|---|---|---|---|
| Kişisel bilgiler → Ad | Evet | Evet | Hesap yönetimi |
| Kişisel bilgiler → E-posta adresi | Evet | Evet (misafir kullanılabilir) | Hesap yönetimi |
| Kişisel bilgiler → Kullanıcı kimlikleri | Evet | Hayır | Uygulama işlevselliği, hesap yönetimi |
| Sağlık ve fitness → Sağlık bilgileri | Evet | Evet | Uygulama işlevselliği |
| Sağlık ve fitness → Fitness bilgileri | Evet | Evet | Uygulama işlevselliği |
| Fotoğraflar ve videolar → Fotoğraflar | Evet | Evet | Uygulama işlevselliği |
| Mesajlar → Diğer uygulama içi mesajlar | Evet (koç sohbeti) | Evet | Uygulama işlevselliği |
| Finansal bilgiler → Satın alma geçmişi | Evet | Evet | Uygulama işlevselliği |
| Uygulama etkinliği → Uygulama etkileşimleri | Evet (son etkinlik günü) | Hayır | Analiz |
| Uygulama bilgileri ve performans → Kilitlenme günlükleri | Evet (Sentry açıksa) | Hayır | Uygulama işlevselliği |
| Cihaz veya diğer kimlikler | Evet (kurulum kimliği, push token) | Hayır | Uygulama işlevselliği |
| Konum, Kişiler, Takvim, Dosyalar, Ses, Web tarama | Hayır | — | — |

**Paylaşılan veri:** Yok. **Hesap silme URL'si:** `https://mochifast-api.fly-work.com/account/delete`.
**Verilerin bir kısmını hesabı silmeden silme:** Evet (öğün, kilo, oruç, sohbet kayıtları tek tek silinebilir).

## Saklama (forma ve aydınlatma metnine)

Hesap silinince tüm veriler 7 gün sonra kalıcı silinir (bu sürede giriş yapılırsa geri alınır);
yedeklerde en fazla 30 gün kalır. Ayrıntı: [06 §8.4](06-guvenlik.md#84-saklama-süreleri-retention).
