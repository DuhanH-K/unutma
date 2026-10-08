# Google Play listing draft

**Developer / Geliştirici:** Duhan Hamit Kaplan  
**Support / Destek:** dhkaplancode@gmail.com

## Turkish

**App name:** UNUTMA  
**Short description:** Önemli bildirimleri yerel aksiyon kartlarına ve hatırlatmalara dönüştürür.  

**Full description:**

UNUTMA, telefonuna gelen fatura, randevu, teslimat, rezervasyon ve son tarih
bildirimlerini cihaz üzerinde analiz eder. Yapman gereken işi sade bir Aksiyon
Kartı olarak gösterir ve seçtiğin zamanda hatırlatır.

- Önemli bildirimlerden otomatik Aksiyon Kartları
- Emin olunamayan bilgiler için kontrol kutusu
- Kendi hatırlatma kartını elle ekleme
- Gmail, Mesajlar ve diğer uygulamalardan Paylaş → UNUTMA
- Tamamlanan ve arşivlenen kart geçmişi
- Türkçe ve İngilizce arayüz
- Açık ve koyu görünüm
- Cihaz üzerinde çalışan, privacy-first mimari

Bildirim metni buluta gönderilmez. Otomatik yakalama için Android bildirim
erişimini sen açarsın; erişim verilmeden manuel kartları kullanabilirsin.
Bildirim düşmeyen bir metni paylaşım menüsünden açıkça UNUTMA'ya aktarabilirsin;
uygulama e-posta veya SMS kutusunu doğrudan okumaz.
WorkManager ve cihaz pil kuralları nedeniyle hatırlatmalar gecikebilir. Kritik
ödeme ve randevular için UNUTMA'yı tek güvence olarak kullanma.

Uygulama seyrek reklamlar içerebilir. Reklamlara bildirim veya kart içeriği
aktarılmaz.

## English

**App name:** UNUTMA  
**Short description:** Turns important notifications into private action cards and reminders.  

**Full description:**

UNUTMA analyzes bill, appointment, delivery, reservation, and deadline
notifications on your device. It turns the next step into a clear Action Card and
reminds you at the time you choose.

- Automatic Action Cards from important notifications
- A review inbox for uncertain information
- Manual reminder cards
- Share text from Gmail, Messages, and other apps
- Completed and archived history
- Turkish and English interface
- Light and dark appearance
- Privacy-first, on-device notification processing

Notification text is not sent to the cloud. You choose whether to enable Android
notification access for automatic capture, and manual cards remain available
without it. If a notification is unavailable, you can explicitly send text
through Android's share menu; the app does not directly read email or SMS inboxes.
WorkManager and device battery restrictions can delay reminders. Do
not use UNUTMA as your only safeguard for critical payments or appointments.

The app may contain occasional ads. Notification and card content is never sent
with an ad request.

## Console declarations and review notes

- Ads: **Yes**.
- App access: no account, login, or reviewer credential is required.
- Primary language: Turkish; English translation is included.
- Recommended category: Productivity.
- Target audience: publisher decision required; the product is not designed for
  children and should not be enrolled in Families without a separate review.
- Reviewer path: launch app, skip or finish onboarding, add a manual card. For
  automatic capture, open Settings > Notification access and enable UNUTMA in the
  Android system screen. Explain that this special access is the core feature and
  that all parsing remains on device.
- Privacy policy: host `privacy-policy.md` at a public HTTPS URL and add that URL
  in Play Console before any closed/open/production release.
