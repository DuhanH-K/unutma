# UNUTMA Privacy Policy / Gizlilik Politikası

**Effective date / Yürürlük tarihi:** 31 August 2026  
**Developer / Geliştirici:** Duhan Hamit Kaplan  
**Contact / İletişim:** dhkaplancode@gmail.com  
**Public URL:** https://unutma-app-dhk.web.app/gizlilik

This repository copy describes the implemented application behavior; it is not
legal advice.

## Türkçe

UNUTMA, bildirimlerdeki fatura, randevu, teslimat ve son tarih gibi işlem
gerektiren bilgileri cihaz üzerinde analiz ederek yerel hatırlatma kartlarına
dönüştürür. Bildirim içeriği, kart başlıkları, tutarlar, notlar ve kaynak uygulama
bilgileri geliştirici sunucusuna, Google AdMob'a veya analitik hizmetine
gönderilmez.
Uygulama SMS veya e-posta kutularına bağlanmaz ve bunları doğrudan okumaz.
Kaynak uygulama bildirim yayımlamazsa UNUTMA alttaki mesajı göremez.
Kullanıcı, Android paylaşım menüsünden düz metni açıkça UNUTMA'ya gönderebilir.
Metin önce bellekte önizlenir; kullanıcı devam etmeden saklanmaz. Ekler ve içerik
URI'ları açılmaz.

Uygulama; gerekli kart alanlarını yerel Room veritabanında saklar. Kısa bildirim
önizlemeleri Android Keystore anahtarıyla AES-256-GCM kullanılarak şifrelenir ve
en geç yedi gün sonra yapılan yerel bakımda silinir. Tamamlanan veya arşivlenen
kartların önizlemeleri hemen silinir; kapatılmış kart geçmişi 90 gün tutulur.
Bulut yedekleme ve cihaz aktarımı özel uygulama verileri için kapalıdır.

Reklamların etkin olduğu sürüm Google Mobile Ads SDK ve Google User Messaging
Platform'u kullanır. Google Mobile Ads SDK reklam, ölçüm ve sahtekârlığı önleme
amaçlarıyla IP adresi (yaklaşık genel konum tahmini), uygulama etkileşimleri,
tanılama bilgileri ve cihaz/hesap tanımlayıcılarını otomatik olarak toplayabilir
ve Google ile paylaşabilir. Google bu aktarımın TLS ile şifrelendiğini belirtir.
Reklam isteğine bildirim veya kart verisi eklenmez. Uygulanabilir bölgelerde izin
seçenekleri UMP ekranında sunulur ve Ayarlar > Gizlilik bölümünden tekrar
açılabilir. Google'ın veri uygulamaları için
https://policies.google.com/privacy adresini inceleyebilirsiniz.

Bildirim erişimi Android tarafından yönetilen özel bir erişimdir ve yalnızca
kullanıcı Android ayarlarından açıkça etkinleştirirse kullanılır. Hatırlatma
bildirim izni ayrıdır. Uygulama konum, kişi, takvim, SMS, arama kaydı veya
Accessibility Service izni istemez. Kullanıcı otomatik yakalamayı reddederek
manuel kartları kullanmaya devam edebilir.

Ayarlar > Tüm yerel verileri sil işlemi kartları, kaynak tercihlerini, şifreli
önizlemeleri, planlanmış işleri ve yerel reklam frekans sayaçlarını siler. Android
bildirim erişimi Android ayarlarından ayrıca kapatılır. UMP reklam izinleri,
gerekli olduğunda Reklam gizlilik seçenekleri üzerinden değiştirilir.

UNUTMA çocuklara yönelik tasarlanmamıştır. Yayıncı, Play Console hedef kitle ve
aile beyanlarını uygulamanın gerçek dağıtımına göre tamamlamalıdır. Politika
değişirse yürürlük tarihi güncellenir. Gizlilik soruları ve veri talepleri için
yukarıdaki yayıncı iletişim adresi kullanılmalıdır.

## English

UNUTMA analyzes actionable information in notifications, such as bills,
appointments, deliveries, and deadlines, on the device and turns it into local
reminder cards. Notification content, card titles, amounts, notes, and source-app
information are not sent to a developer server, Google AdMob, or an analytics
service.
The app does not connect to or directly read SMS or email inboxes. If a source
app does not post a notification, UNUTMA cannot see the underlying message.
The user can explicitly send plain text to UNUTMA through Android's share menu.
It is previewed in memory and is not stored until the user continues. Attachments
and content URIs are not opened.

The app stores necessary card fields in a local Room database. Short notification
previews are encrypted with AES-256-GCM using an Android Keystore key and removed
during the next local maintenance after no more than seven days. Preview data is
removed immediately when a card is completed or archived, and closed-card history
is retained for 90 days. Cloud backup and device transfer are disabled for private
app data.

An ad-enabled build uses the Google Mobile Ads SDK and Google User Messaging
Platform. The Google Mobile Ads SDK may automatically collect and share IP address
(which can estimate general location), app interactions, diagnostic information,
and device/account identifiers with Google for advertising, measurement, and
fraud prevention. Google states that this data is encrypted in transit using TLS.
No notification or card data is added to an ad request. Where applicable, UMP
presents consent choices that can be reopened from Settings > Privacy. See
Google's privacy policy at https://policies.google.com/privacy.

Notification access is a special Android access used only after the user enables
it explicitly in Android settings. Reminder notification permission is separate.
The app does not request location, contacts, calendar, SMS, call-log, or
Accessibility Service access. Users can decline automatic capture and continue
using manual cards.

Settings > Delete all local data removes cards, source preferences, encrypted
previews, scheduled work, and local ad-frequency counters. Android notification
access must be revoked separately in Android settings. UMP advertising choices
can be changed through Ad privacy options when required.

UNUTMA is not designed for children. The publisher must complete the Play Console
target-audience and Families declarations according to the actual distribution.
If this policy changes, its effective date will be updated. Use the publisher
contact above for privacy questions and data requests.
