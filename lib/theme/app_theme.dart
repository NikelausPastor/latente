import 'package:flutter/material.dart';

class AppTheme {
  static const inkBlack = Color(0xFF05070B);
  static const deepBlue = Color(0xFF0B172A);
  static const darkPanel = Color(0xFF101B2F);
  static const softBlue = Color(0xFF9BCBFF);
  static const silver = Color(0xFFD7E5F7);
  static const muted = Color(0xFF8395AE);
  static const warning = Color(0xFFF6C177);

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: softBlue,
      brightness: Brightness.dark,
      surface: darkPanel,
    );

    return ThemeData(
      colorScheme: colorScheme.copyWith(
        primary: softBlue,
        secondary: const Color(0xFF6EA8D9),
        surface: darkPanel,
        error: const Color(0xFFFF8A8A),
      ),
      scaffoldBackgroundColor: inkBlack,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: inkBlack,
        foregroundColor: silver,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: darkPanel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF20304A)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: softBlue,
          foregroundColor: inkBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: silver,
          side: const BorderSide(color: Color(0xFF37506F)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size.fromHeight(44),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0C1424),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF293A56)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF293A56)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: softBlue, width: 1.4),
        ),
        labelStyle: const TextStyle(color: muted),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF1E2C42)),
      listTileTheme: const ListTileThemeData(
        iconColor: softBlue,
        textColor: silver,
      ),
    );
  }
}
