import 'package:flutter/material.dart';

/// Paleta de la app. Ningún widget debe escribir `Color(0x...)` por su cuenta:
/// si falta un color, se agrega aquí con un nombre que diga para qué sirve.
class AppColors {
  AppColors._();

  // --- Marca -----------------------------------------------------------------
  static const brown = Color(0xFF5A3E2B);
  static const brownDark = Color(0xFF2E1D11);
  static const brownButtonText = Color(0xFF3B2718);
  static const gold = Color(0xFFC8963E);
  static const goldLight = Color(0xFFE3B965);
  static const goldDark = Color(0xFFB07D2B);
  static const metallicGold = Color(0xFFD4AF37);
  static const amber = Color(0xFFFFC107);
  static const amberLight = Color(0xFFFFE066);
  static const caramel = Color(0xFF8A5A12);
  static const beige = Color(0xFFEFD3AE);
  static const navy = Color(0xFF1F3A5F);

  /// Fondo oscuro de la marca (tarjeta del logo, intro y cargas).
  static const ink = Color(0xFF14100C);
  static const inkSoft = Color(0xFF1E130C);

  // --- Superficies -----------------------------------------------------------
  static const cream = Color(0xFFFFFAF1);
  static const creamDark = Color(0xFFF8E8CE);
  static const creamSplashEnd = Color(0xFFF1D9B5);
  static const creamText = Color(0xFFFFF4E0);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFF9F6F0);
  static const surfaceSubtle = Color(0xFFF2ECE2);
  static const divider = Color(0xFFF0F0F0);
  static const border = Color(0xFFE6D6BC);

  // --- Texto -----------------------------------------------------------------
  static const textPrimary = brownDark;
  static const muted = Color(0xFF9A8264);

  // --- Estados ---------------------------------------------------------------
  static const success = Color(0xFF2E9E4F);
  static const warning = Color(0xFFF5B800);
  static const error = Color(0xFFD64545);
  static const errorLight = Color(0xFFFF8A80);
  static const info = Color(0xFF1E88E5);

  // Se mantienen por compatibilidad con pantallas existentes.
  static const blue = Color(0xFF0A8FFF);
  static const green = Color(0xFF3FB950);
  static const yellow = warning;
  static const red = Color(0xFFE5484D);

  // --- Fondos suaves para íconos ----------------------------------------------
  static const tintRose = Color(0xFFFAD4D8);
  static const tintAmber = Color(0xFFFFF0B3);
  static const tintBlue = Color(0xFFD6E8FB);
  static const tintGreen = Color(0xFFDDEBD8);

  // --- Degradados --------------------------------------------------------------
  static const bannerGradient = [Color(0xFFFBF1E0), Color(0xFFF6D8AA)];

  // --- Gráficas (en orden de uso para series) ----------------------------------
  static const chartPalette = [success, warning, info, red, gold, navy];

  // --- Skeleton de carga -------------------------------------------------------
  static const skeletonBase = Color(0xFFE9DFD0);
  static const skeletonHighlight = Color(0xFFFFF9EF);

  /// Sombra estándar de las tarjetas.
  static Color get shadow => Colors.black.withValues(alpha: 0.04);
}
