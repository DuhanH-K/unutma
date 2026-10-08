import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/data/providers.dart';
import 'core/platform/unutma_api.g.dart';
import 'core/services/ad_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/shared.dart';
import 'core/widgets/adaptive_banner_ad.dart';
import 'l10n/app_localizations.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/inbox/inbox_screen.dart';
import 'features/history/history_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/manual_card/manual_card_screen.dart';
import 'features/manual_card/detail_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/paywall/paywall_screen.dart';
import 'features/share/share_import_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
          GoRoute(path: '/inbox', builder: (_, _) => const InboxScreen()),
          GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        ],
      ),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/disclosure',
        builder: (_, _) => const OnboardingScreen(disclosureOnly: true),
      ),
      GoRoute(
        path: '/new',
        builder: (_, s) => ManualCardScreen(initialText: s.extra as String?),
      ),
      GoRoute(
        path: '/share',
        builder: (_, s) => ShareImportScreen(text: s.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/edit/:id',
        builder: (_, s) => ManualCardScreen(id: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/card/:id',
        builder: (_, s) => DetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/privacy', builder: (_, _) => const PrivacyScreen()),
      GoRoute(
        path: '/terms',
        builder: (_, _) => const PrivacyScreen(terms: true),
      ),
      GoRoute(path: '/sources', builder: (_, _) => const SourcesScreen()),
      GoRoute(path: '/pro', builder: (_, _) => const PaywallScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class UnutmaApp extends ConsumerStatefulWidget {
  const UnutmaApp({super.key});
  @override
  ConsumerState<UnutmaApp> createState() => _UnutmaAppState();
}

class _UnutmaAppState extends ConsumerState<UnutmaApp>
    with WidgetsBindingObserver {
  static const _regularRoutes = {'/', '/inbox', '/history', '/settings'};
  bool consumingIntent = false;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = ref.read(routerProvider);
    _router!.routerDelegate.addListener(_handleRouteChanged);
    UnutmaEvents.setUp(
      _DataEvents(() {
        if (mounted) ref.invalidate(cardsProvider);
      }, consumePendingIntent),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => consumePendingIntent());
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_handleRouteChanged);
    UnutmaEvents.setUp(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleRouteChanged() {
    if (!mounted) return;
    final path = _router?.state.uri.path;
    if (_regularRoutes.contains(path)) {
      ref.read(adServiceProvider).resumeRegularSession();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(adServiceProvider).initialize());
      unawaited(refresh());
    }
  }

  Future<void> refresh() async {
    ref.invalidate(accessProvider);
    ref.invalidate(cardsProvider);
    try {
      await ref.read(repositoryProvider).reconcile();
      await consumePendingIntent();
    } catch (_) {
      /* Recoverable storage errors are shown by the screen providers. */
    }
  }

  Future<void> consumePendingIntent() async {
    if (consumingIntent || !mounted) return;
    consumingIntent = true;
    try {
      final repository = ref.read(repositoryProvider);
      final shared = await repository.sharedText();
      if (shared != null && shared.trim().isNotEmpty && mounted) {
        ref.read(adServiceProvider).suppressForSession();
        // Platform intents are destinations, not additions to the current
        // navigation stack. Replacing the location also avoids reserving the
        // same ShellRoute page key twice when a notification opens a tab.
        ref.read(routerProvider).go('/share', extra: shared);
        return;
      }
      final id = await repository.openedCard();
      if (id != null && mounted) {
        ref.read(adServiceProvider).suppressForSession();
        ref
            .read(routerProvider)
            .go(id.startsWith('route:') ? id.substring(6) : '/card/$id');
      }
    } catch (_) {
    } finally {
      consumingIntent = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final p = prefs.value;
    return MaterialApp.router(
      title: 'UNUTMA',
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: switch (p?.theme) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      },
      locale: p?.language.isNotEmpty == true ? Locale(p!.language) : null,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool checked = false;
  bool adsStarted = false;
  @override
  Widget build(BuildContext context) {
    final p = ref.watch(preferencesProvider);
    return p.when(
      loading: () => const Scaffold(body: Center(child: BrandMark(size: 64))),
      error: (_, _) => Scaffold(
        body: ErrorPanel(retry: () => ref.invalidate(preferencesProvider)),
      ),
      data: (prefs) {
        if (!prefs.onboarded) return const OnboardingScreen();
        if (!adsStarted) {
          adsStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(ref.read(adServiceProvider).initialize());
          });
        }
        if (!checked) {
          checked = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await ref.read(repositoryProvider).reconcile();
            } catch (_) {}
          });
        }
        final index = [
          '/',
          '/inbox',
          '/history',
          '/settings',
        ].indexOf(widget.path).clamp(0, 3);
        return Scaffold(
          body: widget.child,
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.path == '/') const AdaptiveBannerAdSlot(),
              NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) {
                  if (i == index) return;
                  context.go(['/', '/inbox', '/history', '/settings'][i]);
                },
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded),
                    label: context.l.home,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.inbox_outlined),
                    selectedIcon: const Icon(Icons.inbox_rounded),
                    label: context.l.inbox,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.history_rounded),
                    label: context.l.history,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.tune_rounded),
                    label: context.l.settings,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DataEvents extends UnutmaEvents {
  _DataEvents(this.changed, this.shared);
  final VoidCallback changed;
  final VoidCallback shared;
  @override
  void cardsChanged() => changed();
  @override
  void sharedTextReceived() => shared();
}
