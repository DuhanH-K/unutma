#!/bin/sh
set -eu

fail() {
  echo "error: $1" >&2
  exit 1
}

app_pattern='^ca-app-pub-[0-9]{16}~[0-9]{10}$'
unit_pattern='^ca-app-pub-[0-9]{16}/[0-9]{10}$'
google_test_prefix='ca-app-pub-3940256099942544'

[ "${UNUTMA_ADS_ENABLED:-}" = "YES" ] || fail "UNUTMA_ADS_ENABLED must be YES"
printf '%s' "${ADMOB_IOS_APP_ID:-}" | grep -Eq "$app_pattern" || fail "ADMOB_IOS_APP_ID is missing or invalid"
printf '%s' "${ADMOB_IOS_BANNER:-}" | grep -Eq "$unit_pattern" || fail "ADMOB_IOS_BANNER is missing or invalid"
printf '%s' "${ADMOB_IOS_INTERSTITIAL:-}" | grep -Eq "$unit_pattern" || fail "ADMOB_IOS_INTERSTITIAL is missing or invalid"

case "${CONFIGURATION:-}" in
  Release|Profile)
    [ "${ADMOB_IOS_TEST_ADS:-}" = "NO" ] || fail "Release/Profile must disable test ads"
    case "$ADMOB_IOS_APP_ID $ADMOB_IOS_BANNER $ADMOB_IOS_INTERSTITIAL" in
      *"$google_test_prefix"*) fail "Google test IDs cannot be used in Release/Profile" ;;
    esac
    ;;
  *)
    [ "${ADMOB_IOS_TEST_ADS:-}" = "YES" ] || fail "Debug must use test ads"
    for value in "$ADMOB_IOS_APP_ID" "$ADMOB_IOS_BANNER" "$ADMOB_IOS_INTERSTITIAL"; do
      case "$value" in
        "$google_test_prefix"*) ;;
        *) fail "Debug must use official Google iOS test IDs" ;;
      esac
    done
    ;;
esac
