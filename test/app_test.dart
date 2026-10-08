import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unutma/app.dart';
import 'package:unutma/core/data/providers.dart';
import 'package:unutma/core/data/card_repository.dart';
import 'package:unutma/core/domain/action_card.dart';
import 'package:unutma/core/platform/unutma_api.g.dart';
import 'package:unutma/core/services/ad_providers.dart';
import 'package:unutma/core/services/ad_service.dart';

import 'support/memory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<ProviderContainer> launch(
    WidgetTester tester,
    MemoryRepository repo, {
    String route = '/',
    Object? extra,
    Size size = const Size(393, 873),
    double scale = 1,
    AdService? adService,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(() => fixtureNow),
        if (adService != null) adServiceProvider.overrideWithValue(adService),
      ],
    );
    addTearDown(container.dispose);
    container.read(routerProvider).go(route, extra: extra);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
          ),
          child: const UnutmaApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  test('calendar grouping respects local day boundaries', () {
    final card = fixtureCards().first;
    expect(groupFor(card, fixtureNow), DateGroup.today);
    expect(
      groupFor(card.copyWith(dueAt: DateTime(2026, 9, 8)), fixtureNow),
      DateGroup.tomorrow,
    );
    expect(
      groupFor(card.copyWith(dueAt: DateTime(2026, 9, 6)), fixtureNow),
      DateGroup.overdue,
    );
  });
  test('immutable domain DTO and JSON roundtrip', () {
    final card = fixtureCards().first;
    expect(ActionCard.fromDto(card.toDto()), card);
    expect(ActionCard.fromJson(card.toJson()), card);
  });
  test('bridge maps platform failure without exposing details', () async {
    final api = ThrowingApi();
    final repo = NativeCardRepository(api);
    await expectLater(repo.cards(), throwsA(isA<AppFailure>()));
  });
  test('controller completion reloads canonical state', () async {
    final repo = MemoryRepository()..items = fixtureCards();
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container.read(cardsProvider.future);
    await container
        .read(cardsProvider.notifier)
        .transition(repo.items.first, 'done');
    expect(container.read(cardsProvider).value!.first.status, CardStatus.done);
  });
  testWidgets('dashboard empty and no access states', (tester) async {
    await launch(tester, MemoryRepository()..listener = false);
    expect(find.text('Otomatik yakalama çalışmıyor'), findsOneWidget);
    expect(find.text('Şimdilik her şey yolunda.'), findsNWidgets(2));
  });
  testWidgets('dashboard grouped cards and complete', (tester) async {
    final repo = MemoryRepository()..items = fixtureCards();
    await launch(tester, repo);
    expect(find.text('BUGÜN'), findsOneWidget);
    expect(find.text('YARIN'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.text('Ödendi'));
    await tester.pumpAndSettle();
    expect(repo.items.first.status, CardStatus.done);
  });
  testWidgets('dashboard add action opens the manual card form', (
    tester,
  ) async {
    await launch(tester, MemoryRepository());
    await tester.tap(find.byKey(const Key('dashboard_add')));
    await tester.pumpAndSettle();
    expect(find.text('Aklında kalmasın.'), findsOneWidget);
  });
  testWidgets('inbox confirm edit ignore', (tester) async {
    final repo = MemoryRepository()
      ..items = fixtureCards()
          .map((c) => c.copyWith(status: CardStatus.review))
          .toList();
    final container = await launch(tester, repo, route: '/inbox');
    await tester.tap(find.text('Onayla').first);
    await tester.pumpAndSettle();
    expect(repo.items.first.status, CardStatus.active);
    await tester.tap(find.text('Düzenle').first);
    await tester.pumpAndSettle();
    expect(find.text('Kartı düzenle'), findsOneWidget);
    container.read(routerProvider).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yoksay').first);
    await tester.pumpAndSettle();
    expect(repo.items[1].status, CardStatus.archived);
  });
  testWidgets('onboarding disclosure skip reaches manual mode', (tester) async {
    final repo = MemoryRepository()..prefs.onboarded = false;
    await launch(tester, repo);
    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(find.text('Devam'));
      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Neye erişir?'), findsOneWidget);
    await tester.ensureVisible(find.text('Şimdilik geç'));
    await tester.tap(find.text('Şimdilik geç'));
    await tester.pumpAndSettle();
    expect(repo.prefs.onboarded, true);
  });
  testWidgets('delete data requires explicit confirmation', (tester) async {
    final repo = MemoryRepository()..items = fixtureCards();
    await launch(tester, repo, route: '/settings');
    await tester.scrollUntilVisible(find.text('Tüm yerel verileri sil'), 250);
    await tester.ensureVisible(find.text('Tüm yerel verileri sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tüm yerel verileri sil'));
    await tester.pumpAndSettle();
    expect(repo.items, isNotEmpty);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(repo.items, isNotEmpty);
    await tester.tap(find.text('Tüm yerel verileri sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evet, hepsini sil'));
    await tester.pumpAndSettle();
    expect(repo.items, isEmpty);
  });
  testWidgets('recoverable error offers retry', (tester) async {
    final repo = MemoryRepository()..fail = true;
    await launch(tester, repo);
    expect(find.text('Tekrar dene'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();
    expect(find.text('Tekrar dene'), findsNothing);
  });
  testWidgets('manual card saves without notification access', (tester) async {
    final repo = MemoryRepository()
      ..listener = false
      ..reminders = false;
    await launch(tester, repo, route: '/new');
    await tester.enterText(find.byType(TextFormField).first, 'Su faturası');
    await tester.tap(find.text('Tarih seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Kaydet'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(repo.items.single.title, 'Su faturası');
    expect(repo.items.single.dueAt, isNotNull);
  });
  testWidgets('shared text is previewed before persistence', (tester) async {
    final repo = MemoryRepository();
    const shared = 'Yarın 500 TL doğalgaz ödemesi var';
    await launch(tester, repo, route: '/share', extra: shared);
    expect(find.text('UNUTMA’ya ekle'), findsNWidgets(2));
    expect(find.text(shared), findsOneWidget);
    expect(repo.importedText, isNull);
    await tester.tap(find.text('Analiz et'));
    await tester.pumpAndSettle();
    expect(repo.importedText, shared);
    expect(find.text('Aklında kalmasın.'), findsOneWidget);
    expect(find.text(shared), findsWidgets);
  });

  testWidgets('incoming share opens the local preview flow', (tester) async {
    final repo = MemoryRepository()..pendingSharedText = 'Cuma 14:00 toplantı';
    await launch(tester, repo);
    expect(find.text('UNUTMA’ya ekle'), findsNWidgets(2));
    expect(find.text('Cuma 14:00 toplantı'), findsOneWidget);
    expect(repo.importedText, isNull);
  });

  testWidgets('share ad suppression clears after returning to regular flow', (
    tester,
  ) async {
    final repo = MemoryRepository()..pendingSharedText = 'Cuma 14:00 toplantı';
    final ads = _TrackingAdService();
    final container = await launch(tester, repo, adService: ads);

    expect(container.read(routerProvider).state.uri.path, '/share');
    expect(ads.suppressions, 1);
    expect(ads.resumptions, 0);

    container.read(routerProvider).go('/');
    await tester.pumpAndSettle();

    expect(ads.resumptions, 1);
  });

  testWidgets('platform route replaces an existing detail stack safely', (
    tester,
  ) async {
    final repo = MemoryRepository()..items = fixtureCards();
    final container = await launch(tester, repo, route: '/card/bill');
    repo.pendingOpenedCard = 'route:/inbox';

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(container.read(routerProvider).state.uri.path, '/inbox');
    expect(find.text('Kontrol et'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resuming the app retries ad initialization', (tester) async {
    final ads = _TrackingAdService();
    await launch(tester, MemoryRepository(), adService: ads);
    final initializationsBeforeResume = ads.initializations;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(ads.initializations, initializationsBeforeResume + 1);
  });

  testWidgets('parsed shared text opens its review card', (tester) async {
    final repo = MemoryRepository()
      ..items = [fixtureCards().first.copyWith(status: CardStatus.review)]
      ..importResult = 'bill';
    const shared = 'Yarın internet faturasını öde';
    await launch(tester, repo, route: '/share', extra: shared);
    await tester.tap(find.text('Analiz et'));
    await tester.pumpAndSettle();
    expect(repo.importedText, shared);
    expect(find.text('Aksiyon kartı'), findsOneWidget);
    expect(
      find.text('Bu bildirimden emin olamadım. Tarihi kontrol edip onayla.'),
      findsOneWidget,
    );
  });
  testWidgets('detail shows and deletes the encrypted source message', (
    tester,
  ) async {
    const message = 'Annem\nAbi yarın internet ödemesi var';
    final repo = MemoryRepository()
      ..items = [fixtureCards().first.copyWith(sourceMessage: message)];
    await launch(tester, repo, route: '/card/bill');

    expect(find.text('Kaynak mesaj'), findsOneWidget);
    expect(find.text(message), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mesajı sil'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mesajı sil'));
    await tester.pumpAndSettle();
    expect(find.text('Kaynak mesaj silinsin mi?'), findsOneWidget);
    await tester.tap(find.text('Mesajı sil').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repo.items.single.sourceMessage, isNull);
    expect(find.text(message), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('directly opened action card always has a working back button', (
    tester,
  ) async {
    final repo = MemoryRepository()..items = fixtureCards();
    final container = await launch(tester, repo, route: '/card/bill');

    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(container.read(routerProvider).state.uri.path, '/');
    expect(find.text('Ana sayfa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct review card back button returns to the review inbox', (
    tester,
  ) async {
    final repo = MemoryRepository()
      ..items = [fixtureCards().first.copyWith(status: CardStatus.review)];
    final container = await launch(tester, repo, route: '/card/bill');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(container.read(routerProvider).state.uri.path, '/inbox');
    expect(find.text('Kontrol et'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone bill review detail fits the phone without scrolling', (
    tester,
  ) async {
    const message =
        'DEFNE MİNA KAPLAN🐱🌟😃\n'
        'oğlum yarın telefon faturası var ödemeyi unutma';
    final repo = MemoryRepository()
      ..items = [
        fixtureCards().first.copyWith(
          title: '',
          category: Category.bill,
          sourceLabel: 'WhatsApp',
          sourcePackage: 'com.whatsapp',
          dueAt: DateTime(2026, 9, 2, 9),
          amount: null,
          currency: null,
          status: CardStatus.review,
          sourceMessage: message,
        ),
      ];
    await launch(tester, repo, route: '/card/bill');

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.maxScrollExtent, 0);
    expect(find.text('Fatura'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Fatura')).style?.fontSize, 20);
    expect(find.text('Onayla'), findsOneWidget);
    expect(find.text('Düzenle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('ad-enabled privacy exposes disclosure and UMP options', (
    tester,
  ) async {
    await launch(
      tester,
      MemoryRepository(),
      route: '/privacy',
      adService: const _EnabledAdService(),
    );
    final adTitle = find.text('Reklam ve gizlilik');
    await tester.scrollUntilVisible(
      adTitle,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(adTitle, findsOneWidget);
    expect(find.textContaining('reklam isteğine eklenmez'), findsOneWidget);
    final privacyOptions = find.text('Reklam gizlilik seçenekleri');
    await tester.scrollUntilVisible(
      privacyOptions,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(privacyOptions, findsOneWidget);
  });
  for (final locale in ['tr', 'en']) {
    for (final theme in ['light', 'dark']) {
      for (final width in [360.0, 393.0, 412.0]) {
        for (final scale in [1.0, 1.3]) {
          testWidgets('responsive $locale $theme $width scale $scale', (
            tester,
          ) async {
            final repo = MemoryRepository()
              ..items = fixtureCards()
              ..prefs.language = locale
              ..prefs.theme = theme;
            final container = await launch(
              tester,
              repo,
              size: Size(
                width,
                width == 360
                    ? 800
                    : width == 393
                    ? 873
                    : 915,
              ),
              scale: scale,
            );
            for (final route in [
              '/inbox',
              '/card/bill',
              '/new',
              '/settings',
              '/privacy',
              '/share',
              '/onboarding',
              '/disclosure',
            ]) {
              container
                  .read(routerProvider)
                  .go(
                    route,
                    extra: route == '/share'
                        ? 'Yarın 900 TL internet faturasını öde'
                        : null,
                  );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: route);
            }
          });
        }
      }
    }
  }
}

class _EnabledAdService extends NoOpAdService {
  const _EnabledAdService();

  @override
  AdPrivacyState get state => const AdPrivacyState(
    enabled: true,
    canRequestAds: true,
    privacyOptionsRequired: true,
  );
}

class _TrackingAdService extends NoOpAdService {
  int initializations = 0;
  int suppressions = 0;
  int resumptions = 0;
  bool suppressed = false;

  @override
  Future<void> initialize() async {
    initializations++;
  }

  @override
  void suppressForSession() {
    suppressed = true;
    suppressions++;
  }

  @override
  void resumeRegularSession() {
    if (!suppressed) return;
    suppressed = false;
    resumptions++;
  }
}

class ThrowingApi extends UnutmaApi {
  @override
  Future<List<CardDto>> getCards() async => throw PlatformException(
    code: 'storage_failure',
    message: 'Sensitive internal text must not escape',
  );
}
