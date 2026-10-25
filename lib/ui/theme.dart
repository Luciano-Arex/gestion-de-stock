import 'package:flutter/material.dart';

/// Couleurs et formes communes à tous les écrans.
ThemeData appTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF00695C), brightness: brightness);
  final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return ThemeData(
    colorScheme: scheme,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: scheme.surfaceContainerLowest,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surfaceContainerLowest,
      centerTitle: false,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: rounded)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: rounded)),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
