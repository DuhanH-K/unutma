// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'UNUTMA';

  @override
  String get tagline => 'Önemli şeyler, aklında kalmasın.';

  @override
  String get home => 'Ana sayfa';

  @override
  String get inbox => 'Kontrol et';

  @override
  String get history => 'Geçmiş';

  @override
  String get settings => 'Ayarlar';

  @override
  String get today => 'BUGÜN';

  @override
  String get tomorrow => 'YARIN';

  @override
  String get week => 'BU HAFTA';

  @override
  String get later => 'SONRA';

  @override
  String get overdue => 'TARİHİ GEÇENLER';

  @override
  String get morning => 'Günaydın';

  @override
  String get afternoon => 'İyi günler';

  @override
  String get evening => 'İyi akşamlar';

  @override
  String get allClear => 'Şimdilik her şey yolunda.';

  @override
  String get emptyBody =>
      'Önemli bir bildirim yakaladığımda burada göreceksin.';

  @override
  String get localBadge => 'Yalnızca telefonunda';

  @override
  String get autoOff => 'Otomatik yakalama çalışmıyor';

  @override
  String get autoOffBody =>
      'Bildirim erişimi kapalı olabilir veya Android bağlantıyı durdurmuş olabilir. Ayarlarda UNUTMA erişimini kapatıp yeniden aç.';

  @override
  String get openAccess => 'Erişimi ayarla';

  @override
  String get add => 'Yeni ekle';

  @override
  String get manual => 'Kendin ekle';

  @override
  String get done => 'Tamamlandı';

  @override
  String get paid => 'Ödendi';

  @override
  String get snooze => 'Yarın hatırlat';

  @override
  String get archive => 'Arşivle';

  @override
  String get confirm => 'Onayla';

  @override
  String get edit => 'Düzenle';

  @override
  String get ignore => 'Yoksay';

  @override
  String get reviewLabel => 'Kontrolün gerekiyor';

  @override
  String get emptyInbox => 'Kontrol bekleyen bildirim yok.';

  @override
  String get emptyInboxBody =>
      'Emin olamadığım tarihleri ve bildirimleri onayına sunarım.';

  @override
  String get emptyHistory => 'Tamamladığın şeyler burada görünecek.';

  @override
  String get historyBody => 'Biraz daha hafif bir zihin, her tamamlanan işle.';

  @override
  String get search => 'Geçmişte ara';

  @override
  String get all => 'Tümü';

  @override
  String get archived => 'Arşivlenen';

  @override
  String get completed => 'Tamamlanan';

  @override
  String get newCard => 'Aklında kalmasın.';

  @override
  String get editCard => 'Kartı düzenle';

  @override
  String get what => 'Ne hatırlatayım?';

  @override
  String get titleHint => 'Örn. İnternet faturası';

  @override
  String get category => 'Kategori';

  @override
  String get when => 'Ne zaman?';

  @override
  String get date => 'Tarih';

  @override
  String get time => 'Saat';

  @override
  String get dueToday => 'Son ödeme bugün';

  @override
  String tomorrowAt(String time) {
    return 'Yarın • $time';
  }

  @override
  String pickupDaysLeft(int count) {
    return 'Şubeden alınmalı • $count gün kaldı';
  }

  @override
  String get chooseDate => 'Tarih seç';

  @override
  String get reminder => 'Hatırlatma';

  @override
  String get atTime => 'O saatte';

  @override
  String get oneHour => '1 saat önce';

  @override
  String get oneDay => '1 gün önce';

  @override
  String get threeDays => '3 gün önce';

  @override
  String get noReminder => 'Hatırlatma yok';

  @override
  String get customReminder => 'Özel (dakika önce)';

  @override
  String get optional => 'Diğer ayrıntılar';

  @override
  String get amount => 'Tutar';

  @override
  String get currency => 'Para birimi';

  @override
  String get note => 'Not';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get requiredTitle => 'Kısa bir başlık yaz.';

  @override
  String get requiredDate => 'Devam etmek için bir tarih seç.';

  @override
  String get invalidAmount => 'Geçerli bir tutar yaz.';

  @override
  String get source => 'Kaynak';

  @override
  String get sourceMessage => 'Kaynak mesaj';

  @override
  String get sourceMessageStored =>
      'Bu mesaj yalnızca telefonunda şifreli saklanır.';

  @override
  String get deleteSourceMessage => 'Mesajı sil';

  @override
  String get deleteSourceMessageTitle => 'Kaynak mesaj silinsin mi?';

  @override
  String get deleteSourceMessageBody =>
      'Mesaj metni bu karttan kalıcı olarak kaldırılır. Hatırlatma kartı korunur.';

  @override
  String get sourceMessageDeleted => 'Kaynak mesaj silindi.';

  @override
  String get manualSource => 'Sen ekledin';

  @override
  String get unknownSource => 'Bilinmeyen uygulama';

  @override
  String get noDate => 'Tarih doğrulanmalı';

  @override
  String get detail => 'Aksiyon kartı';

  @override
  String get dueDate => 'İlgili tarih';

  @override
  String get reviewBefore =>
      'Bu bildirimden emin olamadım. Tarihi kontrol edip onayla.';

  @override
  String get approximate =>
      'Hatırlatmalar pil optimizasyonuna bağlı olarak gecikebilir. Kesin saat garantisi verilmez.';

  @override
  String get pastReminder =>
      'Geçmiş hatırlatma saatleri için bildirim gönderilmez.';

  @override
  String get notificationAccess => 'Bildirim erişimi';

  @override
  String get enabled => 'Açık';

  @override
  String get disabled => 'Kapalı';

  @override
  String get reminderPermission => 'Hatırlatma bildirimleri';

  @override
  String get reminderOff =>
      'Hatırlatma bildirimi kapalı. Kartların kaydedilir; bildirim almak için izin ver.';

  @override
  String get reminderDefaults => 'Varsayılan hatırlatma';

  @override
  String get privacy => 'Gizlilik';

  @override
  String get localData => 'Yerel veriler';

  @override
  String get deleteAll => 'Tüm yerel verileri sil';

  @override
  String get deleteTitle => 'Yerel veriler silinsin mi?';

  @override
  String get deleteBody =>
      'Tüm kartlar, şifreli önizlemeler, hatırlatmalar ve yok sayılan kaynaklar kalıcı olarak silinir. Görünüm ve dil sıfırlanır. Tanıtımı tamamladığın bilgisi korunur. Bildirim erişimi Android ayarlarından ayrıca kapatılabilir.';

  @override
  String get deleteConfirm => 'Evet, hepsini sil';

  @override
  String get deleted => 'Yerel veriler silindi.';

  @override
  String get preferences => 'TERCİHLER';

  @override
  String get language => 'Dil';

  @override
  String get theme => 'Görünüm';

  @override
  String get system => 'Sistem';

  @override
  String get light => 'Açık';

  @override
  String get dark => 'Koyu';

  @override
  String get ignoredSources => 'Yok sayılan kaynaklar';

  @override
  String get sourcesBody =>
      'Bir kaynağı kapattığında yeni bildirimleri işlenmez. Var olan kartlar korunur.';

  @override
  String get noSources => 'Henüz bir kaynak yok.';

  @override
  String get about => 'HAKKINDA';

  @override
  String get version => 'Sürüm';

  @override
  String get privacyPolicy => 'Gizlilik ilkesi';

  @override
  String get terms => 'Kullanım koşulları';

  @override
  String get privacyTitle => 'Bildirimlerin\ntelefonunda kalır.';

  @override
  String get privacyLocalAnalysis => 'Cihaz üzerinde analiz';

  @override
  String get privacyNoCloud => 'Bildirim metni buluta gönderilmez';

  @override
  String get privacyDeleteAnytime =>
      'Tüm yerel veriyi istediğin zaman silebilirsin';

  @override
  String get privacyBody =>
      'Bildirim başlığı ve gerekli metin alanları yalnızca cihaz üzerinde analiz edilir. Bildirim metni sunucuya, reklam veya analitik sistemlerine gönderilmez. SMS veya e-posta kutuları doğrudan okunmaz; kaynak uygulamanın bildirimi kapalıysa UNUTMA o içeriği göremez.';

  @override
  String get privacyStorage =>
      'Gerekli kart bilgileri yerel veritabanında saklanır. Kaynak mesajlar Android Keystore ile şifrelenir; kart tamamlanınca, arşivlenince veya sen sildiğinde kaldırılır. Geçmiş 90 gün tutulur. Bulut yedekleme kapalıdır.';

  @override
  String get termsBody =>
      'UNUTMA yardımcı bir hatırlatma aracıdır. Çıkarılan bilgileri kontrol et. Bildirim erişimi, cihaz kısıtlamaları ve pil ayarları çalışmayı etkileyebilir. Kritik ödeme ve randevular için tek güvence olarak kullanma. Bu sürümde reklam, satın alma ve bulut hizmeti etkin değildir.';

  @override
  String get termsBodyWithAds =>
      'UNUTMA yardımcı bir hatırlatma aracıdır. Çıkarılan bilgileri kontrol et. Bildirim erişimi, cihaz kısıtlamaları ve pil ayarları çalışmayı etkileyebilir. Kritik ödeme ve randevular için tek güvence olarak kullanma. Bu sürümde Google AdMob üzerinden seyrek reklamlar gösterilebilir; satın alma ve bulut hizmeti etkin değildir.';

  @override
  String get adPrivacyTitle => 'Reklam ve gizlilik';

  @override
  String get adPrivacyBody =>
      'Google Mobile Ads SDK reklam, ölçüm ve sahtekârlığı önleme için IP adresi (yaklaşık genel konum tahmini), uygulama etkileşimleri, tanılama bilgileri ile cihaz veya hesap tanımlayıcılarını otomatik olarak toplayabilir ve Google ile paylaşabilir. Aktarım TLS ile şifrelenir. Bildirim metni, kart başlığı, tutar, not veya kaynak uygulama reklam isteğine eklenmez.';

  @override
  String get manageAdPrivacy => 'Reklam gizlilik seçenekleri';

  @override
  String get manageAdPrivacyBody =>
      'Uygulanabilir bölgesel reklam izinlerini incele veya değiştir.';

  @override
  String get pro => 'UNUTMA Pro';

  @override
  String get proTitle => 'Önce önemli olan.';

  @override
  String get proBody =>
      'Bu sürümde satın alma etkin değil. Bildirim yakalama, kartlar ve temel hatırlatmalar ücretsiz kullanılabilir.';

  @override
  String get billingDisabled => 'Satın alma yapılandırılmamış';

  @override
  String get restore => 'Satın alımları geri yükle';

  @override
  String get onboardValue => 'Önemli olanı senin\nyerine hatırlar.';

  @override
  String get onboardValueBody =>
      'Fatura, randevu, kargo ve süreli bildirimleri sessizce yakalar.';

  @override
  String get onboardTransform => 'Bildirim gelir.\nYapılacak iş netleşir.';

  @override
  String get onboardTransformBody =>
      'UNUTMA önemli bilgiyi ayırır. Sen yalnızca ne zaman ilgileneceğini bilirsin.';

  @override
  String get onboardAccess => 'Kontrol her zaman sende.';

  @override
  String get accessWhat => 'Neye erişir?';

  @override
  String get accessWhatBody => 'Bildirim başlığı ve gerekli metin alanlarına.';

  @override
  String get accessWhy => 'Neden?';

  @override
  String get accessWhyBody =>
      'Fatura, randevu, teslimat ve tarih içeren önemli bildirimleri ayırmak için.';

  @override
  String get accessWhere => 'Nereye gider?';

  @override
  String get accessWhereBody =>
      'İçerik cihazdan dışarı gönderilmez. İzin Android ayarlarından yönetilir.';

  @override
  String get continueLabel => 'Devam';

  @override
  String get skip => 'Şimdilik geç';

  @override
  String get getStarted => 'Başlayalım';

  @override
  String get enableNotificationAccess => 'Bildirim erişimini aç';

  @override
  String get exampleNotification =>
      'İnternet faturanızın son ödeme tarihi 8 Eylül.';

  @override
  String get exampleBill => 'İnternet faturası';

  @override
  String get exampleDate => '8 Eylül';

  @override
  String get exampleLabel => 'NASIL ÇALIŞIR';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get errorTitle => 'Şu an tamamlanamadı.';

  @override
  String get errorBody => 'Yerel verilere erişilemedi. Tekrar deneyebilirsin.';

  @override
  String get saved => 'Kart kaydedildi.';

  @override
  String get updated => 'Kart güncellendi.';

  @override
  String get shareTitle => 'UNUTMA’ya ekle';

  @override
  String get shareBody =>
      'Paylaştığın metin yalnızca bu cihazda analiz edilir. Devam etmeden hiçbir şey kaydedilmez.';

  @override
  String get sharePreview => 'PAYLAŞILAN METİN';

  @override
  String get shareAnalyze => 'Analiz et';

  @override
  String get shareNoMatch =>
      'Net bir işlem veya tarih bulunamadı. Elle tamamlayabilirsin.';

  @override
  String get shareEmpty => 'Paylaşılacak metin bulunamadı.';

  @override
  String get notFound => 'Bu kart artık mevcut değil.';

  @override
  String get filter => 'Filtrele';

  @override
  String get dateRange => 'Tarih aralığı';

  @override
  String get clearFilters => 'Filtreleri temizle';

  @override
  String get bill => 'Fatura';

  @override
  String get paymentDue => 'Ödeme';

  @override
  String get packageDelivery => 'Kargo';

  @override
  String get packagePickup => 'Teslim alınacak';

  @override
  String get appointment => 'Randevu';

  @override
  String get reservation => 'Rezervasyon';

  @override
  String get subscriptionRenewal => 'Abonelik';

  @override
  String get returnWindow => 'İade süresi';

  @override
  String get ticketEvent => 'Bilet / etkinlik';

  @override
  String get travel => 'Seyahat';

  @override
  String get deadline => 'Son tarih';

  @override
  String get other => 'Diğer';

  @override
  String attentionCount(int count) {
    return 'Bugün dikkat etmen gereken $count şey var.';
  }

  @override
  String reviewCount(int count) {
    return '$count bildirim senden onay bekliyor.';
  }
}
