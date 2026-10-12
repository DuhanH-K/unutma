import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_service.dart';

final adServiceProvider = Provider<AdService>((ref) {
  final service = GoogleMobileAdsService(
    canPresent: () =>
        ref.read(adPresentationAllowedProvider) &&
        !ref.read(adModalOpenProvider),
  );
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final adPresentationAllowedProvider =
    NotifierProvider<AdPresentationAllowed, bool>(AdPresentationAllowed.new);

final adModalOpenProvider = NotifierProvider<AdPresentationAllowed, bool>(
  AdPresentationAllowed.new,
);

/// Track Flutter dialogs independently of the destination URL. A successful
/// save may dispose its form before the ad callback; the destination, rather
/// than the disposed form's context, decides whether presentation is safe.
class AdModalObserver extends NavigatorObserver {
  AdModalObserver(this.onChanged);
  final ValueChanged<bool> onChanged;
  final Set<Route<dynamic>> _dialogs = {};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) _dialogs.add(route);
    onChanged(_dialogs.isNotEmpty);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dialogs.remove(route);
    onChanged(_dialogs.isNotEmpty);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dialogs.remove(route);
    onChanged(_dialogs.isNotEmpty);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _dialogs.remove(oldRoute);
    if (newRoute is PopupRoute) _dialogs.add(newRoute);
    onChanged(_dialogs.isNotEmpty);
  }
}

class AdPresentationAllowed extends Notifier<bool> {
  @override
  bool build() => false;
  void update(bool allowed) => state = allowed;
}

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
