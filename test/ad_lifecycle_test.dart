import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// Exercise the pinned SDK's real codec and callback dispatcher, without ads
// network traffic or production impressions in automated tests.
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:google_mobile_ads/src/ump/user_messaging_codec.dart';
import 'package:unutma/core/config/app_config.dart';
import 'package:unutma/core/services/ad_service.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      '$platform loads, shows, disposes and preloads after dismissal',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final harness = _AdsHarness(tester);
        try {
          await harness.start();
          expect(harness.loads.length, 1);
          expect(harness.shows, 0); // No ad on initialization/first launch.
          final id = harness.loads.single['adId'] as int;
          await harness.event(id, 'onAdLoaded');
          await harness.service.registerAction();
          await harness.service.registerAction();
          harness.now = harness.now.add(const Duration(seconds: 90));
          expect(await harness.service.showAtSessionBreak(isPro: false), true);
          expect(harness.shows, 1);
          await harness.event(
            id,
            platform == TargetPlatform.iOS
                ? 'adDidDismissFullScreenContent'
                : 'onAdDismissedFullScreenContent',
          );
          await tester.pump();
          expect(harness.disposedIds, contains(id));
          expect(harness.loads.length, 2);
          expect((await harness.store.read()).shownToday, 1);
        } finally {
          await harness.close();
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  }

  testWidgets('consent denied prevents both banner and interstitial requests', (
    tester,
  ) async {
    final harness = _AdsHarness(tester)..consentAllowed = false;
    try {
      await harness.start();
      expect(harness.service.state.canRequestAds, false);
      expect(harness.loads, isEmpty);
      expect(await harness.service.loadAdaptiveBanner(393), isNull);
      expect(await harness.service.showAtSessionBreak(isPro: false), false);
      expect(harness.shows, 0);
    } finally {
      await harness.close();
    }
  });

  testWidgets('editing, modal, background and notification flow block show', (
    tester,
  ) async {
    final harness = _AdsHarness(tester);
    try {
      await harness.start();
      await harness.event(harness.loads.single['adId'] as int, 'onAdLoaded');
      await harness.service.registerAction();
      await harness.service.registerAction();
      harness.now = harness.now.add(const Duration(minutes: 2));
      harness.safeToPresent = false;
      expect(await harness.service.showAtSessionBreak(isPro: false), false);
      harness.safeToPresent = true;
      harness.service.suppressForSession();
      expect(await harness.service.showAtSessionBreak(isPro: false), false);
      harness.service.resumeRegularSession();
      harness.service.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(await harness.service.showAtSessionBreak(isPro: false), false);
      harness.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(await harness.service.showAtSessionBreak(isPro: false), true);
      expect(harness.shows, 1);
    } finally {
      await harness.close();
    }
  });

  testWidgets(
    'load callback timeout retries, late callbacks cannot replace a newer ad',
    (tester) async {
      final harness = _AdsHarness(tester);
      try {
        await harness.start();
        final first = harness.loads.single['adId'] as int;
        await tester.pump(const Duration(seconds: 30));
        expect(harness.loads.length, 1);
        await tester.pump(const Duration(seconds: 30));
        expect(harness.loads.length, 2);
        await harness.event(first, 'onAdLoaded');
        expect(harness.disposedIds, contains(first));
        final second = harness.loads.last['adId'] as int;
        await harness.event(second, 'onAdLoaded');
        await harness.service.registerAction();
        await harness.service.registerAction();
        harness.now = harness.now.add(const Duration(minutes: 2));
        expect(await harness.service.showAtSessionBreak(isPro: false), true);
        expect(harness.lastShownId, second);
      } finally {
        await harness.close();
      }
    },
  );

  testWidgets(
    'no-fill retries with backoff and pauses requests in background',
    (tester) async {
      final harness = _AdsHarness(tester);
      try {
        await harness.start();
        await harness.event(
          harness.loads.single['adId'] as int,
          'onAdFailedToLoad',
          {'loadAdError': LoadAdError(3, 'test', 'No fill', null)},
        );
        await tester.pump(const Duration(seconds: 29));
        expect(harness.loads.length, 1);
        harness.service.didChangeAppLifecycleState(AppLifecycleState.paused);
        await tester.pump(const Duration(minutes: 10));
        expect(harness.loads.length, 1);
        harness.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await tester.pump();
        expect(harness.loads.length, 2);
      } finally {
        await harness.close();
      }
    },
  );

  testWidgets('slow consent interaction cannot open duplicate forms', (
    tester,
  ) async {
    final harness = _AdsHarness(tester)..consentForm = Completer<Object?>();
    try {
      final start = harness.service.initialize();
      await tester.pump();
      await tester.pump(const Duration(seconds: 40));
      await harness.service.initialize();
      expect(harness.formRequests, 1);
      expect(harness.loads, isEmpty);
      harness.consentForm!.complete(null);
      await tester.pump();
      await start;
      expect(harness.loads.length, 1);
    } finally {
      await harness.close();
    }
  });

  testWidgets('adaptive banner resizes and releases stale background loads', (
    tester,
  ) async {
    final harness = _AdsHarness(tester);
    try {
      await harness.start();
      final portrait = harness.service.loadAdaptiveBanner(393);
      await tester.pump();
      final first = harness.bannerLoads.last['adId'] as int;
      await harness.event(first, 'onAdLoaded');
      final loaded = await portrait;
      expect(loaded!.size.width, 393);
      harness.service.releaseBanner(loaded);
      expect(harness.disposedIds, contains(first));

      final landscape = harness.service.loadAdaptiveBanner(750);
      await tester.pump();
      final second = harness.bannerLoads.last['adId'] as int;
      harness.service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await harness.event(second, 'onAdLoaded');
      expect(await landscape, isNull);
      expect(harness.disposedIds, contains(second));
      expect(await harness.service.loadAdaptiveBanner(750), isNull);
      expect(harness.bannerLoads.length, 2);
    } finally {
      await harness.close();
    }
  });

  testWidgets('banner no-fill and missing callbacks release native resources', (
    tester,
  ) async {
    final harness = _AdsHarness(tester);
    try {
      await harness.start();
      final failed = harness.service.loadAdaptiveBanner(393);
      await tester.pump();
      final first = harness.bannerLoads.last['adId'] as int;
      await harness.event(first, 'onAdFailedToLoad', {
        'loadAdError': LoadAdError(3, 'test', 'No fill', null),
      });
      expect(await failed, isNull);
      expect(harness.disposedIds, contains(first));
      final timedOut = harness.service.loadAdaptiveBanner(393);
      await tester.pump();
      final second = harness.bannerLoads.last['adId'] as int;
      await tester.pump(const Duration(seconds: 15));
      expect(await timedOut, isNull);
      expect(harness.disposedIds, contains(second));
    } finally {
      await harness.close();
    }
  });

  testWidgets('interstitial show failure reloads without consuming daily cap', (
    tester,
  ) async {
    final harness = _AdsHarness(tester)..showFails = true;
    try {
      await harness.start();
      final first = harness.loads.single['adId'] as int;
      await harness.event(first, 'onAdLoaded');
      await harness.service.registerAction();
      await harness.service.registerAction();
      harness.now = harness.now.add(const Duration(seconds: 90));
      expect(await harness.service.showAtSessionBreak(isPro: false), false);
      expect(harness.disposedIds, contains(first));
      expect(harness.loads.length, 2);
      expect((await harness.store.read()).shownToday, 0);
    } finally {
      await harness.close();
    }
  });

  test(
    'old and proposed daily ceilings retain identical action/cooldown guards',
    () {
      const old = AdFrequencyGate(
        minimumActions: 2,
        minimumInterval: Duration(seconds: 90),
        dailyCap: 2,
      );
      const proposed = AdFrequencyGate(
        minimumActions: AppConfig.minSuccessfulActionsBetweenInterstitials,
        minimumInterval: AppConfig.interstitialCooldown,
        dailyCap: AppConfig.dailyInterstitialCap,
      );
      var record = const AdFrequencyRecord();
      final start = DateTime(2026, 10, 12, 9);
      for (var i = 0; i < 6; i++) {
        final now = start.add(Duration(minutes: 3 * i));
        record = proposed.recordAction(record, now);
        record = proposed.recordAction(record, now);
        expect(proposed.canShow(record, now), i > 0);
        final showAt = now.add(const Duration(seconds: 90));
        expect(old.canShow(record, showAt), i < 2);
        expect(proposed.canShow(record, showAt), true);
        record = proposed.recordShown(record, showAt);
      }
      record = proposed.recordAction(
        record,
        start.add(const Duration(hours: 1)),
      );
      record = proposed.recordAction(
        record,
        start.add(const Duration(hours: 1)),
      );
      expect(
        proposed.canShow(record, start.add(const Duration(hours: 2))),
        false,
      );
    },
  );
}

class _Store implements AdFrequencyStore {
  AdFrequencyRecord record = const AdFrequencyRecord();
  @override
  Future<AdFrequencyRecord> read() async => record;
  @override
  Future<void> write(AdFrequencyRecord value) async => record = value;
  @override
  Future<void> clear() async => record = const AdFrequencyRecord();
}

class _AdsHarness {
  _AdsHarness(this.tester) {
    service = GoogleMobileAdsService(
      frequencyStore: store,
      clock: () => now,
      canPresent: () => safeToPresent,
    );
    messenger.setMockMethodCallHandler(
      configChannel,
      (_) async => {
        'enabled': true,
        'testAds': true,
        'bannerId': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ca-app-pub-3940256099942544/2435281174'
            : 'ca-app-pub-3940256099942544/6300978111',
        'interstitialId': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ca-app-pub-3940256099942544/4411468910'
            : 'ca-app-pub-3940256099942544/1033173712',
      },
    );
    messenger.setMockMethodCallHandler(umpChannel, (call) async {
      switch (call.method) {
        case 'ConsentInformation#canRequestAds':
          return consentAllowed;
        case 'ConsentInformation#getPrivacyOptionsRequirementStatus':
          return 1;
        case 'UserMessagingPlatform#loadAndShowConsentFormIfRequired':
          formRequests++;
          return consentForm?.future;
        default:
          return null;
      }
    });
    messenger.setMockMethodCallHandler(sdkChannel, (call) async {
      switch (call.method) {
        case 'MobileAds#initialize':
          return InitializationStatus({});
        case 'loadInterstitialAd':
          loads.add(Map<Object?, Object?>.from(call.arguments as Map));
        case 'loadBannerAd':
          bannerLoads.add(Map<Object?, Object?>.from(call.arguments as Map));
        case 'disposeAd':
          disposedIds.add((call.arguments as Map)['adId'] as int);
        case 'showAdWithoutView':
          shows++;
          lastShownId = (call.arguments as Map)['adId'] as int;
          await event(
            lastShownId!,
            showFails
                ? 'onFailedToShowFullScreenContent'
                : defaultTargetPlatform == TargetPlatform.iOS
                ? 'adWillPresentFullScreenContent'
                : 'onAdShowedFullScreenContent',
            showFails
                ? {'error': AdError(0, 'test', 'Presentation failed')}
                : const {},
          );
        case 'AdSize#getLargeAnchoredAdaptiveBannerAdSize':
          return 60;
      }
      return null;
    });
  }
  final WidgetTester tester;
  TestDefaultBinaryMessenger get messenger =>
      tester.binding.defaultBinaryMessenger;
  static const configChannel = MethodChannel('app.unutma/ads-config');
  static final umpChannel = MethodChannel(
    'plugins.flutter.io/google_mobile_ads/ump',
    StandardMethodCodec(UserMessagingCodec()),
  );
  MethodChannel get sdkChannel => instanceManager.channel;
  final store = _Store();
  late final GoogleMobileAdsService service;
  DateTime now = DateTime(2026, 10, 12, 9);
  bool consentAllowed = true, safeToPresent = true, showFails = false;
  int shows = 0, formRequests = 0;
  int? lastShownId;
  Completer<Object?>? consentForm;
  final loads = <Map<Object?, Object?>>[];
  final bannerLoads = <Map<Object?, Object?>>[];
  final disposedIds = <int>[];
  Future<void> start() async {
    await service.initialize();
  }

  Future<void> event(
    int id,
    String name, [
    Map<String, Object?> extra = const {},
  ]) async {
    final completed = Completer<void>();
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      sdkChannel.name,
      sdkChannel.codec.encodeMethodCall(
        MethodCall('onAdEvent', {'adId': id, 'eventName': name, ...extra}),
      ),
      (_) => completed.complete(),
    );
    await completed.future;
  }

  Future<void> close() async {
    await service.dispose();
    await tester.pump();
    messenger.setMockMethodCallHandler(configChannel, null);
    messenger.setMockMethodCallHandler(umpChannel, null);
    messenger.setMockMethodCallHandler(sdkChannel, null);
  }
}
