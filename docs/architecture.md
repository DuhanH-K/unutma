# Architecture decision record

The repository initially contained only an empty Git repository. No pubspec,
manifest, existing package ID, Gradle setup or baseline application existed.
Flutter 3.47.0 / Dart 3.13.0 and Android SDK 36 are installed. Flutter selects
Android Studio JDK 21 (the unrelated system Java 8 is not used).

The full user specification is the acceptance contract. Precedence: V3 visual
contract, privacy, native reliability, precision, reminders, integrity, UI,
localization, monetization. The 1536x1024 reference board was opened and reviewed.

Native Kotlin owns notification eligibility, deterministic TR/EN parsing, Room,
Keystore encryption and WorkManager reminders. There is no background Flutter
engine. Flutter owns presentation, navigation and typed repository calls via
generated Pigeon. Native Room is the only database. Coroutines perform IO off
the main thread. Typed immutable Flutter models and Riverpod expose state.

No notification/card/source content crosses the network. The optional AdMob/UMP
adapter is isolated from the native parser, starts manually only in foreground UI
after consent, sends an empty ad request, and fails closed without release IDs.
Its auto-init provider is removed so notification-listener wakeups cannot start
advertising. Persisted action/time/day caps permit interstitials only at the
History session break. Billing and analytics remain honest disabled/no-op paths;
no synthetic entitlement or purchase-success path is provided.

Launcher art is deterministically extracted from the standalone main icon in
the supplied board, preserving the mark. Category icons use consistent Material
outlined symbols. Onboarding illustrations are real responsive Flutter widgets,
so no screenshots or misleading text from the board are embedded in the UI. Two
canonical PNG compositions are exported reproducibly for design/store workflows.

Target API 36 follows the Android target SDK requirement:
https://developer.android.com/google/play/requirements/target-sdk
