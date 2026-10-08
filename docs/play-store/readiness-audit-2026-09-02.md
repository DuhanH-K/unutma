# Google Play readiness audit — 2 September 2026

## Verdict

**Code, local runtime, and Turkish listing artwork are ready. The Play upload is
blocked only by publisher-owned configuration.** The structural release AAB is
intentionally unsigned and ads-disabled; it must not be uploaded as-is.

## Verified locally

- Flutter 3.47.0 / Dart 3.13.0; Android Studio JDK 21.
- Application ID `app.unutma.mobile`, version `1.0.0` (`versionCode` 1), min SDK
  26, target SDK 36.
- `flutter pub get`, formatting, `flutter analyze`, 63 Flutter tests, 39 Android
  native unit tests, debug APK, release APK, and structural release AAB pass.
- The native Turkish intent engine is covered by 341 fixtures, including
  conversational actions, noisy/ASCII Turkish, contextual time, marketing,
  completion, OTP/security, and conversation-summary negatives.
- The current debug build was installed and launched on the connected Xiaomi
  device. Existing app data was preserved and Android still lists the UNUTMA
  notification listener as enabled.
- Release APK passes `zipalign -c -P 16 4`.
- Merged release permissions contain no SMS, contacts, call-log, calendar,
  location, accessibility, exact-alarm, or foreground-service permission.
- All six required Turkish store assets pass size, color-mode, alpha, and aspect
  checks in `tools/validate_store_assets.py`.
- Public privacy policy URL: `https://unutma-app-dhk.web.app/gizlilik`.

## Publisher-owned items before upload

1. Confirm `app.unutma.mobile` is reserved in the intended Play Console account.
   If version code 1 was already uploaded, increment `pubspec.yaml`.
2. Create and securely back up an upload keystore, enable Play App Signing, and
   provide all four signing environment variables. The specification explicitly
   forbids inventing signing secrets.
3. Create the production AdMob Android app and interstitial unit for the final
   application ID, publish applicable UMP consent messages, and provide both IDs.
4. Complete Play Console App content: privacy URL, Contains ads, Data safety,
   target audience, content rating, and notification-access reviewer notes.
5. Complete any closed-test requirement that applies to the developer account.

Run `tools/build-play.ps1` after those values are securely configured. It refuses
missing values, rejects malformed AdMob IDs, builds the AAB, and verifies the
signature before reporting success.
