import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In tr, this message translates to:
  /// **'UNUTMA'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In tr, this message translates to:
  /// **'Önemli şeyler, aklında kalmasın.'**
  String get tagline;

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Ana sayfa'**
  String get home;

  /// No description provided for @inbox.
  ///
  /// In tr, this message translates to:
  /// **'Kontrol et'**
  String get inbox;

  /// No description provided for @history.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @today.
  ///
  /// In tr, this message translates to:
  /// **'BUGÜN'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In tr, this message translates to:
  /// **'YARIN'**
  String get tomorrow;

  /// No description provided for @week.
  ///
  /// In tr, this message translates to:
  /// **'BU HAFTA'**
  String get week;

  /// No description provided for @later.
  ///
  /// In tr, this message translates to:
  /// **'SONRA'**
  String get later;

  /// No description provided for @overdue.
  ///
  /// In tr, this message translates to:
  /// **'TARİHİ GEÇENLER'**
  String get overdue;

  /// No description provided for @morning.
  ///
  /// In tr, this message translates to:
  /// **'Günaydın'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In tr, this message translates to:
  /// **'İyi günler'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In tr, this message translates to:
  /// **'İyi akşamlar'**
  String get evening;

  /// No description provided for @allClear.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik her şey yolunda.'**
  String get allClear;

  /// No description provided for @emptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Önemli bir bildirim yakaladığımda burada göreceksin.'**
  String get emptyBody;

  /// No description provided for @localBadge.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca telefonunda'**
  String get localBadge;

  /// No description provided for @autoOff.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik yakalama çalışmıyor'**
  String get autoOff;

  /// No description provided for @autoOffBody.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim erişimi kapalı olabilir veya Android bağlantıyı durdurmuş olabilir. Ayarlarda UNUTMA erişimini kapatıp yeniden aç.'**
  String get autoOffBody;

  /// No description provided for @openAccess.
  ///
  /// In tr, this message translates to:
  /// **'Erişimi ayarla'**
  String get openAccess;

  /// No description provided for @add.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ekle'**
  String get add;

  /// No description provided for @manual.
  ///
  /// In tr, this message translates to:
  /// **'Kendin ekle'**
  String get manual;

  /// No description provided for @done.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get done;

  /// No description provided for @paid.
  ///
  /// In tr, this message translates to:
  /// **'Ödendi'**
  String get paid;

  /// No description provided for @snooze.
  ///
  /// In tr, this message translates to:
  /// **'Yarın hatırlat'**
  String get snooze;

  /// No description provided for @archive.
  ///
  /// In tr, this message translates to:
  /// **'Arşivle'**
  String get archive;

  /// No description provided for @confirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get confirm;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @ignore.
  ///
  /// In tr, this message translates to:
  /// **'Yoksay'**
  String get ignore;

  /// No description provided for @reviewLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kontrolün gerekiyor'**
  String get reviewLabel;

  /// No description provided for @emptyInbox.
  ///
  /// In tr, this message translates to:
  /// **'Kontrol bekleyen bildirim yok.'**
  String get emptyInbox;

  /// No description provided for @emptyInboxBody.
  ///
  /// In tr, this message translates to:
  /// **'Emin olamadığım tarihleri ve bildirimleri onayına sunarım.'**
  String get emptyInboxBody;

  /// No description provided for @emptyHistory.
  ///
  /// In tr, this message translates to:
  /// **'Tamamladığın şeyler burada görünecek.'**
  String get emptyHistory;

  /// No description provided for @historyBody.
  ///
  /// In tr, this message translates to:
  /// **'Biraz daha hafif bir zihin, her tamamlanan işle.'**
  String get historyBody;

  /// No description provided for @search.
  ///
  /// In tr, this message translates to:
  /// **'Geçmişte ara'**
  String get search;

  /// No description provided for @all.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get all;

  /// No description provided for @archived.
  ///
  /// In tr, this message translates to:
  /// **'Arşivlenen'**
  String get archived;

  /// No description provided for @completed.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan'**
  String get completed;

  /// No description provided for @newCard.
  ///
  /// In tr, this message translates to:
  /// **'Aklında kalmasın.'**
  String get newCard;

  /// No description provided for @editCard.
  ///
  /// In tr, this message translates to:
  /// **'Kartı düzenle'**
  String get editCard;

  /// No description provided for @what.
  ///
  /// In tr, this message translates to:
  /// **'Ne hatırlatayım?'**
  String get what;

  /// No description provided for @titleHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. İnternet faturası'**
  String get titleHint;

  /// No description provided for @category.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get category;

  /// No description provided for @when.
  ///
  /// In tr, this message translates to:
  /// **'Ne zaman?'**
  String get when;

  /// No description provided for @date.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get date;

  /// No description provided for @time.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get time;

  /// No description provided for @dueToday.
  ///
  /// In tr, this message translates to:
  /// **'Son ödeme bugün'**
  String get dueToday;

  /// No description provided for @tomorrowAt.
  ///
  /// In tr, this message translates to:
  /// **'Yarın • {time}'**
  String tomorrowAt(String time);

  /// No description provided for @pickupDaysLeft.
  ///
  /// In tr, this message translates to:
  /// **'Şubeden alınmalı • {count} gün kaldı'**
  String pickupDaysLeft(int count);

  /// No description provided for @chooseDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih seç'**
  String get chooseDate;

  /// No description provided for @reminder.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma'**
  String get reminder;

  /// No description provided for @atTime.
  ///
  /// In tr, this message translates to:
  /// **'O saatte'**
  String get atTime;

  /// No description provided for @oneHour.
  ///
  /// In tr, this message translates to:
  /// **'1 saat önce'**
  String get oneHour;

  /// No description provided for @oneDay.
  ///
  /// In tr, this message translates to:
  /// **'1 gün önce'**
  String get oneDay;

  /// No description provided for @threeDays.
  ///
  /// In tr, this message translates to:
  /// **'3 gün önce'**
  String get threeDays;

  /// No description provided for @noReminder.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma yok'**
  String get noReminder;

  /// No description provided for @customReminder.
  ///
  /// In tr, this message translates to:
  /// **'Özel (dakika önce)'**
  String get customReminder;

  /// No description provided for @optional.
  ///
  /// In tr, this message translates to:
  /// **'Diğer ayrıntılar'**
  String get optional;

  /// No description provided for @amount.
  ///
  /// In tr, this message translates to:
  /// **'Tutar'**
  String get amount;

  /// No description provided for @currency.
  ///
  /// In tr, this message translates to:
  /// **'Para birimi'**
  String get currency;

  /// No description provided for @note.
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get note;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// No description provided for @requiredTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kısa bir başlık yaz.'**
  String get requiredTitle;

  /// No description provided for @requiredDate.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için bir tarih seç.'**
  String get requiredDate;

  /// No description provided for @invalidAmount.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir tutar yaz.'**
  String get invalidAmount;

  /// No description provided for @source.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak'**
  String get source;

  /// No description provided for @sourceMessage.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak mesaj'**
  String get sourceMessage;

  /// No description provided for @sourceMessageStored.
  ///
  /// In tr, this message translates to:
  /// **'Bu mesaj yalnızca telefonunda şifreli saklanır.'**
  String get sourceMessageStored;

  /// No description provided for @deleteSourceMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mesajı sil'**
  String get deleteSourceMessage;

  /// No description provided for @deleteSourceMessageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak mesaj silinsin mi?'**
  String get deleteSourceMessageTitle;

  /// No description provided for @deleteSourceMessageBody.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj metni bu karttan kalıcı olarak kaldırılır. Hatırlatma kartı korunur.'**
  String get deleteSourceMessageBody;

  /// No description provided for @sourceMessageDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak mesaj silindi.'**
  String get sourceMessageDeleted;

  /// No description provided for @manualSource.
  ///
  /// In tr, this message translates to:
  /// **'Sen ekledin'**
  String get manualSource;

  /// No description provided for @unknownSource.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen uygulama'**
  String get unknownSource;

  /// No description provided for @noDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih doğrulanmalı'**
  String get noDate;

  /// No description provided for @detail.
  ///
  /// In tr, this message translates to:
  /// **'Aksiyon kartı'**
  String get detail;

  /// No description provided for @dueDate.
  ///
  /// In tr, this message translates to:
  /// **'İlgili tarih'**
  String get dueDate;

  /// No description provided for @reviewBefore.
  ///
  /// In tr, this message translates to:
  /// **'Bu bildirimden emin olamadım. Tarihi kontrol edip onayla.'**
  String get reviewBefore;

  /// No description provided for @approximate.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatmalar pil optimizasyonuna bağlı olarak gecikebilir. Kesin saat garantisi verilmez.'**
  String get approximate;

  /// No description provided for @pastReminder.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş hatırlatma saatleri için bildirim gönderilmez.'**
  String get pastReminder;

  /// No description provided for @notificationAccess.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim erişimi'**
  String get notificationAccess;

  /// No description provided for @enabled.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get disabled;

  /// No description provided for @reminderPermission.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma bildirimleri'**
  String get reminderPermission;

  /// No description provided for @reminderOff.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma bildirimi kapalı. Kartların kaydedilir; bildirim almak için izin ver.'**
  String get reminderOff;

  /// No description provided for @reminderDefaults.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan hatırlatma'**
  String get reminderDefaults;

  /// No description provided for @privacy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik'**
  String get privacy;

  /// No description provided for @localData.
  ///
  /// In tr, this message translates to:
  /// **'Yerel veriler'**
  String get localData;

  /// No description provided for @deleteAll.
  ///
  /// In tr, this message translates to:
  /// **'Tüm yerel verileri sil'**
  String get deleteAll;

  /// No description provided for @deleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yerel veriler silinsin mi?'**
  String get deleteTitle;

  /// No description provided for @deleteBody.
  ///
  /// In tr, this message translates to:
  /// **'Tüm kartlar, şifreli önizlemeler, hatırlatmalar ve yok sayılan kaynaklar kalıcı olarak silinir. Görünüm ve dil sıfırlanır. Tanıtımı tamamladığın bilgisi korunur. Bildirim erişimi Android ayarlarından ayrıca kapatılabilir.'**
  String get deleteBody;

  /// No description provided for @deleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Evet, hepsini sil'**
  String get deleteConfirm;

  /// No description provided for @deleted.
  ///
  /// In tr, this message translates to:
  /// **'Yerel veriler silindi.'**
  String get deleted;

  /// No description provided for @preferences.
  ///
  /// In tr, this message translates to:
  /// **'TERCİHLER'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get theme;

  /// No description provided for @system.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get system;

  /// No description provided for @light.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get dark;

  /// No description provided for @ignoredSources.
  ///
  /// In tr, this message translates to:
  /// **'Yok sayılan kaynaklar'**
  String get ignoredSources;

  /// No description provided for @sourcesBody.
  ///
  /// In tr, this message translates to:
  /// **'Bir kaynağı kapattığında yeni bildirimleri işlenmez. Var olan kartlar korunur.'**
  String get sourcesBody;

  /// No description provided for @noSources.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir kaynak yok.'**
  String get noSources;

  /// No description provided for @about.
  ///
  /// In tr, this message translates to:
  /// **'HAKKINDA'**
  String get about;

  /// No description provided for @version.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik ilkesi'**
  String get privacyPolicy;

  /// No description provided for @terms.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım koşulları'**
  String get terms;

  /// No description provided for @privacyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimlerin\ntelefonunda kalır.'**
  String get privacyTitle;

  /// No description provided for @privacyLocalAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz üzerinde analiz'**
  String get privacyLocalAnalysis;

  /// No description provided for @privacyNoCloud.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim metni buluta gönderilmez'**
  String get privacyNoCloud;

  /// No description provided for @privacyDeleteAnytime.
  ///
  /// In tr, this message translates to:
  /// **'Tüm yerel veriyi istediğin zaman silebilirsin'**
  String get privacyDeleteAnytime;

  /// No description provided for @privacyBody.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim başlığı ve gerekli metin alanları yalnızca cihaz üzerinde analiz edilir. Bildirim metni sunucuya, reklam veya analitik sistemlerine gönderilmez. SMS veya e-posta kutuları doğrudan okunmaz; kaynak uygulamanın bildirimi kapalıysa UNUTMA o içeriği göremez.'**
  String get privacyBody;

  /// No description provided for @privacyStorage.
  ///
  /// In tr, this message translates to:
  /// **'Gerekli kart bilgileri yerel veritabanında saklanır. Kaynak mesajlar Android Keystore ile şifrelenir; kart tamamlanınca, arşivlenince veya sen sildiğinde kaldırılır. Geçmiş 90 gün tutulur. Bulut yedekleme kapalıdır.'**
  String get privacyStorage;

  /// No description provided for @termsBody.
  ///
  /// In tr, this message translates to:
  /// **'UNUTMA yardımcı bir hatırlatma aracıdır. Çıkarılan bilgileri kontrol et. Bildirim erişimi, cihaz kısıtlamaları ve pil ayarları çalışmayı etkileyebilir. Kritik ödeme ve randevular için tek güvence olarak kullanma. Bu sürümde reklam, satın alma ve bulut hizmeti etkin değildir.'**
  String get termsBody;

  /// No description provided for @termsBodyWithAds.
  ///
  /// In tr, this message translates to:
  /// **'UNUTMA yardımcı bir hatırlatma aracıdır. Çıkarılan bilgileri kontrol et. Bildirim erişimi, cihaz kısıtlamaları ve pil ayarları çalışmayı etkileyebilir. Kritik ödeme ve randevular için tek güvence olarak kullanma. Bu sürümde Google AdMob üzerinden seyrek reklamlar gösterilebilir; satın alma ve bulut hizmeti etkin değildir.'**
  String get termsBodyWithAds;

  /// No description provided for @adPrivacyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Reklam ve gizlilik'**
  String get adPrivacyTitle;

  /// No description provided for @adPrivacyBody.
  ///
  /// In tr, this message translates to:
  /// **'Google Mobile Ads SDK reklam, ölçüm ve sahtekârlığı önleme için IP adresi (yaklaşık genel konum tahmini), uygulama etkileşimleri, tanılama bilgileri ile cihaz veya hesap tanımlayıcılarını otomatik olarak toplayabilir ve Google ile paylaşabilir. Aktarım TLS ile şifrelenir. Bildirim metni, kart başlığı, tutar, not veya kaynak uygulama reklam isteğine eklenmez.'**
  String get adPrivacyBody;

  /// No description provided for @manageAdPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Reklam gizlilik seçenekleri'**
  String get manageAdPrivacy;

  /// No description provided for @manageAdPrivacyBody.
  ///
  /// In tr, this message translates to:
  /// **'Uygulanabilir bölgesel reklam izinlerini incele veya değiştir.'**
  String get manageAdPrivacyBody;

  /// No description provided for @pro.
  ///
  /// In tr, this message translates to:
  /// **'UNUTMA Pro'**
  String get pro;

  /// No description provided for @proTitle.
  ///
  /// In tr, this message translates to:
  /// **'Önce önemli olan.'**
  String get proTitle;

  /// No description provided for @proBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu sürümde satın alma etkin değil. Bildirim yakalama, kartlar ve temel hatırlatmalar ücretsiz kullanılabilir.'**
  String get proBody;

  /// No description provided for @billingDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma yapılandırılmamış'**
  String get billingDisabled;

  /// No description provided for @restore.
  ///
  /// In tr, this message translates to:
  /// **'Satın alımları geri yükle'**
  String get restore;

  /// No description provided for @onboardValue.
  ///
  /// In tr, this message translates to:
  /// **'Önemli olanı senin\nyerine hatırlar.'**
  String get onboardValue;

  /// No description provided for @onboardValueBody.
  ///
  /// In tr, this message translates to:
  /// **'Fatura, randevu, kargo ve süreli bildirimleri sessizce yakalar.'**
  String get onboardValueBody;

  /// No description provided for @onboardTransform.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim gelir.\nYapılacak iş netleşir.'**
  String get onboardTransform;

  /// No description provided for @onboardTransformBody.
  ///
  /// In tr, this message translates to:
  /// **'UNUTMA önemli bilgiyi ayırır. Sen yalnızca ne zaman ilgileneceğini bilirsin.'**
  String get onboardTransformBody;

  /// No description provided for @onboardAccess.
  ///
  /// In tr, this message translates to:
  /// **'Kontrol her zaman sende.'**
  String get onboardAccess;

  /// No description provided for @accessWhat.
  ///
  /// In tr, this message translates to:
  /// **'Neye erişir?'**
  String get accessWhat;

  /// No description provided for @accessWhatBody.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim başlığı ve gerekli metin alanlarına.'**
  String get accessWhatBody;

  /// No description provided for @accessWhy.
  ///
  /// In tr, this message translates to:
  /// **'Neden?'**
  String get accessWhy;

  /// No description provided for @accessWhyBody.
  ///
  /// In tr, this message translates to:
  /// **'Fatura, randevu, teslimat ve tarih içeren önemli bildirimleri ayırmak için.'**
  String get accessWhyBody;

  /// No description provided for @accessWhere.
  ///
  /// In tr, this message translates to:
  /// **'Nereye gider?'**
  String get accessWhere;

  /// No description provided for @accessWhereBody.
  ///
  /// In tr, this message translates to:
  /// **'İçerik cihazdan dışarı gönderilmez. İzin Android ayarlarından yönetilir.'**
  String get accessWhereBody;

  /// No description provided for @continueLabel.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get continueLabel;

  /// No description provided for @skip.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik geç'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In tr, this message translates to:
  /// **'Başlayalım'**
  String get getStarted;

  /// No description provided for @enableNotificationAccess.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim erişimini aç'**
  String get enableNotificationAccess;

  /// No description provided for @exampleNotification.
  ///
  /// In tr, this message translates to:
  /// **'İnternet faturanızın son ödeme tarihi 8 Eylül.'**
  String get exampleNotification;

  /// No description provided for @exampleBill.
  ///
  /// In tr, this message translates to:
  /// **'İnternet faturası'**
  String get exampleBill;

  /// No description provided for @exampleDate.
  ///
  /// In tr, this message translates to:
  /// **'8 Eylül'**
  String get exampleDate;

  /// No description provided for @exampleLabel.
  ///
  /// In tr, this message translates to:
  /// **'NASIL ÇALIŞIR'**
  String get exampleLabel;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

  /// No description provided for @errorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şu an tamamlanamadı.'**
  String get errorTitle;

  /// No description provided for @errorBody.
  ///
  /// In tr, this message translates to:
  /// **'Yerel verilere erişilemedi. Tekrar deneyebilirsin.'**
  String get errorBody;

  /// No description provided for @saved.
  ///
  /// In tr, this message translates to:
  /// **'Kart kaydedildi.'**
  String get saved;

  /// No description provided for @updated.
  ///
  /// In tr, this message translates to:
  /// **'Kart güncellendi.'**
  String get updated;

  /// No description provided for @shareTitle.
  ///
  /// In tr, this message translates to:
  /// **'UNUTMA’ya ekle'**
  String get shareTitle;

  /// No description provided for @shareBody.
  ///
  /// In tr, this message translates to:
  /// **'Paylaştığın metin yalnızca bu cihazda analiz edilir. Devam etmeden hiçbir şey kaydedilmez.'**
  String get shareBody;

  /// No description provided for @sharePreview.
  ///
  /// In tr, this message translates to:
  /// **'PAYLAŞILAN METİN'**
  String get sharePreview;

  /// No description provided for @shareAnalyze.
  ///
  /// In tr, this message translates to:
  /// **'Analiz et'**
  String get shareAnalyze;

  /// No description provided for @shareNoMatch.
  ///
  /// In tr, this message translates to:
  /// **'Net bir işlem veya tarih bulunamadı. Elle tamamlayabilirsin.'**
  String get shareNoMatch;

  /// No description provided for @shareEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşılacak metin bulunamadı.'**
  String get shareEmpty;

  /// No description provided for @notFound.
  ///
  /// In tr, this message translates to:
  /// **'Bu kart artık mevcut değil.'**
  String get notFound;

  /// No description provided for @filter.
  ///
  /// In tr, this message translates to:
  /// **'Filtrele'**
  String get filter;

  /// No description provided for @dateRange.
  ///
  /// In tr, this message translates to:
  /// **'Tarih aralığı'**
  String get dateRange;

  /// No description provided for @clearFilters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri temizle'**
  String get clearFilters;

  /// No description provided for @bill.
  ///
  /// In tr, this message translates to:
  /// **'Fatura'**
  String get bill;

  /// No description provided for @paymentDue.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme'**
  String get paymentDue;

  /// No description provided for @packageDelivery.
  ///
  /// In tr, this message translates to:
  /// **'Kargo'**
  String get packageDelivery;

  /// No description provided for @packagePickup.
  ///
  /// In tr, this message translates to:
  /// **'Teslim alınacak'**
  String get packagePickup;

  /// No description provided for @appointment.
  ///
  /// In tr, this message translates to:
  /// **'Randevu'**
  String get appointment;

  /// No description provided for @reservation.
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyon'**
  String get reservation;

  /// No description provided for @subscriptionRenewal.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik'**
  String get subscriptionRenewal;

  /// No description provided for @returnWindow.
  ///
  /// In tr, this message translates to:
  /// **'İade süresi'**
  String get returnWindow;

  /// No description provided for @ticketEvent.
  ///
  /// In tr, this message translates to:
  /// **'Bilet / etkinlik'**
  String get ticketEvent;

  /// No description provided for @travel.
  ///
  /// In tr, this message translates to:
  /// **'Seyahat'**
  String get travel;

  /// No description provided for @deadline.
  ///
  /// In tr, this message translates to:
  /// **'Son tarih'**
  String get deadline;

  /// No description provided for @other.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get other;

  /// No description provided for @attentionCount.
  ///
  /// In tr, this message translates to:
  /// **'Bugün dikkat etmen gereken {count} şey var.'**
  String attentionCount(int count);

  /// No description provided for @reviewCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} bildirim senden onay bekliyor.'**
  String reviewCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
