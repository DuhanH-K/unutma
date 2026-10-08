# Advertising implementation and Play declaration

The ad-enabled production build contains the Google Mobile Ads Flutter plugin
and UMP consent SDK. Play Console **Ads** must be declared **Yes — contains ads**.
Only interstitial ads are implemented; there are no banners, rewarded ads, app
open ads, or native ads.

Ads are requested only after onboarding, while the Flutter UI is in the
foreground, and only after UMP reports that ads may be requested. The SDK's
automatic initialization provider is removed from the merged Android manifest.
This prevents the ads SDK from starting when Android wakes only UNUTMA's native
notification listener.

An interstitial may be shown only when the user deliberately moves to History,
which is a natural session break. The persisted policy requires at least four
eligible navigation actions, at least five minutes since the first eligible
action or previous ad, and no more than two interstitials per local day. A Pro
entitlement disables ads. A session opened from a reminder is entirely
suppressed. Ads are never shown during onboarding, notification access,
reminder/card opening, card editing, payment/appointment actions, local data
deletion, or a paywall transition.

No notification text, card title, amount, note, source label, source package,
parser result, or reminder value is placed in an ad request. Ad requests use an
empty `AdRequest` without keywords, content URLs, neighboring content URLs, or
custom targeting.

The Google Mobile Ads SDK can automatically collect and share IP address,
product interactions, diagnostics, and device/account identifiers for
advertising, analytics, and fraud prevention. Google states that this data is
encrypted in transit with TLS. These SDK behaviors must be represented in the
public privacy policy and Play Data safety form.

## Required AdMob console work

1. Create an Android AdMob app for the final application ID.
2. Create one interstitial and one banner ad unit.
3. Under Privacy & messaging, publish the applicable European regulations and
   US states messages. UMP cannot display an unpublished account-side message.
4. Add and verify the public privacy-policy URL in both AdMob and Play Console.
5. Configure `app-ads.txt` on the developer website when AdMob supplies the
   publisher record.
6. Use Google's test IDs only in debug builds. Never install/click a live-ad
   build as a test device unless that device is registered for test ads.

Production IDs are supplied through `UNUTMA_ADMOB_APP_ID` and
`UNUTMA_ADMOB_INTERSTITIAL_ID` and `UNUTMA_ADMOB_BANNER_ID`; they are not
committed. If ads are disabled or a configuration is invalid, the application
uses a real no-op path and never pretends that an ad was displayed.
