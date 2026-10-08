import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unutma/core/services/ad_providers.dart';
import 'package:unutma/core/services/ad_service.dart';
import 'package:unutma/core/widgets/adaptive_banner_ad.dart';

void main() {
  const gate = AdFrequencyGate(
    minimumActions: 2,
    minimumInterval: Duration(seconds: 90),
    dailyCap: 2,
  );

  test('interstitial requires both action and time thresholds', () {
    final start = DateTime(2026, 8, 31, 12);
    var record = const AdFrequencyRecord();
    record = gate.recordAction(record, start);
    expect(gate.canShow(record, start.add(const Duration(minutes: 5))), false);

    record = gate.recordAction(record, start);

    expect(gate.canShow(record, start.add(const Duration(seconds: 89))), false);
    expect(gate.canShow(record, start.add(const Duration(seconds: 90))), true);

    record = gate.recordShown(record, start.add(const Duration(seconds: 90)));
    expect(record.actionsSinceAd, 0);
    expect(record.shownToday, 1);
  });

  test('daily cap persists and resets only on a new local day', () {
    final firstDay = DateTime(2026, 8, 31, 8);
    var record = const AdFrequencyRecord();
    for (var ad = 0; ad < 2; ad++) {
      for (var action = 0; action < 2; action++) {
        record = gate.recordAction(
          record,
          firstDay.add(Duration(minutes: ad * 10)),
        );
      }
      record = gate.recordShown(
        record,
        firstDay.add(Duration(minutes: ad * 10 + 3)),
      );
    }
    for (var action = 0; action < 2; action++) {
      record = gate.recordAction(
        record,
        firstDay.add(const Duration(hours: 1)),
      );
    }
    expect(gate.canShow(record, firstDay.add(const Duration(hours: 2))), false);

    final nextDay = DateTime(2026, 9, 1, 8);
    expect(gate.normalize(record, nextDay).shownToday, 0);
    expect(gate.canShow(record, nextDay), true);
  });

  test('invalid or disabled runtime configuration fails closed', () {
    expect(const AdRuntimeConfig.disabled().isUsable, false);
    expect(
      const AdRuntimeConfig(
        enabled: true,
        interstitialId: 'placeholder',
        bannerId: 'placeholder',
        testAds: false,
      ).isUsable,
      false,
    );
  });

  test('production runtime rejects Google sample ad unit IDs', () {
    const testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
    const testBanner = 'ca-app-pub-3940256099942544/6300978111';
    expect(
      const AdRuntimeConfig(
        enabled: true,
        interstitialId: testInterstitial,
        bannerId: testBanner,
        testAds: false,
      ).isUsable,
      false,
    );
    expect(
      const AdRuntimeConfig(
        enabled: true,
        interstitialId: testInterstitial,
        bannerId: testBanner,
        testAds: true,
      ).isUsable,
      true,
    );
  });

  testWidgets('banner load failure leaves no gap and does not crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adServiceProvider.overrideWithValue(const _FailingBannerAdService()),
        ],
        child: const MaterialApp(
          home: Scaffold(bottomNavigationBar: AdaptiveBannerAdSlot()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AdaptiveBannerAdSlot)).height, 0);
  });
}

class _FailingBannerAdService extends NoOpAdService {
  const _FailingBannerAdService();

  @override
  AdPrivacyState get state => const AdPrivacyState(
    enabled: true,
    canRequestAds: true,
    privacyOptionsRequired: false,
  );
}
