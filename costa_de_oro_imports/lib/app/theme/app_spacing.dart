import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Escala de espaciado (múltiplos de 4). Usar estos valores en lugar de
/// números sueltos mantiene el ritmo visual igual en todas las pantallas.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  /// Margen lateral de las pantallas.
  static const double page = md;

  /// Ancho máximo del contenido. En tablet o web el contenido queda centrado
  /// en lugar de estirarse a todo el ancho.
  static const double maxContentWidth = 560;
}

/// Radios de borde.
class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 30;

  static BorderRadius get card => BorderRadius.circular(xl);
}

/// Sombras.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Duraciones de animación.
class AppDurations {
  AppDurations._();

  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 600);
}
