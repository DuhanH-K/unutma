import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class AdRuntimeConfig {
  const AdRuntimeConfig({
    required this.enabled,
    required this.interstitialId,
    required this.bannerId,
    required this.testAds,
  });

  const AdRuntimeConfig.disabled()
    : enabled = false,
      interstitialId = '',
      bannerId = '',
      testAds = false;

  final bool enabled;
  final String interstitialId;
  final String bannerId;
  final bool testAds;

  bool get isUsable {
    final unitPattern = RegExp(r'^ca-app-pub-[0-9]{16}/[0-9]{10}$');
    if (!enabled ||
        !unitPattern.hasMatch(interstitialId) ||
        !unitPattern.hasMatch(bannerId)) {
      return false;
    }
    const googleTestPrefix = 'ca-app-pub-3940256099942544/';
    return testAds ||
        (!interstitialId.startsWith(googleTestPrefix) &&
            !bannerId.startsWith(googleTestPrefix));
  }
}

class NativeAdConfigLoader {
  const NativeAdConfigLoader();

  static const _channel = MethodChannel('app.unutma/ads-config');

  Future<AdRuntimeConfig> load() async {
    try {
      final value = await _channel.invokeMethod<Object?>('getConfig');
      if (value is! Map) return const AdRuntimeConfig.disabled();
      final config = AdRuntimeConfig(
        enabled: value['enabled'] == true,
        interstitialId: value['interstitialId'] as String? ?? '',
        bannerId: value['bannerId'] as String? ?? '',
        testAds: value['testAds'] == true,
      );
      return config.isUsable ? config : const AdRuntimeConfig.disabled();
    } on PlatformException {
      return const AdRuntimeConfig.disabled();
    } on MissingPluginException {
      return const AdRuntimeConfig.disabled();
    }
  }
}

class AdPrivacyState {
  const AdPrivacyState({
    required this.enabled,
    required this.canRequestAds,
    required this.privacyOptionsRequired,
  });

  const AdPrivacyState.disabled()
    : enabled = false,
      canRequestAds = false,
      privacyOptionsRequired = false;

  final bool enabled;
  final bool canRequestAds;
  final bool privacyOptionsRequired;
}

abstract interface class AdService {
  AdPrivacyState get state;
  Stream<AdPrivacyState> get states;
  Future<void> initialize();
  Future<void> registerAction();
  Future<bool> showAtSessionBreak({required bool isPro});
  Future<LoadedBannerAd?> loadAdaptiveBanner(int width);
  void releaseBanner(LoadedBannerAd banner);
  void suppressForSession();
  void resumeRegularSession();
  Future<bool> showPrivacyOptions();
  Future<void> resetLocalState();
  Future<void> dispose();
}

class NoOpAdService implements AdService {
  const NoOpAdService();

  @override
  AdPrivacyState get state => const AdPrivacyState.disabled();
  @override
  Stream<AdPrivacyState> get states => const Stream.empty();
  @override
  Future<void> initialize() async {}
  @override
  Future<void> registerAction() async {}
  @override
  Future<bool> showAtSessionBreak({required bool isPro}) async => false;
  @override
  Future<LoadedBannerAd?> loadAdaptiveBanner(int width) async => null;
  @override
  void releaseBanner(LoadedBannerAd banner) => banner.ad.dispose();
  @override
  void suppressForSession() {}
  @override
  void resumeRegularSession() {}
  @override
  Future<bool> showPrivacyOptions() async => false;
  @override
  Future<void> resetLocalState() async {}
  @override
  Future<void> dispose() async {}
}

class LoadedBannerAd {
  const LoadedBannerAd(this.ad);

  final BannerAd ad;
  AdSize get size => ad.size;
}

class AdFrequencyRecord {
  const AdFrequencyRecord({
    this.actionsSinceAd = 0,
    this.firstEligibleActionAtMillis = 0,
    this.lastShownAtMillis = 0,
    this.dayKey = 0,
    this.shownToday = 0,
  });

  final int actionsSinceAd;
  final int firstEligibleActionAtMillis;
  final int lastShownAtMillis;
  final int dayKey;
  final int shownToday;

  AdFrequencyRecord copyWith({
    int? actionsSinceAd,
    int? firstEligibleActionAtMillis,
    int? lastShownAtMillis,
    int? dayKey,
    int? shownToday,
  }) => AdFrequencyRecord(
    actionsSinceAd: actionsSinceAd ?? this.actionsSinceAd,
    firstEligibleActionAtMillis:
        firstEligibleActionAtMillis ?? this.firstEligibleActionAtMillis,
    lastShownAtMillis: lastShownAtMillis ?? this.lastShownAtMillis,
    dayKey: dayKey ?? this.dayKey,
    shownToday: shownToday ?? this.shownToday,
  );
}

class AdFrequencyGate {
  const AdFrequencyGate({
    required this.minimumActions,
    required this.minimumInterval,
    required this.dailyCap,
  });

  final int minimumActions;
  final Duration minimumInterval;
  final int dailyCap;

  int _dayKey(DateTime now) => now.year * 10000 + now.month * 100 + now.day;

  AdFrequencyRecord normalize(AdFrequencyRecord record, DateTime now) {
    final today = _dayKey(now);
    return record.dayKey == today
        ? record
        : record.copyWith(dayKey: today, shownToday: 0);
  }

  AdFrequencyRecord recordAction(AdFrequencyRecord record, DateTime now) {
    final current = normalize(record, now);
    return current.copyWith(
      actionsSinceAd: current.actionsSinceAd + 1,
      firstEligibleActionAtMillis: current.firstEligibleActionAtMillis == 0
          ? now.millisecondsSinceEpoch
          : current.firstEligibleActionAtMillis,
    );
  }

  bool canShow(AdFrequencyRecord record, DateTime now) {
    final current = normalize(record, now);
    if (current.actionsSinceAd < minimumActions ||
        current.shownToday >= dailyCap) {
      return false;
    }
    final anchor = current.lastShownAtMillis == 0
        ? current.firstEligibleActionAtMillis
        : current.lastShownAtMillis;
    return anchor > 0 &&
        now.millisecondsSinceEpoch - anchor >= minimumInterval.inMilliseconds;
  }

  AdFrequencyRecord recordShown(AdFrequencyRecord record, DateTime now) {
    final current = normalize(record, now);
    return current.copyWith(
      actionsSinceAd: 0,
      firstEligibleActionAtMillis: 0,
      lastShownAtMillis: now.millisecondsSinceEpoch,
      shownToday: current.shownToday + 1,
    );
  }
}

abstract interface class AdFrequencyStore {
  Future<AdFrequencyRecord> read();
  Future<void> write(AdFrequencyRecord record);
  Future<void> clear();
}

class SharedPreferencesAdFrequencyStore implements AdFrequencyStore {
  SharedPreferencesAdFrequencyStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _actions = 'unutma.ads.actionsSinceAd';
  static const _firstAction = 'unutma.ads.firstEligibleActionAt';
  static const _lastShown = 'unutma.ads.lastShownAt';
  static const _day = 'unutma.ads.day';
  static const _shownToday = 'unutma.ads.shownToday';
  static const _keys = [_actions, _firstAction, _lastShown, _day, _shownToday];
  final SharedPreferencesAsync _preferences;

  @override
  Future<AdFrequencyRecord> read() async => AdFrequencyRecord(
    actionsSinceAd: await _preferences.getInt(_actions) ?? 0,
    firstEligibleActionAtMillis: await _preferences.getInt(_firstAction) ?? 0,
    lastShownAtMillis: await _preferences.getInt(_lastShown) ?? 0,
    dayKey: await _preferences.getInt(_day) ?? 0,
    shownToday: await _preferences.getInt(_shownToday) ?? 0,
  );

  @override
  Future<void> write(AdFrequencyRecord record) async {
    await _preferences.setInt(_actions, record.actionsSinceAd);
    await _preferences.setInt(_firstAction, record.firstEligibleActionAtMillis);
    await _preferences.setInt(_lastShown, record.lastShownAtMillis);
    await _preferences.setInt(_day, record.dayKey);
    await _preferences.setInt(_shownToday, record.shownToday);
  }

  @override
  Future<void> clear() async {
    for (final key in _keys) {
      await _preferences.remove(key);
    }
  }
}

class GoogleMobileAdsService implements AdService {
  GoogleMobileAdsService({
    this._configLoader = const NativeAdConfigLoader(),
    this._frequencyStore,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const _maximumAdAge = Duration(minutes: 55);
  static const _frequencyGate = AdFrequencyGate(
    minimumActions: AppConfig.minSuccessfulActionsBetweenInterstitials,
    minimumInterval: AppConfig.interstitialCooldown,
    dailyCap: AppConfig.dailyInterstitialCap,
  );

  final NativeAdConfigLoader _configLoader;
  AdFrequencyStore? _frequencyStore;
  final DateTime Function() _clock;
  final StreamController<AdPrivacyState> _states =
      StreamController<AdPrivacyState>.broadcast(sync: true);
  AdPrivacyState _state = const AdPrivacyState.disabled();
  AdRuntimeConfig _config = const AdRuntimeConfig.disabled();
  InterstitialAd? _interstitial;
  final Set<LoadedBannerAd> _banners = <LoadedBannerAd>{};
  DateTime? _loadedAt;
  Future<void> _frequencyWrites = Future.value();
  bool _initializing = false;
  bool _initialized = false;
  bool _mobileAdsStarted = false;
  bool _loading = false;
  bool _showing = false;
  bool _sessionSuppressed = false;
  bool _disposed = false;
  Timer? _interstitialRetry;
  int _interstitialLoadFailures = 0;

  String get _platformLabel => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'Android',
    TargetPlatform.iOS => 'iOS',
    _ => defaultTargetPlatform.name,
  };

  void _logAds(String message) {
    if (!kDebugMode) return;
    developer.log('[ADS][$_platformLabel] $message', name: 'UNUTMA.AdMob');
  }

  void _logInterstitial(String message) {
    _logAds('[Interstitial] $message');
  }

  AdFrequencyStore get _store =>
      _frequencyStore ??= SharedPreferencesAdFrequencyStore();

  @override
  AdPrivacyState get state => _state;
  @override
  Stream<AdPrivacyState> get states => _states.stream;

  void _emit(AdPrivacyState value) {
    _state = value;
    if (!_states.isClosed) _states.add(value);
  }

  @override
  Future<void> initialize() async {
    if (_initialized || _initializing || _disposed) return;
    _initializing = true;
    try {
      _config = await _configLoader.load();
      if (!_config.isUsable) return;
      _emit(
        const AdPrivacyState(
          enabled: true,
          canRequestAds: false,
          privacyOptionsRequired: false,
        ),
      );

      var updateSucceeded = false;
      final update = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          updateSucceeded = true;
          if (!update.isCompleted) update.complete();
        },
        (_) {
          if (!update.isCompleted) update.complete();
        },
      );
      await update.future;
      if (updateSucceeded) {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
      }
      await _refreshConsentState();
      if (_state.canRequestAds) await _startMobileAds();
      _initialized = true;
    } catch (_) {
      // Ads fail closed; platform, consent, or network failures must never
      // affect the core reminder behavior.
    } finally {
      _initializing = false;
    }
  }

  Future<void> _refreshConsentState() async {
    final required =
        await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
    final allowed = await ConsentInformation.instance.canRequestAds();
    _emit(
      AdPrivacyState(
        enabled: _config.isUsable,
        canRequestAds: allowed,
        privacyOptionsRequired: required,
      ),
    );
  }

  Future<void> _startMobileAds() async {
    if (_mobileAdsStarted || _disposed) return;
    await MobileAds.instance.initialize();
    _mobileAdsStarted = true;
    _logAds('SDK initialized');
    await _loadInterstitial();
  }

  Future<void> _loadInterstitial() async {
    if (!_mobileAdsStarted || _loading || _showing || _disposed) return;
    _loading = true;
    _logInterstitial('load requested');
    try {
      await InterstitialAd.load(
        adUnitId: _config.interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loading = false;
            if (_disposed) {
              ad.dispose();
              return;
            }
            _interstitial?.dispose();
            _interstitial = ad;
            _loadedAt = _clock();
            _interstitialLoadFailures = 0;
            _interstitialRetry?.cancel();
            _interstitialRetry = null;
            _logInterstitial('loaded');
          },
          onAdFailedToLoad: (error) {
            _loading = false;
            _interstitial = null;
            _loadedAt = null;
            _logInterstitial(
              'failed: code=${error.code} domain=${error.domain} '
              'message=${error.message} responseInfo=${error.responseInfo}',
            );
            _scheduleInterstitialRetry();
          },
        ),
      );
    } catch (error) {
      _loading = false;
      _interstitial = null;
      _loadedAt = null;
      _logInterstitial('load failed: ${error.runtimeType}');
      _scheduleInterstitialRetry();
    }
  }

  void _scheduleInterstitialRetry() {
    if (_disposed || _interstitialRetry?.isActive == true) return;
    final exponent = _interstitialLoadFailures.clamp(0, 4);
    final delay = Duration(seconds: 30 * (1 << exponent));
    _interstitialLoadFailures++;
    _logInterstitial('retry scheduled: ${delay.inSeconds}s');
    _interstitialRetry = Timer(delay, () {
      _interstitialRetry = null;
      if (_interstitial == null && !_loading && !_showing && !_disposed) {
        unawaited(_loadInterstitial());
      }
    });
  }

  Future<void> _reloadInterstitial(String reason) async {
    _logInterstitial('reload: $reason');
    await _loadInterstitial();
  }

  @override
  Future<LoadedBannerAd?> loadAdaptiveBanner(int width) async {
    if (width <= 0 ||
        !_state.canRequestAds ||
        !_mobileAdsStarted ||
        _disposed) {
      return null;
    }
    try {
      _logAds('[Banner] load requested');
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (size == null || _disposed) return null;
      final result = Completer<LoadedBannerAd?>();
      var settled = false;
      late final BannerAd ad;
      void complete(LoadedBannerAd? value) {
        if (settled) {
          value?.ad.dispose();
          return;
        }
        settled = true;
        if (!result.isCompleted) result.complete(value);
      }

      ad = BannerAd(
        adUnitId: _config.bannerId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (loaded) {
            if (_disposed || settled) {
              loaded.dispose();
              return;
            }
            final banner = LoadedBannerAd(loaded as BannerAd);
            _banners.add(banner);
            _logAds('[Banner] loaded');
            complete(banner);
          },
          onAdFailedToLoad: (failed, error) {
            _logAds(
              '[Banner] failed: code=${error.code} domain=${error.domain} '
              'message=${error.message} responseInfo=${error.responseInfo}',
            );
            failed.dispose();
            complete(null);
          },
        ),
      );
      await ad.load();
      return await result.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          settled = true;
          ad.dispose();
          return null;
        },
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void releaseBanner(LoadedBannerAd banner) {
    _banners.remove(banner);
    banner.ad.dispose();
  }

  @override
  Future<void> registerAction() {
    if (!_config.isUsable || _disposed) return Future.value();
    _frequencyWrites = _frequencyWrites.then((_) async {
      try {
        final record = await _store.read();
        final updated = _frequencyGate.recordAction(record, _clock());
        await _store.write(updated);
        _logAds('Completed action; count=${updated.actionsSinceAd}');
      } catch (_) {
        // A failed cap write must never unlock an ad display.
      }
    });
    return _frequencyWrites;
  }

  @override
  Future<bool> showAtSessionBreak({required bool isPro}) async {
    final blockedReason = switch ((
      isPro,
      _sessionSuppressed,
      _state.canRequestAds,
      _mobileAdsStarted,
      _showing,
      _disposed,
    )) {
      (true, _, _, _, _, _) => 'pro entitlement',
      (_, true, _, _, _, _) => 'notification/share flow',
      (_, _, false, _, _, _) => 'consent unavailable',
      (_, _, _, false, _, _) => 'SDK not started',
      (_, _, _, _, true, _) => 'already showing',
      (_, _, _, _, _, true) => 'service disposed',
      _ => null,
    };
    if (blockedReason != null) {
      _logInterstitial('blocked: $blockedReason');
      return false;
    }
    await _frequencyWrites;
    AdFrequencyRecord record;
    try {
      record = await _store.read();
    } catch (_) {
      return false;
    }
    if (!_frequencyGate.canShow(record, _clock())) {
      final current = _frequencyGate.normalize(record, _clock());
      final reason = current.actionsSinceAd < _frequencyGate.minimumActions
          ? 'count (${current.actionsSinceAd}/${_frequencyGate.minimumActions})'
          : current.shownToday >= _frequencyGate.dailyCap
          ? 'daily cap'
          : 'cooldown';
      _logInterstitial('skipped: $reason');
      return false;
    }

    final ad = _interstitial;
    final loadedAt = _loadedAt;
    if (ad == null ||
        loadedAt == null ||
        _clock().difference(loadedAt) > _maximumAdAge) {
      ad?.dispose();
      _interstitial = null;
      _loadedAt = null;
      await _reloadInterstitial('ad unavailable or stale');
      return false;
    }

    _showing = true;
    _interstitial = null;
    _loadedAt = null;
    final shown = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) {
        _logInterstitial('shown');
        _frequencyWrites = _frequencyWrites.then((_) async {
          try {
            final current = await _store.read();
            await _store.write(_frequencyGate.recordShown(current, _clock()));
          } catch (_) {}
        });
        if (!shown.isCompleted) shown.complete(true);
      },
      onAdDismissedFullScreenContent: (value) {
        _logInterstitial('dismissed');
        value.dispose();
        _showing = false;
        unawaited(_reloadInterstitial('dismissed'));
      },
      onAdFailedToShowFullScreenContent: (value, error) {
        _logInterstitial('show failed: code=${error.code}');
        value.dispose();
        _showing = false;
        if (!shown.isCompleted) shown.complete(false);
        unawaited(_reloadInterstitial('show failed'));
      },
    );
    try {
      _logInterstitial('show called');
      await ad.show();
      return await shown.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (error) {
      _logInterstitial('show failed: ${error.runtimeType}');
      ad.dispose();
      _showing = false;
      unawaited(_reloadInterstitial('show exception'));
      return false;
    }
  }

  @override
  void suppressForSession() {
    _sessionSuppressed = true;
    _logInterstitial('blocked: notification/share flow entered');
  }

  @override
  void resumeRegularSession() {
    if (!_sessionSuppressed) return;
    _sessionSuppressed = false;
    _logInterstitial('notification/share block cleared');
  }

  @override
  Future<bool> showPrivacyOptions() async {
    if (!_config.isUsable || _disposed) return false;
    FormError? formError;
    try {
      await ConsentForm.showPrivacyOptionsForm((error) => formError = error);
      await _refreshConsentState();
      if (_state.canRequestAds) {
        await _startMobileAds();
      } else {
        _interstitial?.dispose();
        _interstitial = null;
        _loadedAt = null;
        _disposeBanners();
      }
      return formError == null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> resetLocalState() async {
    try {
      await _store.clear();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _interstitialRetry?.cancel();
    _interstitialRetry = null;
    _interstitial?.dispose();
    _interstitial = null;
    _disposeBanners();
    await _states.close();
  }

  void _disposeBanners() {
    for (final banner in _banners) {
      banner.ad.dispose();
    }
    _banners.clear();
  }
}
