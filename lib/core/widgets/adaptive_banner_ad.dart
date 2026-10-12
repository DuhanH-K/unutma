import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_providers.dart';
import '../services/ad_service.dart';

/// Shows an anchored adaptive banner only after it has loaded successfully.
/// Until then it occupies no space and never blocks the app's navigation.
class AdaptiveBannerAdSlot extends ConsumerStatefulWidget {
  const AdaptiveBannerAdSlot({
    super.key,
    this.retryBaseDelay = const Duration(seconds: 30),
  });

  @visibleForTesting
  final Duration retryBaseDelay;

  @override
  ConsumerState<AdaptiveBannerAdSlot> createState() =>
      _AdaptiveBannerAdSlotState();
}

class _AdaptiveBannerAdSlotState extends ConsumerState<AdaptiveBannerAdSlot>
    with WidgetsBindingObserver {
  LoadedBannerAd? _banner;
  int? _requestedWidth;
  bool _loading = false;
  Timer? _retryTimer;
  int _loadFailures = 0;
  int _generation = 0;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _clear();
    } else {
      setState(() {});
    }
  }

  void _request(int width) {
    if (!_foreground || _loading || width <= 0 || width == _requestedWidth) {
      return;
    }
    _retryTimer?.cancel();
    _retryTimer = null;
    _requestedWidth = width;
    final generation = _generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _generation && _foreground) {
        unawaited(_load(width, generation));
      }
    });
  }

  Future<void> _load(int width, int generation) async {
    if (_loading || !mounted) return;
    _loading = true;
    final service = ref.read(adServiceProvider);
    final loaded = await service.loadAdaptiveBanner(width);
    if (!mounted ||
        generation != _generation ||
        !_foreground ||
        _requestedWidth != width) {
      if (loaded != null) service.releaseBanner(loaded);
      return;
    }
    final previous = _banner;
    if (mounted) {
      setState(() {
        _banner = loaded;
        _loading = false;
      });
    }
    if (previous != null) service.releaseBanner(previous);
    if (loaded == null) {
      _scheduleRetry(width);
    } else {
      _loadFailures = 0;
      _retryTimer?.cancel();
      _retryTimer = null;
    }
  }

  void _scheduleRetry(int width) {
    if (!mounted || _retryTimer?.isActive == true) return;
    final exponent = _loadFailures.clamp(0, 4);
    final delay = widget.retryBaseDelay * (1 << exponent);
    _loadFailures++;
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (!mounted || _requestedWidth != width) return;
      _requestedWidth = null;
      _request(width);
    });
  }

  void _clear() {
    _generation++;
    final current = _banner;
    _retryTimer?.cancel();
    _retryTimer = null;
    _loadFailures = 0;
    setState(() {
      _banner = null;
      _requestedWidth = null;
      _loading = false;
    });
    if (current != null) ref.read(adServiceProvider).releaseBanner(current);
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    final current = _banner;
    if (current != null) ref.read(adServiceProvider).releaseBanner(current);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canRequestAds =
        ref.watch(adPrivacyStateProvider).value?.canRequestAds == true;
    if (!canRequestAds || !_foreground) {
      if (_banner != null || _requestedWidth != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _clear();
        });
      }
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - MediaQuery.paddingOf(context).horizontal)
                .floor();
        _request(width);
        final banner = _banner;
        if (banner == null || banner.size.width > width) {
          return const SizedBox.shrink();
        }
        return ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Center(
              child: SizedBox(
                width: banner.size.width.toDouble(),
                height: banner.size.height.toDouble(),
                child: AdWidget(ad: banner.ad),
              ),
            ),
          ),
        );
      },
    );
  }
}
