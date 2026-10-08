# UNUTMA

A private Android utility: notification → understanding → Action Card → reminder.
Flutter presents the product; native Kotlin keeps the pipeline working without a
Flutter engine. The provided brand board was opened and reviewed before UI work.

## Product overview

TR/EN on-device rule parsing, review inbox, manual cards, local history, editable
reminder presets, source ignore, privacy controls, dark mode and four-step
onboarding. No account, cloud AI, OCR, direct SMS/email mailbox reading, calendar
scraping or location access.
Real notifications create real Room rows. Release contains no sample data.

## Architecture

`NotificationListenerService → eligibility → normalization → features/entities →
rule classification → confidence → dedupe → Room → WorkManager`

`Room → generated Pigeon → Flutter repository → Riverpod → GoRouter screens`

Room is the only persistent card store. Native ingestion and mutations are
serialized and transactional; revisions protect against stale notification
actions. Room observation refreshes foreground Flutter views. There is no
background Flutter isolate, engine, foreground service or polling loop.

See [architecture](docs/architecture.md) and
[acceptance matrix](docs/acceptance-matrix.md).

## Why native processing is required

Android can deliver notifications while the UI is absent. Listener, parser,
Keystore, repository, actions and reminders import no Flutter UI code. The bridge
is an adapter, not the execution environment of the notification pipeline.

## Flutter setup

Validated toolchain: Flutter 3.47.0 stable, Dart 3.13.0. Run from repository root:

```powershell
flutter pub get
flutter gen-l10n
dart run pigeon --input pigeons/unutma_api.dart
dart run build_runner build
```

Riverpod, GoRouter, Pigeon, Freezed and json_serializable versions are locked in
`pubspec.lock`. Generated source is checked in. Do not edit generated bridge or
model files manually. UI implementation is feature-first under `lib/features`.

## Android setup

Min SDK 26; compile/target SDK 36; JDK 21 supplied by Android Studio; Java/Kotlin
bytecode target 17. Flutter template currently uses AGP 9.1 / Gradle 9.3.1 with its
compatibility DSL flags. These upstream flags emit deprecation warnings but the
validated build works. KSP 2.3.11, Room 2.8.4, WorkManager 2.11.2.

On this Windows machine `java` on PATH is an unrelated Java 8 installation.
Use Android Studio JDK for direct Gradle commands:

```powershell
$env:JAVA_HOME = "$env:ProgramFiles\Android\Android Studio\jbr"
.\android\gradlew.bat -p android :app:testDebugUnitTest
```

## NotificationListenerService

User grants special Notification Access through the disclosed Android settings
flow. Listener filters own notifications, summaries, ongoing services, progress,
media and system status before parsing. Extras access is bounded and null-safe.
One malformed notification cannot terminate the supervisor scope. No raw input
or exception text is logged. Labels resolve locally without QUERY_ALL_PACKAGES.
Unknown/uninstalled source labels fall back in the selected UI language.
Messaging-style notifications are treated as personal content and always enter
review. A privacy-safe local suggestion asks `Add / Review / Ignore` without
showing the captured text. If the source app does not post a notification, the
listener cannot see its SMS or email content.

Android Sharesheet and selected-text `PROCESS_TEXT` integration provide the
permission-free fallback: Gmail, Messages, browsers and other apps can send a
plain-text selection to UNUTMA. The app previews it in memory and persists
nothing until the user chooses Analyze. Parsed results enter review; unmatched
text opens a prefilled manual-card form. No attachment, mailbox or file access is
requested.

## Parser architecture

The V4 Turkish language pipeline is pure Kotlin and independently testable:
`TurkishNormalizer`, `TurkishCharFold`, `NotificationTextComposer`,
`ConversationSummaryDetector`, `ReminderMarkerDetector`, `TurkishVerbLexicon`,
`VerbComplementExtractor`, `ObjectExtractor`, `TurkishTemporalExtractor`,
`ContextualTemporalExtractor`, `ObligationMarkerDetector`,
`MarketingSignalDetector`, `CompletedActionDetector`, `SecurityOtpDetector`,
`IntentClassifier`, `ConfidenceScorer`, and `TurkishIntentEngine`.

Messaging previews parse the latest message body while keeping the sender only
as metadata. Natural requests such as `Gelirken ekmek al`, `3'te beni ara`, and
`Cuma dosyayı gönder` create review candidates. Contextual time is displayed but
never converted to an invented clock time. A 341-fixture Turkish corpus covers
positive, negative, noisy, and ambiguous families. We prioritize precision;
marketing, completed action, OTP/security, and conversation summaries are
rejected. Uncertain, conflicting, past, invalid, missing, or ambiguous dates
require review.

Relative dates use notification `postedAt`, never the current UI time. Missing
years roll to the next plausible date. Numeric English dates use source device
locale (US month-first, UK day-first); unspecified English numeric ambiguity is
reviewed. DST gaps/overlaps require review. Date-only reminders default to 09:00
local time; the user can edit them. Parser version is stored; existing user data
is never silently reparsed. Business-day calculation excludes weekends, not
public holidays. Extracted date is an instant; changing time zone displays the
same instant in the current zone.

Categories: bill, payment, delivery, pickup, appointment, reservation, renewal,
return window, ticket/event, travel, deadline and manual other. Financial titles
are localized category labels unless a user edits them; notification body text
is not repurposed as an unencrypted title.

See the reviewed [parser pattern catalog](docs/parser-pattern-catalog.md) for
Turkish inflections, informal/ASCII spellings, date forms, negative signals,
confirmation behavior, and the SMS/email boundary.

## Play Store artwork

Production Turkish artwork is in `store_assets/tr-TR`. It includes the 512 icon,
1024×500 feature graphic, and four 1080×1920 screenshots composed from the real
Flutter golden screens. Regenerate it with `tools/generate_store_assets.py` and
validate it with `tools/validate_store_assets.py`. The generator has locale-based
copy/output configuration for a later English listing; English app goldens must
be supplied before exporting `en-US` artwork.

## Room database

`cards`, `sources`, `reminder_receipts`; V1 exported schema in `android/app/schemas`.
Indexes support statuses/dates/categories/sources/fingerprints. Dedupe uses both
hashed notification keys and normalized semantic hashes with a seven-day TTL.
Insertion is transactionally deduplicated. Native API validates edits, categories,
amounts, offsets and state transitions. No destructive-migration fallback.
`MigrationTestHelper` validates exported V1 schema on Android; future versions
must ship explicit migrations and retained historical schemas.

## Encryption

AES-256-GCM, random nonce, Keystore-only key, card-ID authenticated associated
data. Source messages are limited to 4096 characters. Encryption errors discard
the optional message rather than save plaintext. The message is decrypted only
when cards are read for the local Flutter UI. Normalized card fields are local,
plain Room fields (this is not a claim of full DB encryption). Source messages
remain encrypted while a card is open and are deleted when the card is completed,
archived, or the user explicitly deletes the message. Closed history retention is
90 days. No periodic polling runs solely for cleanup.

## Notification Access

Four-step onboarding explains value, transformation, local privacy and access.
Skip is supported. Access is OS-managed, separate from POST_NOTIFICATIONS. Manual
mode works with both denied. Revocation and notification-channel blocks are
refreshed on resume. The app cannot override system redaction or restrictions.

## Reminder system

WorkManager unique work per card/revision/slot; category defaults support multiple
reminders. Edit cancels old work then schedules new work. Done/archive cancel work
and visible reminders. Workers check current revision/status and delivery receipts;
a stale or repeated action cannot overwrite current card state. Snooze defaults
to one day. Reconciliation runs on UI resume/listener connect. There is no exact
alarm permission. Past times are skipped, not immediately spammed. Very late
work (over 24 hours) is suppressed. A denied posting permission/channel does not
crash or remove the card. Notification content is generic; actions use immutable,
explicit PendingIntents and an unexported receiver.

WorkManager is not exact-time; Doze, OEM battery rules, force-stop and permission
revocation can delay/suppress delivery. This is stated in the UI. Validate on
physical OEM devices before relying on it for critical dates.

## Privacy architecture

Notification parsing, cards, reminders and sensitive previews remain local and
never enter an advertising request. Android backup/cloud backup and device
transfer exclude private files. Delete local data cancels work/notifications,
clears DB/source data/preferences and the local ad-frequency counters, and deletes
the key. SQLite secure-delete, WAL truncation and vacuum reduce local remnants.
Onboarding completion and a deletion cutoff timestamp remain so queued old events
cannot resurrect erased cards. OS notification access remains user-controlled.

An ad-enabled release contains Google Mobile Ads/UMP and therefore uses network
and advertising-related permissions. Its SDK collection is disclosed separately
below and in `docs/play-store`; this does not change the local notification parser.

## Localization

Official ARB + gen-l10n for Turkish and English. Parser rules are independent from
UI strings. Settings selects system/TR/EN and system/light/dark appearance. Native
reminder copy follows the saved app language. TalkBack labels, scalable text,
48dp actions and quiet default transitions are used. No custom bouncing animation.

## AdMob configuration

`google_mobile_ads` 9.1.0 provides Mobile Ads 25.4.0 and UMP 4.0.0 on Android.
Anchored adaptive banner and interstitial ads are implemented. Production IDs
are never hard-coded:
`UNUTMA_ADS_ENABLED=true`, `UNUTMA_ADMOB_APP_ID`, and
`UNUTMA_ADMOB_INTERSTITIAL_ID` and `UNUTMA_ADMOB_BANNER_ID` are read by Gradle.
An enabled release fails before compilation if an ID is absent, malformed, or
uses Google's sample publisher. Without valid configuration the adapter fails
closed and displays nothing.

Set `UNUTMA_DEBUG_ADS=true` to build with Google's Android sample app, adaptive
banner, and interstitial IDs. Debug ads are disabled by default so test users can
exercise the core product without advertising. Google test IDs cannot enter an
ad-enabled release variant.

The adaptive banner appears only above the home screen's bottom navigation and
occupies no space until loaded. Interstitial eligibility is persisted: at least
three successful reminder creates/approvals/completions, three minutes since the
first eligible action or previous display, and two displays per local day. The
completed operation and UI update happen before an ad attempt. Reminder-opened
sessions, onboarding, permission flows, detail/privacy screens, editing, data
deletion and paywall transitions never show an ad. Pro entitlement is an explicit
fail-closed bypass point.

## Ad consent

UMP requests updated consent information at each foreground application launch
after onboarding, loads the applicable form when required, and gates every ad
request with `canRequestAds()`. Settings and Privacy expose Google's privacy
options entry point whenever UMP marks it required. The publisher must publish
the applicable European-regulations and US-states messages in AdMob; code alone
cannot create account-side consent messages.

The Google Mobile Ads automatic initialization provider is removed. The SDK is
initialized manually only after onboarding, while Flutter UI is foregrounded,
and after the UMP gate. Waking the native notification listener does not start
the advertising SDK. No notification/card/source value is passed to UMP or Ads.

## Billing configuration

`DisabledBillingService` reports unavailable, not purchased/restored. Paywall
explains unavailability and offers no invented price/benefit. There are no products,
purchase tokens or entitlements. Enabling commerce requires a real Play Billing
adapter, configured products, pending/cancelled/restored flows, acknowledgement,
entitlement verification and license-tester validation. Current core is free.

## Analytics safety

`NoOpAnalytics` takes an enum-only event API and emits nothing. No raw-value maps,
merchant, amount, preview, package name or user text are sent. Generated DTO
`toString` must never be logged. There is no remote crash collector.

## Build configuration

Production application ID: `app.unutma.mobile`. It is fixed in Gradle so a
release cannot accidentally be built under another Play package. It becomes
permanent with the first Play upload. Code namespace remains independent. Version is in
`pubspec.yaml`; displayed version is centralized in `AppConfig` and must be
updated together.

## Debug build

```powershell
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`. Debug tooling requires INTERNET;
the Mobile Ads/UMP dependency also contributes INTERNET and advertising-related
permissions to release manifests even when runtime ads fail closed. All
screenshot/parser fixtures live under test directories and are not production
data. Install debug artifacts only on a test emulator/device.

## Release build

```powershell
flutter build appbundle --release
```

Without signing variables, this produces an **unsigned** bundle for structural
validation. Never use the debug key for production. For an ad-enabled, signed,
validated Play artifact run `tools/build-play.ps1`; it refuses missing signing or
AdMob configuration. Configure values in a local secure environment/CI secret
store:

- UNUTMA_KEYSTORE: absolute keystore path
- UNUTMA_STORE_PASSWORD
- UNUTMA_KEY_ALIAS
- UNUTMA_KEY_PASSWORD
- UNUTMA_ADS_ENABLED=true
- UNUTMA_ADMOB_APP_ID
- UNUTMA_ADMOB_INTERSTITIAL_ID
- UNUTMA_ADMOB_BANNER_ID

Do not put secrets in source control or command arguments. This task never
creates a publisher key or claims Play Console ownership of the application ID.

## Testing

```powershell
.\tools\validate.ps1
# With an available isolated Android emulator:
.\android\gradlew.bat -p android :app:assembleDebug :app:assembleDebugAndroidTest
.\tools\device-test.ps1 -Serial emulator-5554
# Regenerate reviewed visual baselines only after intentional UI changes:
flutter test test/visual_qa_test.dart --update-goldens
```

Run Flutter builds/tests serially in this checkout: Flutter's shared native-assets
output is not concurrency-safe. Tests include TR/EN positive/negative/ambiguous
fixtures per category, malformed dates, leap/year boundaries, DST, time zones,
relative dates, key/semantic dedupe/TTL and reminder calculation. Native device
tests exercise Room, migration schema, GCM roundtrip/tampering, real repository
state transitions and reminder notifications. Flutter tests cover repositories,
controllers, onboarding, dashboard, Inbox, delete confirmation and recoverable errors.

The layout matrix covers 360×800, 393×873, 412×915, 1.0/1.3 text scale, TR/EN,
light/dark. Eleven golden captures live in `test/goldens`; fonts come from the
Flutter SDK only during tests. Fixture data never enters release routes or DB.
See [validation report](docs/validation.md) for actual results, not inferred PASS.

## Assets

Source board: `ChatGPT Image 30 Ağu 2026 23_45_40.png`, 1536×1024. The standalone
main icon was visually identified and extracted; no UI screenshot is the launcher.
`tools/derive_assets.py` preserves the original, exports canonical mark/icon and
legacy/adaptive/round/monochrome resources, with SHA-256 audit. No desktop asset
folder existed. Category icons use consistent outlined Material symbols. Onboarding
uses responsive Flutter compositions rather than cropped board text or UI imagery;
canonical exports are reproducible with `tools/render_assets_test.dart`.

## Play Store notes

See `docs/play-store/notification-access-disclosure.md`,
`docs/play-store/data-safety-notes.md`, `docs/play-store/permission-inventory.md`,
`docs/play-store/advertising-disclosure.md`, `docs/play-store/privacy-policy.md`,
`docs/play-store/store-listing.md`, and `docs/play-store/release-checklist.md`.
These describe current behavior, not legal advice or a guarantee of Play
approval. Target SDK reference:
https://developer.android.com/google/play/requirements/target-sdk

## Data Safety notes

Notification/card content is processed locally only. Google Mobile Ads itself can
automatically collect/share IP address, product interactions, diagnostics and
device/account identifiers for advertising, analytics and fraud prevention.
Declare the actual final distributed build and developer practices in Play
Console. Ads must be marked Yes. A public developer-owned privacy policy, contact
details, account-side UMP messages and final store copy must be supplied before
publication.

## Known limitations

- Deterministic TR/EN rules are conservative and cannot understand every merchant.
- Public holidays are not part of business-day arithmetic.
- Date-only items use 09:00; numeric locale and conflicting dates may need review.
- WorkManager timing is approximate. OEM/force-stop restrictions cannot be bypassed.
- No cloud backup/export, account system, remote analytics or purchases.
- Ad delivery and consent-message availability depend on correctly configured
  AdMob/UMP accounts, network access, region, inventory and Google Play services.
- Physical OEM/Doze soak testing is separate from emulator and unit validation.
- Canonical onboarding PNG exports are included for store/design use; runtime scenes
  remain responsive widgets. Category marks use native outlined symbols.

## Release checklist

- [ ] Own and finalize application ID, publisher identity and contact.
- [ ] Configure release signing and verify bundle signatures.
- [ ] Create AdMob app/unit, publish UMP messages and configure production IDs.
- [ ] Publish real privacy-policy URL; declare Contains ads and accurate Data Safety.
- [ ] Run prolonged physical-device background/Doze/permission-revocation tests.
- [ ] Review screenshots and store listing in both languages.
- [ ] Validate UMP and live configuration using registered test devices; never click live ads.
- [ ] Re-run the validation script and archive reports for the release commit.
