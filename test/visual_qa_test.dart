import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unutma/app.dart';
import 'package:unutma/core/data/providers.dart';
import 'package:unutma/core/domain/action_card.dart';

import 'support/memory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    goldenFileComparator = AuditedPlatformGoldenComparator(
      Uri.file('${Directory.current.path}/test/visual_qa_test.dart'),
      platformName: _goldenPlatform,
    );
    await _loadGoldenFonts();
  });
  final cases = <String, String>{
    'dashboard': '/',
    'store_dashboard': '/',
    'dashboard_empty': '/',
    'dashboard_no_access': '/',
    'inbox': '/inbox',
    'store_inbox_message': '/inbox',
    'detail': '/card/bill',
    'store_detail': '/card/bill',
    'settings': '/settings',
    'privacy': '/privacy',
    'share': '/share',
    'onboarding_value': '/onboarding',
    'onboarding_transform': '/onboarding',
    'onboarding_privacy': '/onboarding',
    'dark_dashboard': '/',
  };
  for (final entry in cases.entries) {
    testWidgets('visual ${entry.key}', (tester) async {
      tester.view.physicalSize = const Size(393, 873);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MemoryRepository()..items = fixtureCards();
      if (entry.key.contains('empty') || entry.key.contains('no_access')) {
        repo.items = [];
      }
      if (entry.key.contains('no_access')) repo.listener = false;
      if (entry.key == 'dark_dashboard') repo.prefs.theme = 'dark';
      if (entry.key == 'store_dashboard') {
        repo.items = [
          ...repo.items.take(2),
          repo.items.last.copyWith(
            title: 'Kargo',
            dueAt: DateTime(2026, 9, 9, 17),
          ),
        ];
      }
      if (entry.key == 'detail') {
        repo.items = [
          repo.items.first.copyWith(
            sourceMessage: 'Annem\nAbi yarın internet ödemesi var',
          ),
        ];
      }
      if (entry.key == 'store_detail') {
        repo.items = [
          repo.items.first.copyWith(
            dueAt: DateTime(2026, 9, 8, 18),
            sourceLabel: 'İnternet Sağlayıcısı',
            sourcePackage: 'demo.internet',
            sourceMessage: 'İnternet Sağlayıcısı\n549,90 TL internet faturanızın son ödeme tarihi 8 Eylül.',
          ),
        ];
      }
      if (entry.key == 'inbox') {
        repo.items = repo.items
            .map((c) => c.copyWith(status: CardStatus.review))
            .toList();
      }
      if (entry.key == 'store_inbox_message') {
        repo.items = [
          ActionCard(
            id: 'message-action',
            category: Category.other,
            title: 'Ekmek al',
            sourceLabel: 'WhatsApp',
            sourcePackage: 'com.whatsapp',
            status: CardStatus.review,
            confidence: .76,
            createdAt: fixtureNow,
            note: 'gelirken',
            sourceMessage: 'Anne\nGelirken ekmek almayı unutma',
            parserVersion: 4,
            revision: 1,
          ),
        ];
      }
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          clockProvider.overrideWithValue(() => fixtureNow),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(routerProvider)
          .go(
            entry.value,
            extra: entry.key == 'share'
                ? 'E-posta\nYarın 900 TL internet faturasını öde'
                : null,
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RepaintBoundary(key: Key('capture'), child: UnutmaApp()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/brand/unutma_app_icon_1024.png'),
          tester.element(find.byType(UnutmaApp)),
        );
      });
      await tester.pumpAndSettle();
      final steps = entry.key == 'onboarding_privacy'
          ? 2
          : entry.key == 'onboarding_transform'
          ? 1
          : 0;
      for (var i = 0; i < steps; i++) {
        await tester.tap(find.text('Devam'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const Key('capture')),
        matchesGoldenFile('goldens/$_goldenPlatform/${entry.key}.png'),
      );
    });
  }
}

String get _goldenPlatform {
  if (Platform.isWindows) return 'windows';
  if (Platform.isMacOS) return 'macos';
  throw UnsupportedError(
    'Visual golden tests have no verified baseline for '
    '${Platform.operatingSystem}.',
  );
}

Future<void> _loadGoldenFonts() async {
  Future<ByteData> readFont(String name) async {
    final bytes = await File('test/fonts/$name').readAsBytes();
    return ByteData.sublistView(bytes);
  }

  final roboto = FontLoader('Roboto');
  for (final name in const [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
  ]) {
    roboto.addFont(readFont(name));
  }
  await roboto.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(readFont('MaterialIcons-Regular.otf'));
  await icons.load();
}

final class AuditedPlatformGoldenComparator extends LocalFileComparator {
  AuditedPlatformGoldenComparator(super.testFile, {required this.platformName});

  final String platformName;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final baseline = File.fromUri(basedir.resolveUri(golden));
    if (!await baseline.exists()) {
      final failures = Directory.fromUri(basedir.resolve('failures/'));
      await failures.create(recursive: true);
      final goldenName = golden.pathSegments.last;
      final candidate = File(
        '${failures.path}/'
        '${goldenName.substring(0, goldenName.length - 4)}_'
        '${platformName}_candidate.png',
      );
      await candidate.writeAsBytes(imageBytes, flush: true);
      throw TestFailure(
        'No reviewed $platformName golden exists for $goldenName. '
        'The rendered candidate was written to ${candidate.path}; inspect it '
        'before adding it as a baseline.',
      );
    }
    return super.compare(imageBytes, golden);
  }
}
