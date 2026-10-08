import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unutma/core/theme/app_theme.dart';
import 'package:unutma/features/onboarding/onboarding_screen.dart';
import 'package:unutma/l10n/app_localizations.dart';

/// Explicit asset-export tool, not part of the default test suite.
/// Runtime continues to render responsive/localized widgets, not raster text.
void main() {
  testWidgets('export canonical onboarding compositions', (tester) async {
    tester.view.physicalSize = const Size(480, 440);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fonts = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await fonts.load();
    final config = File('.dart_tool/package_config.json');
    final packages =
        (jsonDecode(config.readAsStringSync())
                as Map<String, dynamic>)['packages']
            as List<dynamic>;
    final flutter = packages.cast<Map<String, dynamic>>().firstWhere(
      (p) => p['name'] == 'flutter',
    );
    final sdk = config.absolute.uri
        .resolve('${flutter['rootUri']}/')
        .resolve('../../');
    final roboto = FontLoader('Roboto')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File.fromUri(
              sdk.resolve(
                'bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/Roboto/Roboto-Regular.ttf',
              ),
            ).readAsBytesSync(),
          ),
        ),
      );
    await roboto.load();
    for (final entry in {
      1: 'onboarding_notification_to_action',
      2: 'onboarding_privacy_local',
    }.entries) {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.light),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: const Key('art'),
                child: SizedBox(
                  width: 360,
                  child: OnboardingArt(page: entry.key),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byKey(const Key('art')),
        matchesGoldenFile('../assets/illustrations/${entry.value}.png'),
      );
    }
  });
}
