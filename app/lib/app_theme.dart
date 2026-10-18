/// Tiny Repair Town — spec palette theme (master prompt §11).
///
/// Suggested palette: cream #FFF5E6, blue #63B8E8, green #7BCB8B,
/// coral #F28C7A, yellow #F5CF63, text #243746.
/// Contrast of these combinations is NOT pre-approved (see KNOWN_ISSUES.md);
/// text is kept dark-on-light and buttons use dark text on bright fills.
library;

import 'package:flutter/material.dart';

class TownTheme {
  static const cream = Color(0xFFFFF5E6);
  static const blue = Color(0xFF63B8E8);
  static const green = Color(0xFF7BCB8B);
  static const coral = Color(0xFFF28C7A);
  static const yellow = Color(0xFFF5CF63);
  static const ink = Color(0xFF243746);
  static const white = Color(0xFFFFFFFF);

  /// Minimum touch target for child controls (spec §14: >= 56 logical px).
  static const double minTouch = 56.0;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: Brightness.light,
    ).copyWith(
      primary: blue,
      secondary: green,
      tertiary: coral,
      surface: cream,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
            color: ink, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(
            color: ink, fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: TextStyle(color: ink, fontSize: 18),
        bodyLarge: TextStyle(color: ink, fontSize: 18),
        bodyMedium: TextStyle(color: ink, fontSize: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, minTouch),
          textStyle:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
