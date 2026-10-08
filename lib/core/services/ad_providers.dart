import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_service.dart';

final adServiceProvider = Provider<AdService>((ref) {
  final service = GoogleMobileAdsService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final adPrivacyStateProvider = StreamProvider<AdPrivacyState>((ref) async* {
  final service = ref.watch(adServiceProvider);
  yield service.state;
  yield* service.states;
});

/// Billing is disabled in V1. A verified entitlement can override this provider
/// when Play Billing is enabled; ads already fail closed for Pro users.
final proEntitlementProvider = Provider<bool>((ref) => false);

/// Records a completed user task after the UI has had a frame to update, then
/// lets the frequency gate decide whether an interstitial is appropriate.
void scheduleEligibleAdAction(WidgetRef ref) {
  final service = ref.read(adServiceProvider);
  final isPro = ref.read(proEntitlementProvider);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(() async {
      await service.registerAction();
      await service.showAtSessionBreak(isPro: isPro);
    }());
  });
}
