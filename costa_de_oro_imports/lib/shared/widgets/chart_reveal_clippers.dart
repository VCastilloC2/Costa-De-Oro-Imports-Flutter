import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Recorte que avanza de izquierda a derecha según [progress] (0 a 1).
/// Con 0 no se ve nada; con 1 se ve todo, con un pequeño margen para no cortar
/// el borde de los puntos de la gráfica.
class SweepClipper extends CustomClipper<Rect> {
  SweepClipper(this.progress);

  final double progress;
  static const _margin = 16.0;

  @override
  Rect getClip(Size size) {
    if (progress <= 0) {
      return Rect.zero;
    }
    final right = progress >= 1 ? size.width + _margin : size.width * progress;
    return Rect.fromLTRB(-_margin, -_margin, right, size.height + _margin);
  }

  @override
  bool shouldReclip(covariant SweepClipper oldClipper) =>
      oldClipper.progress != progress;
}

/// Recorte en forma de "barrido de reloj": una cuña que gira en el sentido de
/// las manecillas desde [startDegrees] (0 = las 3 en punto, igual que
/// `startDegreeOffset` de fl_chart) hasta completar la vuelta.
class DonutSweepClipper extends CustomClipper<Path> {
  DonutSweepClipper(this.progress, this.startDegrees);

  final double progress;
  final double startDegrees;

  @override
  Path getClip(Size size) {
    if (progress <= 0) {
      return Path();
    }
    if (progress >= 1) {
      return Path()..addRect(Offset.zero & size);
    }
    final center = size.center(Offset.zero);
    return Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: size.longestSide),
        startDegrees * math.pi / 180,
        2 * math.pi * progress,
        false,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant DonutSweepClipper oldClipper) =>
      oldClipper.progress != progress ||
      oldClipper.startDegrees != startDegrees;
}
