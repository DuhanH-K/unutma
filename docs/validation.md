# Validation report

Final local validation was run on 3 September 2026 with Flutter 3.47.0 stable,
Dart 3.13.0, Android compile/target API 36, and Android Studio JDK 21.

| Check | Result | Evidence |
|---|---|---|
| `flutter pub get` | PASS | Dependency resolution completed from the lockfile. |
| `dart format .` | PASS | 34 source files checked; 0 changed on the final pass. |
| `flutter analyze` | PASS | No issues found. |
| `flutter test` | PASS | 65 tests, including AdMob failure handling, 15 deterministic goldens, and the TR/EN, light/dark, width/text-scale matrix. |
| Android native unit tests | PASS | 39 tests; parser/date/dedupe/filter/reminder suites, exact WhatsApp regression, messaging-package detection, and the 341-fixture Turkish quality gate passed. |
| Debug APK with Google test ads | PASS | `201080005` bytes; SHA-256 `753FDAFC68277AC7C52775873A4BC56272FC9DA9500BBFAFB65F2BC4B14386CB`; sample app, interstitial, and adaptive-banner IDs were transferred into the debug variant. |
| Physical-device update | PASS | Debug APK installed with `adb install -r --no-streaming`, launched, retained app data, and notification access remains enabled. |
| Release APK | PASS | `61069926` bytes; SHA-256 `613F0DC873EE7A70687F814D1375BE9C3EA2A13E4FE0DE4BEE6185FBCF0D7E74`. |
| 16 KB APK alignment | PASS | Build-tools 36 `zipalign -c -P 16 4` verification successful. |
| Signed production release AAB | PASS | `release/UNUTMA-1.0.0+2-PRODUCTION-PLAY.aab`; version code `2`; fixed package `app.unutma.mobile`; `61738856` bytes; SHA-256 `FF07FDBF0E493C58033E408FC4E21819F4EA41060727CF51351BE7275CE81E7D`. |
| Release signing | PASS | `jarsigner` reports `jar verified`; the bundle contains its upload-key signature entry. |
| Play Store artwork | PASS | 512 icon, 1024×500 feature graphic, and four 1080×1920 RGB screenshots validated. |

The release manifest resolves to `app.unutma.mobile`, `targetSdk=36`,
`allowBackup=false`, `usesCleartextTraffic=false`, and a non-debuggable release.
It requests only reminder, boot, network/ads SDK, wake-lock, and AndroidX internal
receiver permissions. The listener service is protected by
`BIND_NOTIFICATION_LISTENER_SERVICE`; this is a system binding permission, not a
dangerous `uses-permission` granted to the app.

The final release artifact has production advertising enabled through build-time
environment values. Its merged manifest contains the production AdMob App ID;
the banner and interstitial units are present in the release BuildConfig and
bundle, and Google's three Android sample IDs are absent. The values remain
outside source control. `tools/build-play.ps1` requires App, interstitial,
banner, and signing values, rejects malformed/sample IDs, and verifies the
resulting signature.
