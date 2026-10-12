#!/usr/bin/env bash
# macOS/Xcode only. Debug uses test ads; never signs or uploads an IPA.
set -euo pipefail
cd "$(dirname "$0")/.."
[[ "$(uname -s)" == Darwin ]] || { echo 'macOS and Xcode are required.' >&2; exit 1; }
mkdir -p .qa/ios
flutter pub get
flutter build ios --simulator --debug --no-codesign 2>&1 | tee .qa/ios/build.log
simulator_id="${UNUTMA_SIMULATOR_ID:-$(xcrun simctl list devices available -j | python3 -c '
import sys,json
devices=[d for values in json.load(sys.stdin)["devices"].values() for d in values if "iPhone" in d["name"]]
if not devices: raise SystemExit("No available iPhone simulator; install an iOS runtime in Xcode.")
print(next((d["udid"] for d in devices if d["state"]=="Booted"),devices[0]["udid"]))
')}"
if ! xcrun simctl list devices booted -j | grep -q "$simulator_id"; then
  xcrun simctl boot "$simulator_id"
fi
xcrun simctl bootstatus "$simulator_id" -b
result_bundle=".qa/ios/native-tests-$(date +%Y%m%d-%H%M%S).xcresult"
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug \
  -destination "id=$simulator_id" CODE_SIGNING_ALLOWED=NO \
  -resultBundlePath "$result_bundle" test 2>&1 | tee .qa/ios/native-tests.log
xcrun simctl install "$simulator_id" build/ios/iphonesimulator/Runner.app
xcrun simctl launch --terminate-running-process "$simulator_id" app.unutma.mobile
sleep 3
xcrun simctl io "$simulator_id" screenshot .qa/ios/launch.png
xcrun simctl spawn "$simulator_id" log show --last 2m --style compact \
  --predicate 'subsystem == "app.unutma.mobile"' > .qa/ios/runtime.log
echo 'Inspect launch.png/runtime.log; simulator success is not a real iPhone test.'
