// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Renkler (PDF'e göre)
  // Açık Tema Renkleri
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF2563EB);
  static const Color lightSecondary = Color(0xFF94A3B8);
  static const Color lightText = Color(0xFF1E293B);
  static const Color lightError = Color(0xFFDC2626);

  // Koyu Tema Renkleri
  static const Color darkBackground = Color(0xFF1f2d50);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkPrimary = Color(0xFF3B82F6);
  static const Color darkSecondary = Color(0xFF64748B);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkError = Color(0xFFEF4444);

  // Text Tema Fonksiyonu
  static TextTheme _textTheme(Color textColor) {
    return GoogleFonts.manropeTextTheme(
      TextTheme(
        displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textColor, height: 1.5),
        bodyMedium: TextStyle(color: textColor, height: 1.5),
        labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2), // Buton metni
      ),
    );
  }

  // Ortak Stiller
  static final _cardTheme = CardThemeData(
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
    ),
  );

  static final _inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: lightPrimary, width: 2),
    ),
  );

  // Açık Tema
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: lightPrimary,
    scaffoldBackgroundColor: lightBackground,
    textTheme: _textTheme(lightText),
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      surface: lightCard,
      background: lightBackground,
      error: lightError,
      onPrimary: Colors.white,
      onSecondary: lightText,
      onSurface: lightText,
      onBackground: lightText,
      onError: Colors.white,
    ),
    cardTheme: _cardTheme.copyWith(color: lightCard, surfaceTintColor: Colors.white),
    appBarTheme: AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.grey.withOpacity(0.5),
      iconTheme: const IconThemeData(color: lightText),
      titleTextStyle: _textTheme(lightText).headlineSmall,
    ),
    inputDecorationTheme: _inputDecorationTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        textStyle: _textTheme(Colors.white).labelLarge,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        elevation: 1,
      ),
    ),
  );

  // Koyu Tema
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkBackground,
    textTheme: _textTheme(darkText),
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      surface: darkCard,
      background: darkBackground,
      error: darkError,
      onPrimary: Colors.white,
      onSecondary: darkText,
      onSurface: darkText,
      onBackground: darkText,
      onError: Colors.white,
    ),
    cardTheme: _cardTheme.copyWith(color: darkCard),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black.withOpacity(0.5),
      iconTheme: const IconThemeData(color: darkText),
      titleTextStyle: _textTheme(darkText).headlineSmall,
    ),
    inputDecorationTheme: _inputDecorationTheme.copyWith(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkPrimary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.white,
        textStyle: _textTheme(Colors.white).labelLarge,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        elevation: 1,
      ),
    ),
  );
}