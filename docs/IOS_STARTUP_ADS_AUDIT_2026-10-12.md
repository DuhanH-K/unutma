# UNUTMA iOS açılış, yerel hatırlatıcı ve reklam denetimi

Tarih: 12 Ekim 2026. Ortam: Windows, Flutter 3.47.0 / Dart 3.13.0.

Kaynak düzeltmeleri ve Windows doğrulaması tamamlandı. **Gerçek iPhone açılışı, Swift/Xcode derlemesi, iOS simulator, iOS bildirim teslimi ve canlı reklam gösterimi bu makinede doğrulanmadı.** Bu rapor bunları başarılı bir production doğrulaması olarak sunmaz. Mağazaya yükleme, production yayını veya Codemagic tetikleme yapılmadı. Kullanıcının son talimatıyla kaynaklar güvenli commit ve normal main push için final kontrolden geçirildi; Git işlem sonucu teslim mesajında ayrıca raporlanır.

## 1. Açılış hatasının kanıtları

Başlangıçtaki `0a40e14` kaynaklarında Pigeon yapılandırmasında yalnız Dart/Kotlin çıktıları vardı; Swift çıktısı ve iOS `UnutmaApi` host implementasyonu yoktu. `AppDelegate.didInitializeImplicitFlutterEngine` yalnız Flutter pluginlerini ve reklam config kanalını kaydediyordu. `NativeCardRepository.preferences()` ise iOS'ta da `UnutmaApi.getPreferences` kanalını çağırıyordu.

Eksik kanal bir bridge hatası üretir. Riverpod 3.4.3 varsayılan retry mekanizması 10 tekrar, 200 ms başlangıç ve 6400 ms tavan kullanır. Bu beklemelerin toplamı 38,2 saniyedir. Preferences provider yükleme durumunda kaldığı sürece eski arayüz logoyu göstermekteydi. Bu, kullanıcıdaki 27,5 saniyelik logo videosuyla uyumlu, kaynak kodla kanıtlanan bir kusurdur. Gerçek iPhone logu olmadan videodaki tek çalışma zamanı nedeninin bu olduğunu iddia etmiyoruz.

Swift Pigeon üretimi ve 16 host metodu eklendi; kayıt UIScene/implicit-engine yaşam döngüsündeki doğru callback'e bağlandı. Başlangıç provider'larında otomatik retry kapatıldı. Native çağrılar 8 saniye ile sınırlandı; hata ekranı ve kullanıcı tarafından tekrar deneme korunuyor. Reklam SDK'sı, consent veya ağ açılış animasyonunu bekletemez.

## 2. iOS yerel işlevler

- `IOSLocalStore`: Application Support altında atomik JSON kayıt, şema kontrolü, revision çatışması kontrolü, oluşturma/düzenleme/silme/tamamlama/erteleme ve tercihlerin kalıcılığı.
- Kart dosyası iOS Data Protection ile korunur; veri dizini iCloud yedeğinden hariç tutulur. Okunamayan dosya sessizce sıfırlanmaz veya üzerine yazılmaz. Kullanıcının açık veri silme işlemi bozuk dosya için de çalışır.
- `IOSReminders`: gerçek `UNUserNotificationCenter` izinleri, zamanlama, iptal, ön planda sunum ve bildirime dokununca karta yönlendirme.
- Son ödeme tarihi değiştirilmez; hatırlatma offset'i ayrı zamanlanır. Varsayılan 1440 dakika, yani bir gün öncedir. Erteleme ve gecikmiş ilk plan için kontrollü catch-up vardır. Teslim kaydı aynı hatırlatmanın her açılışta tekrarlanmasını önler.
- iOS pending request sınırı için en yakın 60 bildirim planlanır; dört slot ayrılır. Daha fazla bekleyen hatırlatıcı, sonraki açılış/değişiklikte yeniden değerlendirilir. Uygulama hiç açılmazsa bu sınırın ötesindeki bütün kayıtların zamanında teslimi garanti edilmez.
- Tamamlanan/silinen kartların planları ve artık geçersiz teslim edilmiş bildirimleri kaldırılır. Kaydetme sonucu OS bildirim planlamasının süresini beklemez; planlama hatası bir kez ve sonraki foreground'da tekrar denenir.
- iOS'ta başka uygulamaların SMS/WhatsApp bildirimlerini okuma taklit edilmez. Manuel hatırlatıcı ve açıkça yapıştırılan metinden, kullanıcı tarih seçip onaylayınca etkinleşen yerel REVIEW taslağı vardır. Bu bir iOS NotificationListener veya otomatik doğal dil parser'ı olarak tanıtılmaz.
- Türkçe/İngilizce iOS açıklamaları ve kalıcı tek kart silme onayı eklendi. Android yakalama/parser davranışı değiştirilmedi.

iOS Focus, Scheduled Summary, sessiz mod ve kullanıcının bildirim tercihleri sunumu etkileyebilir; native zamanlama kodu bunları aşmaz.

## 3. Reklam düzeni ve güvenlik

| Kural | Önce | Şimdi |
|---|---|---|
| Anlamlı başarılı işlem | En az 2 | En az 2 |
| İlk uygun işlemden/son gösterimden bekleme | En az 90 saniye | En az 90 saniye |
| Günlük interstitial tavanı | 2 | 6 |
| Açılış/düzenleme/onboarding/paylaşım/izin veya gizlilik penceresi | Dağınık kontroller | Merkezi route, lifecycle ve modal kontrolü |
| Hazır olmayan reklam | İşlem devam eder | İşlem devam eder; kontrollü preload/retry |

Altı gösterim bir hedef veya zorunlu kota değildir. İki işlem ve 90 saniye, reklamın tamamen hazır olması ve güvenli doğal geçiş şartları birlikte uygulanır. Günlük tavan `AppConfig.dailyInterstitialCap` üzerinden geri alınabilir. Gerçek gelir/retention verisi bulunmadığından gelir artışı garanti edilmez; sonraki 7 günlük platform/sürüm bazlı veriye göre değerlendirilmelidir.

Geçiş reklamı yalnız başarılı yeni kayıt veya onay/tamamlama sonrası değerlendirilir. Formun kapanmış olması artık hedef ana akıştaki gösterimi yanlışlıkla engellemez. Açık Flutter diyalogları ayrı izlenir. Bildirim/paylaşım session suppression ana akışa dönüşte geçici olarak kaldırılır. Pro, arka plan, kritik route, consent, günlük tavan, cooldown ve hazır reklam kontrolleri korunur.

SDK ve consent başlangıcında çakışma koruması, interstitial callback için 30 saniye watchdog, geç cevapların dispose edilmesi, 30–480 saniye backoff, başarısız gösterimde ve kapanışta dispose/preload vardır. Kullanıcının consent formunu okuması bir ağ timeout'u sayılmaz; ikinci consent formu açılmaz.

Banner ana sayfada alt navigasyonun üstünde adaptive boyut kullanır. Safe-area/orientation genişliği değişince yeniden değerlendirilir. Başarısız, eski veya arka planda gelen yükleme sonucu görünmez; boş alan bırakılmaz. Request/timeout hataları native kaynakları serbest bırakır; frame başına yeniden istek gönderilmez.

SDK'ya yalnız yapılandırılmış reklam birimi ve boş `AdRequest` gider; kart, mesaj, kişi adı veya not gönderilmez. Tanılama logları yalnız debug içindir: load, ready, blocked reason, show, impression, failure, dismiss ve reload. Release'te özel içerik loglaması eklenmedi.

[Google interstitial rehberi](https://developers.google.com/admob/flutter/interstitial), doğal geçişlerde gösterim, test kimlikleri ve tek kullanımlık reklamların callback'lerde dispose edilmesi için temel alınmıştır. Sayısal 6/90/2 kuralı Google tarafından onaylanmış bir kota değildir; uygulamaya ait muhafazakâr üst sınırdır.

## 4. Android/iOS AdMob ve gizlilik denetimi

| Platform | Production App ID | Banner | Interstitial |
|---|---|---|---|
| Android | `ca-app-pub-4879558726064660~9522054765` | `ca-app-pub-4879558726064660/6443253838` | `ca-app-pub-4879558726064660/3326135902` |
| iOS | `ca-app-pub-4879558726064660~8062049694` | `ca-app-pub-4879558726064660/1712353053` | `ca-app-pub-4879558726064660/1444670455` |

iOS Release/Debug xcconfig, production kimlikleri, validation script'i, signing ve Info.plist değiştirilmedi. Debug her platformun kendi resmi Google test kimliklerini kullanır. Release'te eksik/test iOS yapılandırması validation hatasıdır; Android fallback yoktur.

Info.plist `GADApplicationIdentifier` değerini `$(ADMOB_IOS_APP_ID)` üzerinden alır. Mevcut 50 SKAdNetwork kaydı [Google'ın güncel iOS kurulum listesindeki](https://developers.google.com/admob/ios/quick-start) 50 kayıtla birebir karşılaştırıldı; eksik veya fazla kayıt yok (`.qa/skadnetwork-audit.json`).

UMP consent bilgisi her süreçte güncellenir; SDK'nın `canRequestAds` sonucu izin vermeden banner/interstitial isteği açılmaz. Güncelleme hatasında güvenli retry ve SDK'nın geçerli consent durumu kullanılır. `canRequestAds=false` senaryosunda iki reklam türünün de engellendiği otomatik test edildi. Bu, bütün consent reddi durumlarında SDK'nın sınırlı reklamlara izin veremeyeceği anlamına gelmez.

ATT popup eklenmedi; uygulama IDFA erişimi istemiyor. SKAdNetwork IDFA olmadan kullanılabilir. App Store gizlilik beyanı ve AdMob privacy message ayarları panelde ayrıca doğrulanmalıdır. [Google iOS gizlilik stratejileri](https://developers.google.com/admob/ios/privacy/strategies).

Yeni native bildirim teslim kayıtları uygulamanın kendi UserDefaults alanını kullandığından `PrivacyInfo.xcprivacy` içine `NSPrivacyAccessedAPICategoryUserDefaults / CA92.1` gerekçesi eklendi ve Runner Resources'a bağlandı. Bu dosya reklam SDK'sının veri toplamadığını iddia etmez; SDK manifestleri ve App Store gizlilik beyanı ayrıca değerlendirilir. [Apple required-reason API rehberi](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest).

Public [app-ads.txt](https://unutma-app-dhk.web.app/app-ads.txt) HTTP 200 döndü ve `pub-4879558726064660` için beklenen DIRECT satırı bulundu. Bu, AdMob panelinde tarama/onay tamamlandı anlamına gelmez.

## 5. Açılış ve ikon

Mevcut `assets/brand/unutma_app_icon_1024.png` kullanıldı; yeni logo çizilmedi. iOS AppIcon katalogundaki 15 boyut gerçek ikonla, opak RGB PNG olarak değiştirildi. Native launch screen ve Android launch drawable'ları aynı gerçek logo/açık-koyu palet ile eşleştirildi.

Flutter açılışı yerleşik AnimationController ile 1,8 saniye: logo opacity/scale, yerleşme, UNUTMA yazısı ve ana ekrana fade. Reduced motion seçeneğinde animasyon beklenmez. Ağ veya reklam hazır değilse bile animasyon biter; bounded loading/hata arayüzü görünür. Fiziksel cihazda 60 FPS profili alınmadı.

`.qa/startup-light.gif` ve `.qa/startup-dark.gif`, gerçek uygulama widget'ının Flutter test engine'inde oluşturduğu 393×873 karelerden üretilmiştir. Mockup veya iPhone kaydı değildir; fixture veri ve reklam yerine test servisi kullanır.

## 6. Doğrulama

| Kontrol | Sonuç |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test pigeons tools` | 40 dosya, değişiklik yok |
| `flutter analyze` | Temiz |
| `flutter test --concurrency=1 --reporter expanded` | **97/97 başarılı**; `.qa/final-prepush-tests.log` |
| Windows strict golden | **15/15 başarılı**, tolerans/skip/update yok |
| macOS golden | 15 mevcut onaylı PNG korunuyor; macOS'ta yeniden çalıştırılmadı |
| Android native unit | **44/44 başarılı**, 0 failure/error/skip; `.qa/final-prepush-android-tests.log` ve JUnit XML'leri |
| Android production release | **İmzalı 1.0.13+15 AAB**; final metadata `.qa/android-artifact-audit.json` |
| iOS native XCTest | CRUD/restart/revision/delete, prefs, bozuk dosya, offset/snooze için 4 test hazır; çalıştırılmadı |
| iOS simulator / gerçek iPhone | Windows'ta Xcode yok; çalıştırılmadı |
| Android canlı reklam / gerçek cihaz | Fiziksel cihaz bağlı değil; emülatör disk alanı nedeniyle başlayamadı |

Yeni Dart testleri gerçek SDK codec/callback dispatcher'ını mock native channel ile çalıştırır. Android ve iOS load/show/dismiss/reload, no-fill, timeout, stale callback, banner genişliği/background dispose, consent, geçici suppression, eski/yeni frequency gate, form kapandıktan sonra reklam değerlendirmesi ve açık diyalog engeli doğrulandı. Pigeon Dart codec roundtrip ve 16 Swift metodun kaynak/Runner bağlantı kontrolü de vardır. **Bunlar Swift derlemesi veya gerçek reklam ağı gösteriminin yerine geçmez.**

Bir ara test turu disk dolmasıyla durdu. Yalnız bu çalışmada üretilen iki debug APK kopyası silinerek yer açıldı. Modal observer ile ilgili geliştirme sırasında yakalanan provider yaşam döngüsü hatası post-frame güncelleme ile düzeltildi. Önceki başarısız loglar `.qa/` altında tutulur; yukarıdaki sayı son temiz tam koşuya aittir. Test silinmedi veya devre dışı bırakılmadı.

## 7. Release durumu ve kalan işlemler

Kullanıcı Play Console'da üretim sürümünün `1.0.12`, tüm yüklenmiş paketler içindeki en yüksek Android versionCode'un `14` ve son yayının 8 Ekim 2026 olduğunu doğruladı. **Android hedefi `1.0.13+15`** olarak pubspec.yaml'a işlendi; 15 > 14. Önceki 14 numaralı kontrol AAB'si artık yüklenmemelidir. Bu mağaza bilgisi kullanıcının panel doğrulamasından gelir; tarayıcı otomasyonu URL'yi güvenli biçimde doğrulayamadığı için canlı panel kontrolü tarafımızdan yapılmış gibi sunulmaz.

Android production dosyası `C:/Users/pc/Desktop/UNUTMA-1.0.13-15-release.aab`. Son build'in package/version/production kimlikleri/imza/boyut/hash doğrulaması `.qa/android-artifact-audit.json` dosyasındadır. Mevcut upload keystore yalnız local properties'ten process environment'a alınarak kullanıldı; parola veya özel anahtar kaynaklara/loglara eklenmedi. Beklenen upload sertifikası: `89:62:32:7E:C2:C9:B3:A3:76:68:4E:9C:50:82:D1:D0:FD:2C:C6:A7:D9:04:7A:FC:B7:8A:BB:43:BA:5A:B5:37`.

Yeni IPA Windows'ta oluşturulmadı. **iOS hedefi `1.0.12+14`**; kullanıcı tarafından belirtilen son App Store Connect build'i 13'ten yüksektir. `ios-app-store` / `UNUTMA iOS App Store` workflow'u, `IOS_VERSION_NAME=1.0.12` ve `IOS_BUILD_NUMBER=14` değerlerini açık `--build-name` / `--build-number` argümanlarıyla kullanır. Android pubspec sürümünden bağımsızdır. Flutter 3.47.0, `Codemagic` signing entegrasyonu ve app_store profil türü korunur. **Son kullanıcı talimatı gereğince publishing bölümü kaldırıldı; bu workflow yalnız imzalı IPA artifact'ı üretir, App Store Connect'e otomatik yüklemez.** Otomatik triggering tanımlanmadı ve build başlatılmadı.

iOS projesi CocoaPods yerine Swift Package Manager kullanır. google_mobile_ads 9.1.0, shared_preferences_foundation 2.5.7 ve webview_flutter_wkwebview 3.27.0 için Package.swift tanımları mevcut; Runner paket bağımlılığı, Flutter prepare scheme pre-action'ı ve tüm yeni Swift kaynaklarının Sources kayıtları doğrulandı. Podfile yokluğu bu yapıda eksik bağımlılık değildir. Swift language mode 5.0 ve iOS deployment target 15.0 değiştirilmedi; paket manifestleri için gerekli Swift 5.9+ derleyici Codemagic'in Xcode ortamınca sağlanır. Windows'ta Swift/Xcode derlemesi yapılmadı. [Flutter Swift Package Manager rehberi](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers).

`tools/test-ios-simulator.sh` macOS'ta debug/test kimlikleriyle derleme, dört RunnerTests testi, simulator açılış görüntüsü ve native log üretimi için hazırdır; signing veya upload yapmaz. Codemagic workflow'una otomatik eklenmedi. Native doğrulama için macOS/Xcode erişimi ve sonrasında gerçek iPhone testi gerekir.

Final sürüm kontrolünde Ayarlar ekranındaki eski `1.0.5 (7)` sabiti kaldırıldı. `app.unutma/app-info` native kanalı Android'de BuildConfig, iOS'ta gerçek CFBundle sürümünü döndürür; metadata çağrısı iki saniye ile sınırlıdır ve hata halinde yanlış sürüm uydurulmaz. Görsel test fixture'ındaki eski örnek değer sabit tutuldu; baseline PNG'leri değişmedi. Android/iOS metadata ve timeout davranışı için iki test, ayrı iOS workflow sürümü ve otomatik yayın olmaması için iki test eklendi. Önceki 93 test korunarak toplam 97'ye çıktı.

Mağaza sürüm adımları için kullanıcı tarafından doğrulanan Android 14 ve iOS 13 üstüne sırasıyla 15 ve 14 seçildi. Bu arada başka paket yüklenirse tekrar kontrol edilmeli. Kalan doğrulama: macOS'ta Swift/Xcode ve strict golden sonuçlarını gör; iPhone'da ilk/ikinci açılış, çevrimdışı CRUD/restart, izin reddi/izin verme, arka plan ve bir günlük bildirim teslimini doğrula. Üretilen IPA'nın bundle/version/imza/reklam kimliklerini ayrıca kontrol et. Hiçbir mağaza yüklemesi veya production yayını bu çalışmanın parçası değildir.

AdMob panelinde uygulama onayı, reklam sunum kısıtlamaları/Policy Center, app-ads.txt crawler sonucu ve UMP mesajlarının yayın durumu kontrol edilmeli. Aynı zaman aralığı ve platform/sürüm/ad-unit kırılımında requests, matched requests, impressions, show rate (impressions/matched requests), match rate, eCPM ve tahmini gelir karşılaştırılmalı. Load/ready olup show yoksa debug blocked-reason; show olup impression yoksa SDK callback/cihaz ve panel gecikmesi incelenmeli. Doluluk veya gelir panel verisi alınmadan başarılı sayılmaz.

## 8. Değişen dosyalar

Tam dosya listesi aşağıya çalışma ağacından eklenir. Başlangıçtaki 69 dosyaya son sürüm/CI doğrulaması ve gerçek Android sürüm bilgisi için üç dosya daha katıldı. Pubspec sürüm güncellemesi son kullanıcı talimatıyla yapıldı. `.qa/`, build çıktıları, AAB/IPA, keystore ve key.properties Git dosya listesine dahil değildir.

<!-- generated changed-file list -->

72 güvenli kaynak/config/test/asset dosyası.

- `C:/Users/pc/Desktop/projeler/UNUTMA/android/app/src/main/kotlin/app/unutma/unutma/MainActivity.kt`
- `C:/Users/pc/Desktop/projeler/UNUTMA/android/app/src/main/kotlin/app/unutma/unutma/bridge/UnutmaApi.g.kt`
- `C:/Users/pc/Desktop/projeler/UNUTMA/android/app/src/main/res/drawable-hdpi/launch_logo.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/android/app/src/main/res/drawable-mdpi/launch_logo.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/android/app/src/main/res/drawable-v21/launch_background.xml`
- `C:/Users/pc/Desktop/projeler/UNUTMA/android/app/src/main/res/drawable-xhdpi/launch_logo.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/android/app/src/main/res/drawable-xxhdpi/launch_logo.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/android/app/src/main/res/drawable-xxxhdpi/launch_logo.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/android/app/src/main/res/drawable/launch_background.xml`
- `C:/Users/pc/Desktop/projeler/UNUTMA/android/app/src/main/res/values-night/launch_colors.xml`
- `C:/Users/pc/Desktop/projeler/UNUTMA/android/app/src/main/res/values/launch_colors.xml`
- `C:/Users/pc/Desktop/projeler/UNUTMA/codemagic.yaml`
- `C:/Users/pc/Desktop/projeler/UNUTMA/docs/IOS_STARTUP_ADS_AUDIT_2026-10-12.md`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner.xcodeproj/project.pbxproj`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/AppDelegate.swift`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/Base.lproj/LaunchScreen.storyboard`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/IOSLocalStore.swift`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/IOSReminders.swift`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/NativeUnutmaApi.swift`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/PrivacyInfo.xcprivacy`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/Runner/UnutmaApi.g.swift`
- `C:/Users/pc/Desktop/projeler/UNUTMA/ios/RunnerTests/RunnerTests.swift`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/app.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/core/config/app_config.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/core/data/card_repository.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/core/data/providers.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/core/platform/platform_capabilities.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/core/platform/unutma_api.g.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/core/services/ad_providers.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/core/services/ad_service.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/core/widgets/adaptive_banner_ad.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/core/widgets/ios_reminder_entry.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/core/widgets/startup_gate.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/features/dashboard/dashboard_screen.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/features/inbox/inbox_screen.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/features/manual_card/detail_screen.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/features/onboarding/onboarding_screen.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/features/settings/settings_screen.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/features/share/share_import_screen.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/l10n/app_en.arb`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/l10n/app_localizations.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/l10n/app_localizations_en.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/l10n/app_localizations_tr.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/lib/l10n/app_tr.arb`
- `C:/Users/pc/Desktop/projeler/UNUTMA/pigeons/unutma_api.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/pubspec.yaml`
- `C:/Users/pc/Desktop/projeler/UNUTMA/test/ad_lifecycle_test.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/test/app_test.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/test/ios_ad_config_test.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/test/startup_and_bridge_test.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/test/visual_qa_test.dart`
- `C:/Users/pc/Desktop/projeler/UNUTMA/tools/test-ios-simulator.sh`

Final Android AAB: **62,135,998 bytes / 59.26 MiB**, SHA-256 `9677978F3F0913E47A75866A947B40B204181EB0C3EA5F9ED1CEE5AA9909F346`. Paket `app.unutma.mobile`, sürüm `1.0.13+15`, mevcut upload sertifikasıyla eşleşen imza doğrulandı. Kullanıcının doğruladığı Play maksimumu 14'ün üstündedir.
