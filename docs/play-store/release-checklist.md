# Play release checklist

## Publisher-owned account setup

- [ ] Create/confirm the Play Console app with the fixed package name
      `app.unutma.mobile`. Never change it after the first upload.
- [ ] Complete developer identity, public developer name, support email, and
      required contact verification.
- [ ] Create the AdMob Android app using the exact final application ID.
- [ ] Create AdMob interstitial and banner units and publish applicable UMP messages.
- [x] Host the reviewed privacy policy on a stable public HTTPS URL:
      `https://unutma-app-dhk.web.app/gizlilik`.
- [ ] Create and securely back up the upload keystore; enable Play App Signing.

## Environment for `tools/build-play.ps1`

- `UNUTMA_ADS_ENABLED=true`
- `UNUTMA_ADMOB_APP_ID`
- `UNUTMA_ADMOB_INTERSTITIAL_ID`
- `UNUTMA_ADMOB_BANNER_ID`
- `UNUTMA_KEYSTORE`
- `UNUTMA_STORE_PASSWORD`
- `UNUTMA_KEY_ALIAS`
- `UNUTMA_KEY_PASSWORD`

Keep passwords in the local environment or a CI secret store. Do not place them
in source files, `.env` files committed to Git, command arguments, screenshots,
or support messages.

## Play Console App content

- [ ] Privacy policy URL.
- [ ] Ads: Yes.
- [ ] Data safety answers match `data-safety-notes.md` and the exact SDK version.
- [ ] Target audience and content rating completed by the publisher.
- [ ] Notification-access disclosure and reviewer instructions supplied.
- [ ] No account deletion declaration is needed unless an account system is
      added; this build has no account.

## Store assets

- [x] Export the Google Play icon as a 512×512 32-bit PNG (maximum 1 MB).
- [x] Create the required 1024×500 24-bit PNG feature graphic.
- [x] Produce four compliant 1080×1920 Turkish phone screenshots from real
      Flutter golden renders and privacy-safe demo data.
- [ ] Upload localized Turkish and English screenshots if promotional text is
      added outside the app UI. Turkish is ready; the generator's locale map and
      output layout are ready for English goldens.

## Artifact and staged rollout

- [ ] Increment `version`/build number in `pubspec.yaml` for every upload.
- [ ] Run the complete validation suite and `tools/build-play.ps1`.
- [ ] Verify the AAB signature, application ID, version code, target SDK, merged
      permissions, real AdMob IDs, and absence of Google test IDs.
- [ ] Upload first to internal testing, complete automated pre-launch reports,
      then closed testing if required for the developer account.
- [ ] Test UMP choices and interstitial delivery in applicable regions with test
      devices; never click live ads during validation.
- [ ] Review Android vitals and AdMob policy center before a staged production
      rollout.
