"""MochiFast yasal metinleri (TR + EN). Kaynak: docs/backend/06-guvenlik.md §8 ve
docs/backend/15-magaza-gizlilik.md — sistemin gerçekte işlediği veriler."""

EMAIL = '<a href="mailto:info@fly-work.com">info@fly-work.com</a>'
DELETE_URL = (
    '<a href="https://mochifast-api.fly-work.com/account/delete">'
    "mochifast-api.fly-work.com/account/delete</a>"
)

# ───────────────────────────── GİZLİLİK ─────────────────────────────

PRIVACY_TR = f"""
<div class="note">MochiFast, aralıklı oruç ve sağlıklı alışkanlık takibi uygulamasıdır. Verilerini <strong>satmayız</strong>, reklam
amacıyla kullanmayız ve seni uygulamalar arasında <strong>takip etmeyiz</strong>. Bu politika, hangi verileri neden işlediğimizi
ve haklarını açıklar (6698 sayılı KVKK ve AB Genel Veri Koruma Tüzüğü – GDPR).</div>

<h2>1. Veri sorumlusu</h2>
<p>MochiFast uygulaması ("Uygulama") Fly Work tarafından geliştirilir ve işletilir. Kişisel verilerinle ilgili tüm talepler için:
{EMAIL}</p>

<h2>2. Topladığımız veriler</h2>
<h3>2.1 Hesap bilgileri</h3>
<ul>
<li><strong>Misafir kullanım:</strong> Hesap açmadan kullanabilirsin; bu durumda cihazına özgü rastgele bir kurulum kimliği oluşturulur.</li>
<li><strong>Apple veya Google ile giriş:</strong> Giriş sağlayıcısının ilettiği ad ve e-posta adresi (Apple'da gizli aktarma adresi olabilir).
Şifreni hiçbir zaman görmeyiz.</li>
<li>Profil adın ve isteğe bağlı profil fotoğrafın.</li>
</ul>
<h3>2.2 Profil ve hedef bilgileri</h3>
<p>Onboarding'de ve profilde verdiğin bilgiler: hedefin, cinsiyet, yaş, boy, mevcut ve hedef kilo, beslenme tercihi, sevdiğin ve
kaçındığın yiyecekler, önceki deneyimin, engellerin, oruç nedenin, seçtiğin oruç planı ve öğün pencerenin saatleri, birim tercihlerin
(kg/lb, ml/oz) ve dil.</p>
<h3>2.3 Sağlık ve aktivite verileri</h3>
<ul>
<li>Oruç kayıtları (başlangıç, bitiş, his ve notlar), kilo kayıtları, su tüketimi, uyku kayıtları, açlık kontrolü cevapların ve
öğün kayıtların (kalori, makro besinler, notlar).</li>
<li><strong>Apple Sağlık / Health Connect:</strong> Yalnızca senin açtığın senkron ile <strong>adım sayın okunur</strong>. Bu
uygulamalara hiçbir veri yazmayız.</li>
</ul>
<p>Bu veriler özel nitelikli (sağlık) veri sayılabilir; bu yüzden onboarding sırasında <strong>açık rızanı</strong> alırız.</p>
<h3>2.4 Fotoğraflar</h3>
<p>Kalori hesaplamak için çektiğin öğün fotoğrafları ve profil fotoğrafın. Analiz edilip öğün olarak <strong>kaydetmediğin</strong>
fotoğraflar 24 saat içinde silinir.</p>
<h3>2.5 Yapay zekâ koçu ile sohbetler</h3>
<p>Koç Mochi'ye yazdığın mesajlar ve aldığın yanıtlar, sohbet geçmişini gösterebilmek için saklanır.</p>
<h3>2.6 Satın alma bilgileri</h3>
<p>Abonelik durumun (ürün, başlangıç/bitiş, yenileme). Ödeme App Store veya Google Play tarafından alınır; kart bilgilerini
<strong>görmeyiz</strong>.</p>
<h3>2.7 Teknik veriler</h3>
<ul>
<li>Rastgele kurulum kimliği, bildirim (push) jetonu, platform, uygulama sürümü, saat dilimi ve dil.</li>
<li>Güvenlik ve kötüye kullanımı önleme amaçlı istek kayıtları (IP adresi dahil), son etkinlik günü.</li>
<li>Uygulama hata raporları (kişisel veri ayıklanmış şekilde).</li>
</ul>
<p>Konum, rehber, takvim, mikrofon kaydı veya tarama geçmişi <strong>toplamayız</strong>.</p>

<h2>3. Verileri neden ve hangi hukuki sebeple işliyoruz</h2>
<div class="table"><table>
<tr><th>Amaç</th><th>Hukuki sebep</th></tr>
<tr><td>Hesabını oluşturmak, oturumunu yönetmek, uygulamayı çalıştırmak</td><td>Sözleşmenin kurulması ve ifası</td></tr>
<tr><td>Oruç, kilo, su, adım, uyku, açlık ve öğün takibi; kişisel plan, hedef ve tahminler</td><td>Açık rıza (sağlık verisi)</td></tr>
<tr><td>Yapay zekâ ile fotoğraftan kalori tahmini ve koç sohbeti</td><td>Açık rıza (özellik ilk kullanıldığında ayrıca sorulur)</td></tr>
<tr><td>Bildirimler (oruç hatırlatmaları, su hatırlatıcısı vb.)</td><td>Sözleşmenin ifası; istediğin zaman kapatabilirsin</td></tr>
<tr><td>Abonelik doğrulama</td><td>Sözleşmenin ifası</td></tr>
<tr><td>Güvenlik, dolandırıcılık ve kötüye kullanımı önleme, hata giderme, kullanım istatistiği</td><td>Meşru menfaat</td></tr>
<tr><td>Yasal yükümlülükler</td><td>Kanuni yükümlülük</td></tr>
</table></div>
<p>Sağlık verilerini reklam, pazarlama veya veri madenciliği için <strong>kullanmayız</strong>. Bildirim metinlerine sağlık
ayrıntısı (ör. kilo değeri) yazmayız.</p>

<h2>4. Yapay zekâ özellikleri</h2>
<ul>
<li>Fotoğraftan kalori tahmini ve koç sohbeti için OpenAI hizmetini kullanırız. Bu özellikleri ilk kez kullandığında ayrıca onay
isteriz; onay vermezsen yapay zekâ özellikleri kapalı kalır, uygulamanın geri kalanı çalışır.</li>
<li>Modele adın, e-posta adresin veya cihaz bilgin <strong>gönderilmez</strong>; yalnızca isteğin ve gerekli bağlam (ör. hedefin,
planın) iletilir.</li>
<li>OpenAI'nin API koşullarına göre bu veriler varsayılan olarak modellerini eğitmek için kullanılmaz.</li>
<li>Yapay zekâ yanıtları bilgilendirme amaçlıdır; tıbbi tavsiye değildir.</li>
</ul>

<h2>5. Verilerin aktarıldığı taraflar</h2>
<p>Verilerini <strong>satmayız</strong> ve reklam ağlarıyla <strong>paylaşmayız</strong>. Yalnızca bizim adımıza ve
talimatlarımızla çalışan hizmet sağlayıcılarla, gereken en az veriyi paylaşırız:</p>
<div class="table"><table>
<tr><th>Hizmet sağlayıcı</th><th>Veri</th><th>Konum</th></tr>
<tr><td>Barındırma (sunucu ve veritabanı)</td><td>Uygulama verilerinin tümü</td><td>Avrupa Birliği</td></tr>
<tr><td>Bunny.net</td><td>Fotoğraflar (öğün, profil)</td><td>Avrupa Birliği</td></tr>
<tr><td>OpenAI</td><td>Analiz edilen öğün fotoğrafı ve bilgisi, sohbet mesajları</td><td>ABD</td></tr>
<tr><td>Google Firebase</td><td>Giriş (Apple/Google) ve bildirim jetonu</td><td>ABD / global</td></tr>
<tr><td>RevenueCat</td><td>Anonim kullanıcı kimliği ve satın alma durumu (ad veya e-posta gönderilmez)</td><td>ABD</td></tr>
<tr><td>Sentry</td><td>Hata raporları (kişisel veri ayıklanmış)</td><td>ABD / AB</td></tr>
<tr><td>Apple / Google</td><td>Uygulama mağazası satın alma işlemleri</td><td>Global</td></tr>
</table></div>
<p>Ayrıca yasal bir zorunluluk veya yetkili makam talebi olduğunda veri paylaşabiliriz.</p>
<p>Meydan okumalarda "Listede adımla görün" ayarını açarsan, adın (soyadının baş harfiyle) ve profil fotoğrafın aynı meydan okumaya
katılan diğer kullanıcılara gösterilir. Ayar varsayılan olarak kapalıdır; kapalıyken diğer katılımcılar seni yalnızca anonim olarak
ve ilerlemenle görür.</p>

<h2>6. Yurt dışına aktarım</h2>
<p>Bazı hizmet sağlayıcılarımız Türkiye ve Avrupa Ekonomik Alanı dışında (özellikle ABD) bulunur. Bu aktarımları KVKK ve GDPR'ın
öngördüğü güvencelerle (standart sözleşme hükümleri ve ilgili bildirimler) ve açık rızana dayanarak yaparız.</p>

<h2>7. Saklama süreleri</h2>
<div class="table"><table>
<tr><th>Veri</th><th>Süre</th></tr>
<tr><td>Hesap ve takip verileri</td><td>Hesabın açık olduğu sürece</td></tr>
<tr><td>Silme talebinden sonra</td><td>7 gün içinde geri alınabilir; ardından kalıcı olarak silinir</td></tr>
<tr><td>Uygulamada sildiğin tekil kayıtlar (öğün, kilo, oruç vb.)</td><td>30 gün içinde kalıcı silinir</td></tr>
<tr><td>Kaydedilmeyen analiz fotoğrafları</td><td>24 saat</td></tr>
<tr><td>Okunmuş bildirimler</td><td>90 gün</td></tr>
<tr><td>Kapanmış oturum kayıtları</td><td>30 gün</td></tr>
<tr><td>Güvenlik denetim kayıtları</td><td>13 ay (hesap silinince anonimleştirilir)</td></tr>
<tr><td>Uygulama günlükleri</td><td>30 gün</td></tr>
<tr><td>Şifreli yedekler</td><td>En fazla 30 gün</td></tr>
</table></div>

<h2>8. Hakların</h2>
<p>KVKK m.11 ve GDPR kapsamında; verilerinin işlenip işlenmediğini öğrenme, bilgi ve kopya talep etme, düzeltme, silme,
işlemeyi kısıtlama ve itiraz etme, verilerin taşınması ve <strong>rızanı istediğin zaman geri çekme</strong> hakların vardır.</p>
<ul>
<li><strong>Hesabını silme:</strong> Uygulamada <em>Profil → Profili Düzenle → Hesabı Sil</em>. Uygulamaya erişemiyorsan: {DELETE_URL}
veya {EMAIL}. Aboneliğini ayrıca App Store / Google Play ayarlarından iptal etmen gerekir.</li>
<li><strong>Düzeltme ve tekil silme:</strong> Profil bilgilerini ve kayıtlarını (öğün, kilo, oruç, uyku, sohbet) uygulamada düzenleyip
silebilirsin.</li>
<li><strong>Diğer talepler</strong> (bilgi, kopya, itiraz): {EMAIL}. Talebini en geç 30 gün içinde yanıtlarız.</li>
<li>Kişisel Verileri Koruma Kurulu'na veya bulunduğun ülkedeki veri koruma otoritesine şikâyette bulunma hakkın saklıdır.</li>
</ul>

<h2>9. Çocuklar</h2>
<p>MochiFast 13 yaşından küçükler için tasarlanmamıştır ve bu yaştaki çocuklardan bilerek veri toplamayız. 13–17 yaş arası
kullanıcılara yalnızca daha hafif planlar sunulur ve ebeveyn/vasi gözetimi önerilir. 13 yaşından küçük bir çocuğa ait veri
işlediğimizi fark edersek siliriz; bize {EMAIL} adresinden bildirebilirsin.</p>

<h2>10. Güvenlik</h2>
<p>Veriler aktarım sırasında TLS ile şifrelenir; hassas alanlar ve yedekler şifreli saklanır; erişim yetkiyle sınırlıdır ve
kayıt altındadır. Hiçbir sistem yüzde yüz güvenli olmasa da verilerini korumak için makul teknik ve idari önlemleri alırız.</p>

<h2>11. Bildirimler ve izinler</h2>
<p>Bildirim, kamera, fotoğraf arşivi ve Apple Sağlık / Health Connect izinleri isteğe bağlıdır; cihaz ayarlarından ve uygulamadaki
<em>Profil → Bildirim ayarları</em> ekranından istediğin zaman değiştirebilirsin.</p>

<h2>12. Değişiklikler</h2>
<p>Bu politikayı güncelleyebiliriz. Önemli değişikliklerde uygulama içinde seni bilgilendirir ve gerekiyorsa yeniden onayını isteriz.
Güncel sürüm her zaman bu sayfadadır.</p>

<h2>13. İletişim</h2>
<p>Sorular ve talepler için: {EMAIL}</p>
"""

PRIVACY_EN = f"""
<div class="note">MochiFast is an intermittent fasting and healthy-habit tracking app. We <strong>do not sell</strong> your data, we do
not use it for advertising and we <strong>do not track</strong> you across apps. This policy explains what we process, why, and your
rights (EU General Data Protection Regulation – GDPR, and Turkish Law No. 6698 – KVKK).</div>

<h2>1. Data controller</h2>
<p>The MochiFast app (the "App") is developed and operated by Fly Work. For any request about your personal data: {EMAIL}</p>

<h2>2. Data we collect</h2>
<h3>2.1 Account information</h3>
<ul>
<li><strong>Guest use:</strong> You can use the App without an account; a random install ID unique to your device is created.</li>
<li><strong>Sign in with Apple or Google:</strong> the name and email address shared by the provider (Apple may share a private relay
address). We never see your password.</li>
<li>Your profile name and optional profile photo.</li>
</ul>
<h3>2.2 Profile and goal information</h3>
<p>Information you give during onboarding and in your profile: your goal, gender, age, height, current and goal weight, diet, foods you
love and avoid, previous experience, obstacles, reason for fasting, chosen fasting plan and meal window, unit preferences (kg/lb,
ml/oz) and language.</p>
<h3>2.3 Health and activity data</h3>
<ul>
<li>Fasting sessions (start, end, feeling, notes), weight entries, water intake, sleep entries, hunger check-in answers and meal logs
(calories, macronutrients, notes).</li>
<li><strong>Apple Health / Health Connect:</strong> only if you turn on sync, we <strong>read your step count</strong>. We never write
any data to these apps.</li>
</ul>
<p>This data may be considered special-category (health) data, so we ask for your <strong>explicit consent</strong> during onboarding.</p>
<h3>2.4 Photos</h3>
<p>Meal photos you take to estimate calories, and your profile photo. Analysed photos that you <strong>do not save</strong> as a meal are
deleted within 24 hours.</p>
<h3>2.5 Conversations with the AI coach</h3>
<p>Messages you send to Coach Mochi and its replies are stored so we can show your chat history.</p>
<h3>2.6 Purchase information</h3>
<p>Your subscription status (product, start/end, renewal). Payments are handled by the App Store or Google Play; we <strong>never
see</strong> your card details.</p>
<h3>2.7 Technical data</h3>
<ul>
<li>Random install ID, push notification token, platform, app version, time zone and language.</li>
<li>Request logs for security and abuse prevention (including IP address), and the date you were last active.</li>
<li>Crash reports (with personal data removed).</li>
</ul>
<p>We do <strong>not</strong> collect location, contacts, calendar, audio recordings or browsing history.</p>

<h2>3. Why we process data and on what legal basis</h2>
<div class="table"><table>
<tr><th>Purpose</th><th>Legal basis</th></tr>
<tr><td>Creating your account, managing your session, running the App</td><td>Performance of a contract</td></tr>
<tr><td>Fasting, weight, water, steps, sleep, hunger and meal tracking; personal plan, goals and projections</td><td>Explicit consent (health data)</td></tr>
<tr><td>AI calorie estimation from photos and coach chat</td><td>Explicit consent (asked separately on first use)</td></tr>
<tr><td>Notifications (fasting reminders, water reminders, etc.)</td><td>Performance of a contract; you can turn them off anytime</td></tr>
<tr><td>Verifying subscriptions</td><td>Performance of a contract</td></tr>
<tr><td>Security, fraud and abuse prevention, debugging, usage statistics</td><td>Legitimate interests</td></tr>
<tr><td>Legal obligations</td><td>Legal obligation</td></tr>
</table></div>
<p>We <strong>never</strong> use health data for advertising, marketing or data mining, and we do not put health details (such as your
weight) in notification texts.</p>

<h2>4. AI features</h2>
<ul>
<li>We use OpenAI to estimate calories from photos and to power the coach chat. We ask for your consent the first time you use these
features; if you decline, AI features stay off and the rest of the App keeps working.</li>
<li>Your name, email address or device information is <strong>not sent</strong> to the model; only your request and the necessary
context (e.g. your goal and plan).</li>
<li>Under OpenAI's API terms, this data is not used to train their models by default.</li>
<li>AI responses are for information only and are not medical advice.</li>
</ul>

<h2>5. Who we share data with</h2>
<p>We <strong>do not sell</strong> your data and we <strong>do not share</strong> it with advertising networks. We only share the
minimum necessary data with service providers that act on our behalf and under our instructions:</p>
<div class="table"><table>
<tr><th>Service provider</th><th>Data</th><th>Location</th></tr>
<tr><td>Hosting (servers and database)</td><td>All App data</td><td>European Union</td></tr>
<tr><td>Bunny.net</td><td>Photos (meals, profile)</td><td>European Union</td></tr>
<tr><td>OpenAI</td><td>Analysed meal photo and details, chat messages</td><td>USA</td></tr>
<tr><td>Google Firebase</td><td>Sign-in (Apple/Google) and push token</td><td>USA / global</td></tr>
<tr><td>RevenueCat</td><td>Anonymous user ID and purchase status (no name or email)</td><td>USA</td></tr>
<tr><td>Sentry</td><td>Crash reports (personal data removed)</td><td>USA / EU</td></tr>
<tr><td>Apple / Google</td><td>App store purchases</td><td>Global</td></tr>
</table></div>
<p>We may also disclose data where required by law or by a competent authority.</p>
<p>If you turn on "Show my name in the list" in a challenge, your name (with your last initial) and profile photo are shown to other
users taking part in the same challenge. The setting is off by default; while it is off, other participants only see you anonymously
together with your progress.</p>

<h2>6. International transfers</h2>
<p>Some providers are located outside Türkiye and the European Economic Area (mainly the USA). We make these transfers with the
safeguards required by GDPR and KVKK (such as Standard Contractual Clauses and the related notifications) and based on your explicit
consent.</p>

<h2>7. Retention</h2>
<div class="table"><table>
<tr><th>Data</th><th>Period</th></tr>
<tr><td>Account and tracking data</td><td>As long as your account is active</td></tr>
<tr><td>After an account deletion request</td><td>Can be undone within 7 days, then permanently deleted</td></tr>
<tr><td>Individual entries you delete in the App (meals, weight, fasts, etc.)</td><td>Permanently deleted within 30 days</td></tr>
<tr><td>Analysed photos that were not saved</td><td>24 hours</td></tr>
<tr><td>Read notifications</td><td>90 days</td></tr>
<tr><td>Closed session records</td><td>30 days</td></tr>
<tr><td>Security audit records</td><td>13 months (anonymised when the account is deleted)</td></tr>
<tr><td>Application logs</td><td>30 days</td></tr>
<tr><td>Encrypted backups</td><td>Up to 30 days</td></tr>
</table></div>

<h2>8. Your rights</h2>
<p>You have the right to access your data, receive a copy, rectify it, erase it, restrict or object to processing, data portability, and
to <strong>withdraw your consent at any time</strong>.</p>
<ul>
<li><strong>Delete your account:</strong> in the App go to <em>Profile → Edit Profile → Delete Account</em>. If you can't access the
App: {DELETE_URL} or {EMAIL}. Please also cancel your subscription in your App Store / Google Play settings.</li>
<li><strong>Correct or delete single entries:</strong> you can edit and delete your profile details and entries (meals, weight,
fasts, sleep, chats) in the App.</li>
<li><strong>Other requests</strong> (information, copy, objection): {EMAIL}. We respond within 30 days at the latest.</li>
<li>You may lodge a complaint with the Turkish Personal Data Protection Authority or the data protection authority in your country.</li>
</ul>

<h2>9. Children</h2>
<p>MochiFast is not intended for children under 13, and we do not knowingly collect data from them. Users aged 13–17 are only offered
gentler plans, and parental or guardian supervision is recommended. If we learn that we have processed data of a child under 13, we will
delete it; you can let us know at {EMAIL}.</p>

<h2>10. Security</h2>
<p>Data is encrypted in transit with TLS; sensitive fields and backups are stored encrypted; access is restricted and logged. No system
is 100% secure, but we take reasonable technical and organisational measures to protect your data.</p>

<h2>11. Notifications and permissions</h2>
<p>Notification, camera, photo library and Apple Health / Health Connect permissions are optional. You can change them anytime in your
device settings and in <em>Profile → Notification settings</em> in the App.</p>

<h2>12. Changes</h2>
<p>We may update this policy. For significant changes we will notify you in the App and, where required, ask for your consent again. The
current version is always available on this page.</p>

<h2>13. Contact</h2>
<p>For questions and requests: {EMAIL}</p>
"""

# ───────────────────────────── KOŞULLAR ─────────────────────────────

TERMS_TR = f"""
<div class="warn"><strong>Önemli sağlık uyarısı:</strong> MochiFast tıbbi bir cihaz değildir ve tıbbi tavsiye, teşhis veya tedavi
sunmaz. Oruca başlamadan önce, özellikle hamileysen, emziriyorsan, yeme bozukluğu geçmişin, diyabetin, kalp rahatsızlığın varsa,
düzenli ilaç kullanıyorsan veya 18 yaşından küçüksen bir sağlık profesyoneline danış. Kendini iyi hissetmezsen orucunu bitir.</div>

<h2>1. Kabul</h2>
<p>MochiFast uygulamasını ("Uygulama") indirerek veya kullanarak bu Kullanım Koşulları'nı ve
<a href="../privacy-policy/">Gizlilik Politikası</a>'nı kabul etmiş olursun. Kabul etmiyorsan Uygulamayı kullanma. Uygulama
Fly Work ("biz") tarafından sunulur.</p>

<h2>2. Hizmet</h2>
<p>MochiFast; aralıklı oruç planları ve zamanlayıcısı, oruç aşamaları, su, adım, kilo, uyku, açlık ve öğün takibi, yapay zekâ ile
fotoğraftan kalori tahmini, yapay zekâ koçu, meydan okumalar ve oyunlaştırma (Mochi Dünyası, seriler) sunar. Özellikleri zaman içinde
değiştirebilir, ekleyebilir veya kaldırabiliriz.</p>

<h2>3. Uygunluk</h2>
<p>Uygulamayı kullanmak için en az 13 yaşında olmalısın. 18 yaşından küçüksen ebeveyninin veya vasinin izniyle ve gözetiminde
kullanmalısın; bu yaş grubuna yalnızca daha hafif planlar sunulur.</p>

<h2>4. Hesap</h2>
<ul>
<li>Uygulamayı misafir olarak veya Apple / Google ile giriş yaparak kullanabilirsin. Misafir verileri cihazına bağlıdır; uygulamayı
silersen veya cihaz değiştirirsen erişimini kaybedebilirsin.</li>
<li>Hesabının güvenliğinden ve hesabınla yapılan işlemlerden sen sorumlusun.</li>
<li>Hesabını istediğin zaman <em>Profil → Profili Düzenle → Hesabı Sil</em> yoluyla silebilirsin. Silme talebi 7 gün içinde geri
alınabilir, sonra tüm verilerin kalıcı olarak silinir.</li>
</ul>

<h2>5. Abonelikler ve ödemeler</h2>
<ul>
<li>Bazı özellikler (ör. ileri ve haftalık planlar, daha yüksek yapay zekâ kotası) ücretli abonelik (MochiFast Premium) gerektirir.
Fiyatlar ve süreler satın alma ekranında gösterilir.</li>
<li>Ödeme, satın alımın onaylanmasıyla App Store veya Google Play hesabından alınır. Abonelik, dönem bitmeden en az 24 saat önce iptal
edilmedikçe <strong>otomatik olarak yenilenir</strong>.</li>
<li>Aboneliğini cihazındaki App Store veya Google Play abonelik ayarlarından yönetebilir ve iptal edebilirsin. Uygulamayı ya da
hesabını silmek aboneliği iptal etmez.</li>
<li>Ücretsiz deneme sunulursa, deneme bitmeden iptal edilmezse ücretli aboneliğe dönüşür.</li>
<li>İadeler ilgili mağazanın politikalarına tabidir; talepler Apple veya Google'a iletilir. Yürürlükteki tüketici mevzuatından doğan
hakların saklıdır.</li>
</ul>

<h2>6. Yapay zekâ özellikleri</h2>
<ul>
<li>Kalori tahminleri ve koç yanıtları otomatik üretilir; hatalı veya eksik olabilir. Önemli kararlar için tek kaynak olarak kullanma.</li>
<li>Yapay zekâ özellikleri günlük kullanım kotalarına tabidir.</li>
<li>Bu özellikleri kullanmak için ayrıca onay vermen gerekir; onayını istediğin zaman geri çekebilirsin.</li>
</ul>

<h2>7. Kabul edilebilir kullanım</h2>
<p>Uygulamayı kullanırken şunları yapmamayı kabul edersin: yasa dışı, zararlı, taciz edici, nefret içeren veya müstehcen içerik
yüklemek ya da göndermek; çocukların cinsel istismarına ilişkin her türlü içerik (bkz. <a href="../csae/">Çocuk Güvenliği
Standartları</a>); başkasının kimliğine bürünmek; Uygulamayı tersine mühendislik, kazıma veya otomatik araçlarla kötüye kullanmak;
güvenlik önlemlerini aşmaya çalışmak; kotaları veya ödeme sistemini atlatmak.</p>

<h2>8. Kullanıcı içeriği</h2>
<p>Yüklediğin fotoğraflar, notlar ve mesajlar sana aittir. Bunları yalnızca Uygulamayı sana sunmak (saklamak, işlemek, göstermek, analiz
etmek) için kullanmamıza izin verirsin. Meydan okuma sayfasında "Listede adımla görün" ayarını açarsan, adın (soyadının yalnızca
baş harfiyle) ve profil fotoğrafın katıldığın meydan okumalarda diğer katılımcılara görünür. Bu ayar varsayılan olarak kapalıdır ve
istediğin zaman kapatabilirsin; kapalıyken listede anonim görünürsün.</p>

<h2>9. Fikri mülkiyet</h2>
<p>Uygulama, Mochi karakteri, tasarımlar, metinler ve yazılım bize veya lisans verenlerimize aittir. Sana Uygulamayı kişisel ve ticari
olmayan amaçla kullanman için sınırlı, devredilemez bir kullanım hakkı veriyoruz.</p>

<h2>10. Üçüncü taraf hizmetleri</h2>
<p>Apple, Google, Apple Sağlık, Health Connect, RevenueCat ve OpenAI gibi hizmetlerin kullanımı, o hizmetlerin kendi koşullarına
tabidir.</p>

<h2>11. Sorumluluğun sınırlandırılması</h2>
<p>Uygulama "olduğu gibi" sunulur. Kesintisiz veya hatasız çalışacağını garanti etmeyiz. Yürürlükteki hukukun izin verdiği ölçüde;
Uygulamanın kullanımından doğan dolaylı zararlardan ve Uygulamadaki bilgilere dayanarak alınan sağlık kararlarından sorumlu değiliz.
Kast veya ağır ihmalden doğan sorumluluk ile tüketici olarak sahip olduğun yasal haklar saklıdır.</p>

<h2>12. Fesih</h2>
<p>Uygulamayı istediğin zaman kullanmayı bırakabilir ve hesabını silebilirsin. Bu koşulları ihlal edersen hesabını askıya alabilir veya
kapatabiliriz.</p>

<h2>13. Uygulanacak hukuk</h2>
<p>Bu koşullar Türkiye Cumhuriyeti hukukuna tabidir. Tüketici olarak ikamet ettiğin ülkenin emredici hükümlerinden doğan hakların
saklıdır.</p>

<h2>14. Değişiklikler</h2>
<p>Bu koşulları güncelleyebiliriz. Önemli değişikliklerde Uygulama içinde bilgilendirir ve gerekiyorsa yeniden onayını isteriz.</p>

<h2>15. İletişim</h2>
<p>{EMAIL}</p>
"""

TERMS_EN = f"""
<div class="warn"><strong>Important health notice:</strong> MochiFast is not a medical device and does not provide medical advice,
diagnosis or treatment. Talk to a healthcare professional before fasting, especially if you are pregnant or breastfeeding, have a history
of eating disorders, diabetes or a heart condition, take regular medication, or are under 18. Stop your fast if you feel unwell.</div>

<h2>1. Acceptance</h2>
<p>By downloading or using the MochiFast app (the "App") you agree to these Terms of Use and our
<a href="../privacy-policy/">Privacy Policy</a>. If you do not agree, do not use the App. The App is provided by Fly Work
("we", "us").</p>

<h2>2. The service</h2>
<p>MochiFast offers intermittent fasting plans and a timer, fasting stages, water, step, weight, sleep, hunger and meal tracking, AI
calorie estimation from photos, an AI coach, challenges and gamification (Mochi World, streaks). We may change, add or remove features
over time.</p>

<h2>3. Eligibility</h2>
<p>You must be at least 13 years old to use the App. If you are under 18, you must use it with the permission and supervision of a parent
or guardian; this age group is only offered gentler plans.</p>

<h2>4. Your account</h2>
<ul>
<li>You can use the App as a guest or sign in with Apple / Google. Guest data is tied to your device; you may lose access if you delete
the App or change devices.</li>
<li>You are responsible for keeping your account secure and for activity under your account.</li>
<li>You can delete your account anytime via <em>Profile → Edit Profile → Delete Account</em>. A deletion request can be undone within 7
days; after that all your data is permanently deleted.</li>
</ul>

<h2>5. Subscriptions and payments</h2>
<ul>
<li>Some features (e.g. advanced and weekly plans, a higher AI quota) require a paid subscription (MochiFast Premium). Prices and
periods are shown on the purchase screen.</li>
<li>Payment is charged to your App Store or Google Play account at confirmation of purchase. Subscriptions <strong>renew
automatically</strong> unless cancelled at least 24 hours before the end of the current period.</li>
<li>You can manage and cancel your subscription in your App Store or Google Play subscription settings. Deleting the App or your account
does not cancel your subscription.</li>
<li>If a free trial is offered, it converts to a paid subscription unless cancelled before the trial ends.</li>
<li>Refunds are subject to the policies of the respective store; requests are handled by Apple or Google. Your statutory consumer rights
are not affected.</li>
</ul>

<h2>6. AI features</h2>
<ul>
<li>Calorie estimates and coach replies are generated automatically and may be inaccurate or incomplete. Do not rely on them as your
only source for important decisions.</li>
<li>AI features are subject to daily usage quotas.</li>
<li>Using these features requires your separate consent, which you can withdraw at any time.</li>
</ul>

<h2>7. Acceptable use</h2>
<p>You agree not to: upload or send unlawful, harmful, harassing, hateful or obscene content; any content related to child sexual abuse
or exploitation (see our <a href="../csae/">Child Safety Standards</a>); impersonate others; reverse engineer, scrape or abuse the App with
automated tools; attempt to bypass security measures; or circumvent quotas or the payment system.</p>

<h2>8. Your content</h2>
<p>Photos, notes and messages you upload remain yours. You allow us to use them only to provide the App to you (store, process, display
and analyse them). If you turn on "Show my name in the list" on a challenge page, your name (with only your last initial) and profile
photo become visible to other participants in challenges you join. This setting is off by default and you can turn it off at any time;
while it is off, you appear anonymously.</p>

<h2>9. Intellectual property</h2>
<p>The App, the Mochi character, designs, texts and software belong to us or our licensors. We grant you a limited, non-transferable
licence to use the App for personal, non-commercial purposes.</p>

<h2>10. Third-party services</h2>
<p>Your use of services such as Apple, Google, Apple Health, Health Connect, RevenueCat and OpenAI is subject to their own terms.</p>

<h2>11. Limitation of liability</h2>
<p>The App is provided "as is". We do not guarantee that it will be uninterrupted or error-free. To the extent permitted by applicable
law, we are not liable for indirect damages arising from the use of the App or for health decisions made based on information in the App.
Liability for intent or gross negligence and your statutory rights as a consumer remain unaffected.</p>

<h2>12. Termination</h2>
<p>You may stop using the App and delete your account at any time. We may suspend or close your account if you breach these Terms.</p>

<h2>13. Governing law</h2>
<p>These Terms are governed by the laws of the Republic of Türkiye. Mandatory consumer protection rules of your country of residence
remain unaffected.</p>

<h2>14. Changes</h2>
<p>We may update these Terms. For significant changes we will notify you in the App and, where required, ask for your consent again.</p>

<h2>15. Contact</h2>
<p>{EMAIL}</p>
"""

# ───────────────────────────── ÇEREZLER ─────────────────────────────

COOKIES_TR = f"""
<div class="note">Kısaca: MochiFast <strong>reklam veya takip çerezi kullanmaz</strong>. Uygulama, yalnızca çalışması için gereken
bilgileri cihazında saklar. Bu sayfalar da çerez veya yerel depolama kullanmaz.</div>

<h2>1. Çerez nedir?</h2>
<p>Çerezler, web sitelerinin tarayıcına kaydettiği küçük dosyalardır. Mobil uygulamalar tarayıcı çerezi yerine cihazdaki
benzer depolama alanlarını (ör. güvenli anahtar deposu, uygulama tercihleri) kullanır. Bu politika her ikisini de kapsar.</p>

<h2>2. Uygulamanın cihazında sakladığı bilgiler</h2>
<p>Bunların tamamı <strong>zorunlu</strong> niteliktedir; Uygulamanın çalışması için gerekir ve reklam ya da takip amacıyla kullanılmaz:</p>
<div class="table"><table>
<tr><th>Bilgi</th><th>Amaç</th><th>Nerede</th></tr>
<tr><td>Oturum anahtarları (erişim / yenileme)</td><td>Girişli kalmanı sağlamak</td><td>Cihazın güvenli deposu (Keychain / Keystore)</td></tr>
<tr><td>Rastgele kurulum kimliği ve misafir anahtarı</td><td>Misafir hesabını cihazına bağlamak</td><td>Cihazın güvenli deposu</td></tr>
<tr><td>Dil, birim ve ekran tercihleri</td><td>Ayarlarını hatırlamak</td><td>Uygulama tercihleri</td></tr>
<tr><td>Son ana sayfa özeti ve kısa süreli önbellek</td><td>Uygulamanın hızlı açılması, internet yokken son verileri göstermek</td><td>Uygulama tercihleri / bellek</td></tr>
<tr><td>Ana ekran widget verileri</td><td>Oruç ve su widget'larını göstermek</td><td>Uygulamanın paylaşılan alanı</td></tr>
</table></div>
<p>Çıkış yaptığında oturum ve kişisel önbellek bilgileri silinir; uygulamayı kaldırdığında tümü cihazından kaldırılır.</p>

<h2>3. Üçüncü taraf bileşenler</h2>
<ul>
<li><strong>Google Firebase:</strong> Giriş ve bildirim (push) iletimi için bir cihaz/kurulum tanımlayıcısı kullanır.</li>
<li><strong>RevenueCat:</strong> Abonelik durumunu doğrulamak için anonim bir kullanıcı kimliği kullanır.</li>
<li><strong>Sentry:</strong> Uygulama çökerse kişisel veri ayıklanmış bir hata raporu gönderebilir.</li>
</ul>
<p>Bu bileşenler bizim adımıza çalışır; seni başka uygulama veya sitelerde takip etmek için kullanılmaz. Uygulamada reklam,
reklam kimliği (IDFA / Reklam Kimliği) veya uygulamalar arası takip <strong>yoktur</strong>.</p>

<h2>4. Bu web sayfaları</h2>
<p>MochiFast yasal sayfaları (gizlilik, koşullar, çerezler, çocuk güvenliği) çerez, yerel depolama veya analitik araç
kullanmaz. Dil seçimi yalnızca sayfa adresi üzerinden yapılır.</p>

<h2>5. Tercihlerini yönetme</h2>
<ul>
<li>Bildirimleri <em>Profil → Bildirim ayarları</em> ekranından veya cihaz ayarlarından kapatabilirsin.</li>
<li>Uygulamada sakladığın bilgileri çıkış yaparak veya uygulamayı kaldırarak silebilirsin.</li>
<li>Kişisel verilerin hakkında ayrıntılar için <a href="../privacy-policy/">Gizlilik Politikası</a>'na bak.</li>
</ul>

<h2>6. İletişim</h2>
<p>{EMAIL}</p>
"""

COOKIES_EN = f"""
<div class="note">In short: MochiFast <strong>does not use advertising or tracking cookies</strong>. The App only stores what it needs
to work on your device. These pages do not use cookies or local storage either.</div>

<h2>1. What are cookies?</h2>
<p>Cookies are small files that websites save in your browser. Mobile apps use similar storage on your device instead (such as a secure
key store or app preferences). This policy covers both.</p>

<h2>2. What the App stores on your device</h2>
<p>All of these are <strong>strictly necessary</strong> for the App to work and are never used for advertising or tracking:</p>
<div class="table"><table>
<tr><th>Information</th><th>Purpose</th><th>Where</th></tr>
<tr><td>Session tokens (access / refresh)</td><td>Keep you signed in</td><td>Device secure storage (Keychain / Keystore)</td></tr>
<tr><td>Random install ID and guest key</td><td>Link your guest account to your device</td><td>Device secure storage</td></tr>
<tr><td>Language, unit and display preferences</td><td>Remember your settings</td><td>App preferences</td></tr>
<tr><td>Last home summary and short-lived cache</td><td>Open quickly and show your latest data when offline</td><td>App preferences / memory</td></tr>
<tr><td>Home screen widget data</td><td>Show the fasting and water widgets</td><td>The App's shared container</td></tr>
</table></div>
<p>Session and personal cache data are removed when you sign out; everything is removed when you uninstall the App.</p>

<h2>3. Third-party components</h2>
<ul>
<li><strong>Google Firebase:</strong> uses a device/installation identifier for sign-in and push notification delivery.</li>
<li><strong>RevenueCat:</strong> uses an anonymous user ID to verify your subscription.</li>
<li><strong>Sentry:</strong> may send a crash report with personal data removed if the App crashes.</li>
</ul>
<p>These components act on our behalf and are not used to track you across other apps or websites. The App has <strong>no</strong>
advertising, advertising identifiers (IDFA / Advertising ID) or cross-app tracking.</p>

<h2>4. These web pages</h2>
<p>The MochiFast legal pages (privacy, terms, cookies, child safety) do not use cookies, local storage or analytics tools. The language
choice is handled only through the page address.</p>

<h2>5. Managing your preferences</h2>
<ul>
<li>Turn notifications off in <em>Profile → Notification settings</em> or in your device settings.</li>
<li>Remove data stored by the App by signing out or uninstalling it.</li>
<li>See our <a href="../privacy-policy/">Privacy Policy</a> for details about your personal data.</li>
</ul>

<h2>6. Contact</h2>
<p>{EMAIL}</p>
"""

# ───────────────────────────── ÇOCUK GÜVENLİĞİ (CSAE) ─────────────────────────────

CSAE_TR = f"""
<div class="note">MochiFast, <strong>çocukların cinsel istismarı ve sömürüsüne (CSAE)</strong> ve çocuk cinsel istismarı materyaline
(CSAM) karşı <strong>sıfır tolerans</strong> politikası uygular.</div>

<h2>1. Kapsam</h2>
<p>Bu standartlar MochiFast uygulaması ve ilgili tüm hizmetler için geçerlidir. MochiFast bir sağlık ve alışkanlık takibi
uygulamasıdır; herkese açık bir akış veya kullanıcılar arası mesajlaşma sunmaz. Kullanıcıların başkalarına görünebilen tek içeriği,
kullanıcının açıkça izin vermesi hâlinde meydan okumalarda görünen kısaltılmış adı ve profil fotoğrafıdır. Yapay zekâ koçu ile yapılan sohbetler yalnızca kullanıcının kendisine
görünür.</p>

<h2>2. Yasaklanan içerik ve davranışlar</h2>
<ul>
<li>Çocukların cinsel istismarını gösteren, teşvik eden veya cinselleştiren her türlü görsel, metin veya diğer içerik (CSAM).</li>
<li>Çocuklarla cinsel amaçlı iletişim kurmaya, onları kandırmaya veya istismara yönelik her türlü girişim (grooming).</li>
<li>Çocukların cinsel sömürüsünü, insan ticaretini veya bunlara aracılığı içeren her türlü faaliyet.</li>
<li>Bu tür içerikleri yapay zekâ özellikleri aracılığıyla üretmeye veya elde etmeye çalışmak.</li>
</ul>

<h2>3. Önleme</h2>
<ul>
<li>Uygulamayı kullanmak için en az 13 yaşında olmak gerekir; 18 yaşından küçükler için ebeveyn/vasi gözetimi istenir.</li>
<li>Kullanıcılar arasında doğrudan mesajlaşma yoktur; diğer kullanıcılara görünen içerik profil adı ve fotoğrafıyla sınırlıdır.</li>
<li>Yapay zekâ özellikleri, cinsel içerik ve reşit olmayanlarla ilgili zararlı talepleri reddedecek güvenlik kurallarıyla çalışır.</li>
</ul>

<h2>4. Bildirim</h2>
<p>Uygulamada veya hizmetlerimizde çocuk güvenliğini tehdit eden bir içerik ya da davranış görürsen hemen bize bildir:</p>
<ul>
<li><strong>Uygulama içinden:</strong> <em>Profil → Yasal ve destek → Destek ile iletişim</em></li>
<li><strong>E-posta:</strong> {EMAIL} (konu: "Çocuk güvenliği")</li>
</ul>
<p>Mümkünse ilgili kullanıcının adını, ekran görüntüsünü ve tarihini ekle. Çocuk istismarı materyalini kendin kopyalama, saklama veya
paylaşma; yalnızca bize ve yetkililere bildir. Bir çocuk acil tehlikedeyse önce <strong>112</strong>'yi (veya bulunduğun ülkedeki acil
durum hattını) ara.</p>

<h2>5. Müdahale</h2>
<ul>
<li>Bildirimler öncelikli olarak incelenir.</li>
<li>İhlal eden içerik derhal kaldırılır ve ilgili hesap kalıcı olarak kapatılır.</li>
<li>Çocuk cinsel istismarı materyali tespit edildiğinde yürürlükteki yasalar uyarınca yetkili makamlara (Türkiye'de kolluk kuvvetleri ve
ilgili kurumlar; gerektiğinde ABD'deki NCMEC dahil uluslararası kuruluşlar) bildirilir.</li>
<li>Soruşturmalarda yetkili makamlarla iş birliği yapılır ve kanunen gereken kayıtlar korunur.</li>
</ul>

<h2>6. Yasalara uyum</h2>
<p>MochiFast, çocuk güvenliğine ilişkin yürürlükteki yasalara ve Google Play ile App Store politikalarına uyar.</p>

<h2>7. Çocuk güvenliği irtibat kişisi</h2>
<p>Çocuk güvenliği uygulamalarımız ve bu standartlar hakkında soruların için irtibat: {EMAIL}</p>
"""

CSAE_EN = f"""
<div class="note">MochiFast has a <strong>zero-tolerance</strong> policy towards <strong>child sexual abuse and exploitation
(CSAE)</strong> and child sexual abuse material (CSAM).</div>

<h2>1. Scope</h2>
<p>These standards apply to the MochiFast app and all related services. MochiFast is a health and habit tracking app; it has no public
feed and no user-to-user messaging. The only user content that may be visible to others is a shortened name and profile photo shown in
challenges, and only if the user explicitly opts in. Conversations with the AI coach are visible only to the user.</p>

<h2>2. Prohibited content and behaviour</h2>
<ul>
<li>Any image, text or other content that depicts, promotes or sexualises the abuse of children (CSAM).</li>
<li>Any attempt to contact, groom or manipulate children for sexual purposes.</li>
<li>Any activity involving the sexual exploitation or trafficking of children, or facilitating it.</li>
<li>Attempting to generate or obtain such content through AI features.</li>
</ul>

<h2>3. Prevention</h2>
<ul>
<li>Users must be at least 13 years old; users under 18 must have parental or guardian supervision.</li>
<li>There is no direct messaging between users; content visible to others is limited to a profile name and photo.</li>
<li>AI features run with safety rules designed to refuse sexual content and harmful requests involving minors.</li>
</ul>

<h2>4. Reporting</h2>
<p>If you see content or behaviour in the App or our services that threatens child safety, report it to us immediately:</p>
<ul>
<li><strong>In the App:</strong> <em>Profile → Legal &amp; support → Contact support</em></li>
<li><strong>Email:</strong> {EMAIL} (subject: "Child safety")</li>
</ul>
<p>If possible, include the user's name, a screenshot and the date. Do not copy, store or share child sexual abuse material yourself;
report it only to us and to the authorities. If a child is in immediate danger, first call your local emergency number (e.g.
<strong>112</strong> in Türkiye and the EU, <strong>911</strong> in the US).</p>

<h2>5. Response</h2>
<ul>
<li>Reports are reviewed as a priority.</li>
<li>Violating content is removed immediately and the account involved is permanently closed.</li>
<li>Where child sexual abuse material is identified, we report it to the competent authorities as required by applicable law (law
enforcement in Türkiye and, where applicable, international organisations including NCMEC in the US).</li>
<li>We cooperate with authorities in investigations and preserve records as required by law.</li>
</ul>

<h2>6. Legal compliance</h2>
<p>MochiFast complies with applicable child safety laws and with Google Play and App Store policies.</p>

<h2>7. Child safety point of contact</h2>
<p>For questions about our child safety practices and these standards, contact: {EMAIL}</p>
"""

PAGES = {
    "privacy-policy": {
        "title": {"tr": "MochiFast – Gizlilik Politikası", "en": "MochiFast – Privacy Policy"},
        "desc": "MochiFast privacy policy / gizlilik politikası",
        "body": {"tr": PRIVACY_TR, "en": PRIVACY_EN},
    },
    "terms": {
        "title": {"tr": "MochiFast – Kullanım Koşulları", "en": "MochiFast – Terms of Use"},
        "desc": "MochiFast terms of use / kullanım koşulları",
        "body": {"tr": TERMS_TR, "en": TERMS_EN},
    },
    "cookies": {
        "title": {"tr": "MochiFast – Çerez Politikası", "en": "MochiFast – Cookie Policy"},
        "desc": "MochiFast cookie policy / çerez politikası",
        "body": {"tr": COOKIES_TR, "en": COOKIES_EN},
    },
    "csae": {
        "title": {
            "tr": "MochiFast – Çocuk Güvenliği Standartları (CSAE)",
            "en": "MochiFast – Child Safety Standards (CSAE)",
        },
        "desc": "MochiFast child safety standards against CSAE / çocuk güvenliği standartları",
        "body": {"tr": CSAE_TR, "en": CSAE_EN},
    },
}
