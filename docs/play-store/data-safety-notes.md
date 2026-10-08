# Data Safety implementation notes

The ad-enabled production build has no cloud parser, account, billing SDK, or
remote analytics/crash reporter. It does contain Google Mobile Ads 25.4.0 and
UMP 4.0.0 through `google_mobile_ads` 9.1.0, so its merged release manifest
includes INTERNET and advertising-related permissions. Play disclosures must
describe the final ad-enabled artifact rather than the older offline build.

On-device normalized card data: category, user title/note, due time, amount and
currency when available, source label/package, state, timestamps, parser version
and reminder settings. Notification text is not stored in these fields.
Notification-derived titles are localized category labels; raw titles are not
copied to the UI model. SHA-256 fingerprints support duplicate detection.

An optional source preview is limited to 240 characters, AES-256-GCM encrypted
with a randomly generated IV and a non-exportable Android Keystore key. Card ID
is authenticated as associated data. Previews never cross Pigeon. Encryption
failure discards the optional preview, never writes plaintext. Previews are
cleared on completion/archive and on local maintenance after seven days.
Closed card history is retained for 90 days; active user cards are not expired
or deleted merely because their due date has passed.

Automatic backup and device transfer of private app data are disabled. Delete
all data cancels scheduled work and posted reminders, deletes rows and source
preferences, enables SQLite secure_delete, checkpoints/truncates WAL, vacuums
the DB, and deletes the Keystore key. Onboarding-completed state and a deletion
cutoff timestamp are retained to prevent queued old notifications resurrecting
deleted data. Language/theme/reminder preferences reset. Android notification
access itself remains a user-managed OS setting.

Reminder notifications use generic text, never title/merchant/amount/preview.
User-visible titles and other sensitive values are not sent to logs. Generated
DTO toString methods must never be logged.

The advertising adapter sends an empty ad request: it does not add notification
text, normalized card fields, title, amount, note, source label/package, parser
signals, reminder values, keywords, content URLs, neighboring content URLs, or
custom targeting. The automatic Mobile Ads initialization provider is removed;
SDK initialization occurs only in the foreground UI after onboarding and UMP.

Google's Mobile Ads SDK disclosure states that the SDK automatically collects
and shares the following data for advertising, analytics, and fraud prevention:

| Play data area | SDK behavior to declare |
|---|---|
| Approximate location | IP address may estimate general location |
| App activity | Product interactions such as app launch, taps, and video views |
| App info and performance | Diagnostics including launch time, hang rate, and energy use |
| Device or other IDs | Advertising ID, app set ID, and applicable device/account identifiers |

Google states that these SDK transfers use TLS. The publisher remains
responsible for the exact answers to collected/shared, required/optional, and
purposes in Play Console, including the final UMP and AdMob account settings.
Deleting UNUTMA's local data does not delete data already processed by Google;
the public policy must link Google's privacy controls.

Play Console Ads must be **Yes**. Do not blindly copy a Data Safety answer from
this file. Re-evaluate after every SDK, mediation, billing, or telemetry change.
The Play form must describe the final distributed build, publisher practices,
target audience, and account-side ad configuration.
