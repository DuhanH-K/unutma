import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xs = 4.0,
      sm = 8.0,
      md = 12.0,
      base = 16.0,
      lg = 20.0,
      xl = 24.0,
      xxl = 32.0,
      xxxl = 40.0,
      huge = 48.0,
      hero = 64.0;
}

abstract final class AppRadius {
  static const small = 12.0, medium = 18.0, large = 24.0, pill = 999.0;
}

abstract final class AppMotion {
  static const quiet = Duration(milliseconds: 180);
}

abstract final class AppIconSize {
  static const category = 24.0, container = 48.0;
}

abstract final class AppElevation {
  static const card = 0.0;
}

abstract final class AppSemanticColors {
  static const ink = Color(0xFF17263D),
      orange = Color(0xFFEF702A),
      blue = Color(0xFF2563EB),
      green = Color(0xFF16815D);
}

abstract final class AppTypography {
  static const heading = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    height: 1.15,
  );
}

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppSemanticColors.blue,
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFF9DBAFF) : AppSemanticColors.blue,
        surface: dark ? const Color(0xFF111C2C) : Colors.white,
        onSurface: dark ? const Color(0xFFEDF1F7) : AppSemanticColors.ink,
        surfaceContainerLow: dark
            ? const Color(0xFF192637)
            : const Color(0xFFF5F7FB),
        outlineVariant: dark
            ? const Color(0xFF314156)
            : const Color(0xFFE6EBF2),
      );
  return ThemeData(
    platform: TargetPlatform.android,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
    ),
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF0C1523)
        : const Color(0xFFF8F9FC),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF0C1523) : const Color(0xFFF8F9FC),
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    textTheme: TextTheme(
      headlineLarge: AppTypography.heading,
      headlineMedium: AppTypography.heading.copyWith(fontSize: 26),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -.4,
      ),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
      bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .7)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primary.withValues(alpha: .10),
      height: 80,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
  );
}
