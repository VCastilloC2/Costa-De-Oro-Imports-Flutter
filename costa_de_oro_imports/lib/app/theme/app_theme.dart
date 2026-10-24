import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  /// Familia tipográfica Outfit, guardada aparte para reutilizarla
  /// en el estilo de los botones.
  static final String? _font = GoogleFonts.outfit().fontFamily;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: _font,
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          primary: AppColors.brown,
          surface: Colors.white,
          onSurface: AppColors.brownDark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.gold, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brown,
            foregroundColor: AppColors.cream,
            minimumSize: const Size.fromHeight(56),
            shape: const StadiumBorder(),
            textStyle: TextStyle(
              fontFamily: _font,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brown,
            minimumSize: const Size.fromHeight(56),
            side: const BorderSide(color: AppColors.border, width: 1.5),
            shape: const StadiumBorder(),
            textStyle: TextStyle(
              fontFamily: _font,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}