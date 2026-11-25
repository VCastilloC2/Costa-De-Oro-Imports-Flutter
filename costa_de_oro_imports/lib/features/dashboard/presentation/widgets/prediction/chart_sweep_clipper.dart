import 'package:flutter/rendering.dart';

/// Revela el contenido de una gráfica con un barrido horizontal.
///
/// [progress] se espera en el intervalo de cero a uno y determina el borde
/// derecho del recorte. El margen evita cortar trazos que llegan al límite del
/// área de dibujo.
class ChartSweepClipper extends CustomClipper<Rect> {
  /// Crea un recorte para el avance actual de la animación.
  const ChartSweepClipper(this.progress);

  /// Progreso normalizado del barrido horizontal.
  final double progress;
  static const _margin = 16.0;

  @override
  Rect getClip(Size size) {
    if (progress <= 0) return Rect.zero;
    final right = progress >= 1 ? size.width + _margin : size.width * progress;
    return Rect.fromLTRB(-_margin, -_margin, right, size.height + _margin);
  }

  @override
  bool shouldReclip(covariant ChartSweepClipper oldClipper) =>
      oldClipper.progress != progress;
}
