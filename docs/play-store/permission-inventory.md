# Permission inventory

The final merged release manifest is authoritative. Run
`tools/validate.ps1` and inspect `build/app/intermediates/merged_manifests`.

| Permission | Purpose | Runtime | Disclosure | Sensitivity |
|---|---|---|---|---|
| INTERNET | UMP consent messages and Google Mobile Ads requests in ad-enabled builds | No | Privacy policy and Contains ads declaration | No notification/card value is added to requests |
| POST_NOTIFICATIONS | Post the user's reminders on Android 13+ | Yes | Settings → Reminder notifications | User can refuse; no core feature lock |
| WAKE_LOCK | WorkManager's bounded background execution | No | Reminder timing documentation | No persistent foreground service |
| RECEIVE_BOOT_COMPLETED | WorkManager reschedules persisted work | No | Reminder reliability notes | OS-managed scheduling only |
| ACCESS_NETWORK_STATE | WorkManager constraints and ads SDK connectivity | No | Advertising/privacy disclosure | No notification/card content transmitted |
| com.google.android.gms.permission.AD_ID | Google Mobile Ads advertising identifier on supported Android versions | No | Advertising/privacy and Data safety | Subject to Android user controls and Google Ads policy |
| ACCESS_ADSERVICES_AD_ID | Android Privacy Sandbox advertising identifier access used by the ads SDK | No | Advertising/privacy and Data safety | SDK-contributed normal permission |
| ACCESS_ADSERVICES_ATTRIBUTION | Android Privacy Sandbox ad attribution used by the ads SDK | No | Advertising/privacy and Data safety | SDK-contributed normal permission |
| ACCESS_ADSERVICES_TOPICS | Android Privacy Sandbox Topics support used by the ads SDK | No | Advertising/privacy and Data safety | SDK-contributed normal permission; review account/target-audience policy |
| app.unutma.mobile.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION | AndroidX signature-protected internal receiver | No | Not a user data permission | Signature only; follows application ID |

`BIND_NOTIFICATION_LISTENER_SERVICE` is a permission **required of callers of the
exported listener service**, not a uses-permission granted to the app. Only the
system binds after the user enables special Notification Access. Launcher
activity is exported for launch; it exposes no data-returning interface. The
Done/Snooze receiver is unexported; PendingIntents are explicit and immutable.
WorkManager's own merged components keep AndroidX permissions intact.

Any unused foreground-service permission/component contributed by WorkManager
is removed by manifest merge directives. No exact alarm, location, contacts,
calendar, SMS, call-log, accessibility, camera, or microphone permission is
requested. The Mobile Ads auto-init provider is also removed so a background
notification-listener wake does not initialize advertising.
