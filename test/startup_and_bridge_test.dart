import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unutma/app.dart';
import 'package:unutma/core/data/card_repository.dart';
import 'package:unutma/core/data/providers.dart';
import 'package:unutma/core/platform/unutma_api.g.dart';
import 'package:unutma/core/services/ad_providers.dart';
import 'package:unutma/core/services/ad_service.dart';
import 'package:unutma/core/widgets/startup_gate.dart';

import 'support/memory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final roboto = FontLoader('Roboto');
    for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
      roboto.addFont(
        File('test/fonts/Roboto-$weight.ttf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    }
    await roboto.load();
    await (FontLoader('MaterialIcons')..addFont(
          File('test/fonts/MaterialIcons-Regular.otf')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
  });

  test(
    'app version reads platform metadata independently on Android and iOS',
    () async {
      const channel = MethodChannel('app.unutma/app-info');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      for (final metadata in [
        {'name': '1.0.13', 'build': '15'},
        {'name': '1.0.12', 'build': '14'},
      ]) {
        messenger.setMockMethodCallHandler(channel, (_) async => metadata);
        final container = ProviderContainer();
        try {
          expect(
            await container.read(appVersionProvider.future),
            '${metadata['name']} (${metadata['build']})',
          );
        } finally {
          container.dispose();
        }
      }
    },
  );

  testWidgets(
    'unanswered app metadata cannot block settings or invent an old version',
    (tester) async {
      const channel = MethodChannel('app.unutma/app-info');
      final messenger = tester.binding.defaultBinaryMessenger;
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (_) {
        calls++;
        return Completer<Object?>().future;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final result = container.read(appVersionProvider.future);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(await result, '—');
      expect(calls, 1);
    },
  );

  test('native bridge roundtrips preferences, cards and revisions', () async {
    const codec = UnutmaApi.pigeonChannelCodec;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const prefix = 'dev.flutter.pigeon.unutma.UnutmaApi.';
    final preferences = PreferencesDto(
      onboarded: true,
      language: 'tr',
      theme: 'dark',
      reminderMinutes: 1440,
    );
    final dto = fixtureCards().first.toDto();
    messenger.setMockDecodedMessageHandler<Object?>(
      const BasicMessageChannel<Object?>('${prefix}getPreferences', codec),
      (_) async => [preferences],
    );
    messenger.setMockDecodedMessageHandler<Object?>(
      const BasicMessageChannel<Object?>('${prefix}saveCard', codec),
      (message) async {
        final decoded = (message! as List).first as CardDto;
        expect(decoded.sourceMessage, dto.sourceMessage);
        expect(decoded.dueAt, dto.dueAt);
        decoded.revision += 1;
        return [decoded];
      },
    );
    addTearDown(() {
      for (final method in ['getPreferences', 'saveCard']) {
        messenger.setMockDecodedMessageHandler<Object?>(
          BasicMessageChannel<Object?>('$prefix$method', codec),
          null,
        );
      }
    });
    final repo = NativeCardRepository();
    expect((await repo.preferences()).theme, 'dark');
    final saved = await repo.save(fixtureCards().first);
    expect(saved.revision, dto.revision + 1);
  });

  test(
    'unanswered native call terminates with a safe bridge failure',
    () async {
      final repo = NativeCardRepository(
        _HangingApi(),
        const Duration(milliseconds: 5),
      );
      await expectLater(
        repo.preferences(),
        throwsA(
          isA<AppFailure>().having((e) => e.kind, 'kind', FailureKind.bridge),
        ),
      );
    },
  );

  testWidgets(
    'startup error is visible, does not auto-retry, manual retry recovers',
    (tester) async {
      final repository = _RecoverableRepository();
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          adServiceProvider.overrideWithValue(const NoOpAdService()),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const UnutmaApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(preferencesProvider).hasError, true);
      expect(repository.preferenceReads, 1);
      expect(find.byType(OutlinedButton), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      expect(repository.preferenceReads, 1);
      repository.broken = false;
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(container.read(preferencesProvider).hasValue, true);
      expect(find.byKey(const Key('dashboard_add')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'all Pigeon methods are generated, implemented and linked into Runner',
    () {
      final input = File('pigeons/unutma_api.dart').readAsStringSync();
      final generated = File('ios/Runner/UnutmaApi.g.swift').readAsStringSync();
      final native = File('ios/Runner/NativeUnutmaApi.swift')
          .readAsStringSync();
      final project = File('ios/Runner.xcodeproj/project.pbxproj')
          .readAsStringSync();
      final api = input
          .split('abstract class UnutmaApi {')[1]
          .split('@FlutterApi')[0];
      final methods = RegExp(r'\b(\w+)\([^;]*\);')
          .allMatches(api)
          .map((m) => m[1]!)
          .toList();
      expect(methods.length, 16);
      for (final method in methods) {
        expect(generated, contains('func $method('), reason: method);
        expect(native, contains('func $method('), reason: method);
      }
      for (final name in [
        'UnutmaApi.g',
        'NativeUnutmaApi',
        'IOSLocalStore',
        'IOSReminders',
      ]) {
        expect(project, contains('$name.swift in Sources'));
      }
      expect(
        File('ios/Runner/AppDelegate.swift').readAsStringSync(),
        contains('UnutmaApiSetup.setUp(binaryMessenger: messenger, api: api)'),
      );
    },
  );

  testWidgets(
    'splash finishes within two seconds and respects reduced motion',
    (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StartupGate(
            onComplete: () => completed++,
            child: const Text('ready'),
          ),
        ),
      );
      final began = tester.binding.clock.now();
      await tester.pumpAndSettle(const Duration(milliseconds: 10));
      expect(
        tester.binding.clock.now().difference(began),
        lessThanOrEqualTo(const Duration(seconds: 2)),
      );
      expect(completed, 1);
      expect(find.text('UNUTMA'), findsNothing);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: StartupGate(
              key: const Key('reduced'),
              onComplete: () => completed++,
              child: const Text('instant'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('UNUTMA'), findsNothing);
      expect(find.text('instant'), findsOneWidget);
      expect(completed, 2);
    },
  );

  testWidgets(
    'iOS offers manual reminders without Android listener permission',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(
            MemoryRepository()..listener = false,
          ),
          adServiceProvider.overrideWithValue(const NoOpAdService()),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const UnutmaApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Metinden ekle'), findsOneWidget);
      expect(find.text('Otomatik yakalama çalışmıyor'), findsNothing);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('capture actual Flutter startup frames in light and dark themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final brightness in Brightness.values) {
      final key = GlobalKey();
      final repository = MemoryRepository()..items = fixtureCards();
      repository.prefs.theme = brightness.name;
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => fixtureNow),
          adServiceProvider.overrideWithValue(const NoOpAdService()),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(key: key, child: const UnutmaApp()),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/brand/unutma_app_icon_1024.png'),
          tester.element(find.byType(StartupGate)),
        ),
      );
      for (var frame = 0; frame < 18; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            '.qa/startup/${brightness.name}-${frame.toString().padLeft(2, '0')}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    }
  });
}

class _HangingApi extends UnutmaApi {
  @override
  Future<PreferencesDto> getPreferences() => Completer<PreferencesDto>().future;
}

class _RecoverableRepository extends MemoryRepository {
  bool broken = true;
  int preferenceReads = 0;
  @override
  Future<PreferencesDto> preferences() async {
    preferenceReads++;
    if (broken) throw const AppFailure(FailureKind.bridge);
    return prefs;
  }
}
