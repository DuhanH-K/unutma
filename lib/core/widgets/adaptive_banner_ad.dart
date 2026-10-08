import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_providers.dart';
import '../services/ad_service.dart';

/// Shows an anchored adaptive banner only after it has loaded successfully.
/// Until then it occupies no space and never blocks the app's navigation.
class AdaptiveBannerAdSlot extends ConsumerStatefulWidget {
  const AdaptiveBannerAdSlot({super.key});

  @override
  ConsumerState<AdaptiveBannerAdSlot> createState() =>
      _AdaptiveBannerAdSlotState();
}

class _AdaptiveBannerAdSlotState extends ConsumerState<AdaptiveBannerAdSlot> {
  LoadedBannerAd? _banner;
  int? _requestedWidth;
  bool _loading = false;

  void _request(int width) {
    if (_loading || width <= 0 || width == _requestedWidth) return;
    _requestedWidth = width;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load(width));
    });
  }

  Future<void> _load(int width) async {
    if (_loading || !mounted) return;
    _loading = true;
    final service = ref.read(adServiceProvider);
    final loaded = await service.loadAdaptiveBanner(width);
    if (!mounted || _requestedWidth != width) {
      if (loaded != null) service.releaseBanner(loaded);
      _loading = false;
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
  }

  void _clear() {
    final current = _banner;
    setState(() {
      _banner = null;
      _requestedWidth = null;
      _loading = false;
    });
    if (current != null) ref.read(adServiceProvider).releaseBanner(current);
  }

  @override
  void dispose() {
    final current = _banner;
    if (current != null) ref.read(adServiceProvider).releaseBanner(current);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canRequestAds =
        ref.watch(adPrivacyStateProvider).value?.canRequestAds == true;
    if (!canRequestAds) {
      if (_banner != null || _requestedWidth != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _clear();
        });
      }
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.floor();
        _request(width);
        final banner = _banner;
        if (banner == null) return const SizedBox.shrink();
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
