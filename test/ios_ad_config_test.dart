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
}
