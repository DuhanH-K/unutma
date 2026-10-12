import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const productionAppId = 'ca-app-pub-4879558726064660~8062049694';
  const productionBanner = 'ca-app-pub-4879558726064660/1712353053';
  const productionInterstitial = 'ca-app-pub-4879558726064660/1444670455';
  const androidBanner = 'ca-app-pub-4879558726064660/6443253838';
  const androidInterstitial = 'ca-app-pub-4879558726064660/3326135902';

  test('iOS release uses only iOS production AdMob IDs', () {
    final release = File('ios/Flutter/Release.xcconfig').readAsStringSync();

    expect(release, contains('ADMOB_IOS_APP_ID=$productionAppId'));
    expect(release, contains('ADMOB_IOS_BANNER=$productionBanner'));
    expect(release, contains('ADMOB_IOS_INTERSTITIAL=$productionInterstitial'));
    expect(release, contains('ADMOB_IOS_TEST_ADS=NO'));
    expect(release, isNot(contains(androidBanner)));
    expect(release, isNot(contains(androidInterstitial)));
    expect(release, isNot(contains('ca-app-pub-3940256099942544')));
  });

  test('iOS debug uses official iOS test IDs', () {
    final debug = File('ios/Flutter/Debug.xcconfig').readAsStringSync();

    expect(
      debug,
      contains('ADMOB_IOS_APP_ID=ca-app-pub-3940256099942544~1458002511'),
    );
    expect(
      debug,
      contains('ADMOB_IOS_BANNER=ca-app-pub-3940256099942544/2435281174'),
    );
    expect(
      debug,
      contains('ADMOB_IOS_INTERSTITIAL=ca-app-pub-3940256099942544/4411468910'),
    );
    expect(debug, contains('ADMOB_IOS_TEST_ADS=YES'));
  });

  test('Info.plist consumes build-specific IDs and SKAdNetwork list', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(plist, contains(r'<string>$(ADMOB_IOS_APP_ID)</string>'));
    expect(plist, contains(r'<string>$(ADMOB_IOS_BANNER)</string>'));
    expect(plist, contains(r'<string>$(ADMOB_IOS_INTERSTITIAL)</string>'));
    expect(plist, contains('cstr6suwn9.skadnetwork'));
    expect(plist, isNot(contains('NSUserTrackingUsageDescription')));
  });

  test('Codemagic keeps iOS version independent of Android release', () {
    final workflow = File('codemagic.yaml').readAsStringSync();
    expect(workflow, contains('IOS_VERSION_NAME: "1.0.12"'));
    expect(workflow, contains('IOS_BUILD_NUMBER: "14"'));
    expect(workflow, contains(r'--build-name="$IOS_VERSION_NAME"'));
    expect(workflow, contains(r'--build-number="$IOS_BUILD_NUMBER"'));
    expect(workflow, contains('flutter: 3.47.0'));
    expect(workflow, contains('bundle_identifier: app.unutma.mobile'));
  });

  test(
    'Codemagic uploads IPA without automatic review or App Store submission',
    () {
      final workflow = File('codemagic.yaml').readAsStringSync();
      expect(workflow, contains('app_store_connect: Codemagic'));
      expect(workflow, contains('distribution_type: app_store'));
      expect(workflow, contains('xcode-project use-profiles'));
      expect(workflow, contains('build/ios/ipa/*.ipa'));
      expect(workflow, contains('auth: integration'));
      expect(workflow, contains('submit_to_testflight: false'));
      expect(workflow, contains('submit_to_app_store: false'));
      expect(
        RegExp(r'^\s*publishing:', multiLine: true).hasMatch(workflow),
        true,
      );
      expect(
        RegExp(r'^\s*triggering:', multiLine: true).hasMatch(workflow),
        false,
      );
    },
  );
}
