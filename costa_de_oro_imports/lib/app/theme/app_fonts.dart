import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografía central del proyecto. Para cambiarla, solo modifica [family].
class AppFonts {
  AppFonts._();

  /// Única familia tipográfica de la app (también la usa el tema).
  static String? get family => GoogleFonts.geist().fontFamily;

  static TextStyle style({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.geist(
      fontSize: size, // tamanio
      fontWeight: weight, // ancho
      color: color, // color
      height: height, // altura
      letterSpacing: letterSpacing, // espacio de las letras
    );
  }
}

/// Escala tipográfica con nombre. Preferir estos estilos a tamaños sueltos
/// para que los títulos, cifras y textos se vean igual en toda la app.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display =>
      AppFonts.style(size: 30, weight: FontWeight.w800, color: _ink);

  static TextStyle get headline =>
      AppFonts.style(size: 24, weight: FontWeight.w700, color: _ink);

  static TextStyle get title =>
      AppFonts.style(size: 18, weight: FontWeight.w700, color: _ink);

  static TextStyle get cardTitle =>
      AppFonts.style(size: 15, weight: FontWeight.w600, color: _ink);

  static TextStyle get metric =>
      AppFonts.style(size: 23, weight: FontWeight.w800, color: _ink);

  static TextStyle get body =>
      AppFonts.style(size: 14, weight: FontWeight.w500, color: _ink);

  static TextStyle get bodySmall =>
      AppFonts.style(size: 12, weight: FontWeight.w500, color: AppColors.muted);

  static TextStyle get caption =>
      AppFonts.style(size: 11, color: AppColors.muted);

  static TextStyle get button =>
      AppFonts.style(size: 15, weight: FontWeight.w600, color: Colors.white);

  static const _ink = AppColors.textPrimary;
}
