// RAMA: feature/Profile
// ============================================================================
// VASO DE LICOR ANIMADO (CustomPainter)
// Ubicacion: lib/features/profile/presentation/widget/subscription_glass.dart
// El nivel y el color del licor siguen el scroll de los planes en tiempo real.
// Al deslizar, el liquido "se agita" (olas mas grandes) y luego se calma.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'subscription_plan.dart';

class SubscriptionGlass extends StatelessWidget {
  const SubscriptionGlass({super.key, required this.page, required this.time});

  /// Posicion continua del PageView (0.0 .. 2.0).
  final ValueListenable<double> page;

  /// Reloj que se repite 0..1 (olas y burbujas).
  final Animation<double> time;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GlassPainter(page: page, time: time),
        size: Size.infinite,
      ),
    );
  }
}

class _Bubble {
  const _Bubble(this.x, this.speed, this.size, this.offset);
  final double x;
  final int speed;
  final double size;
  final double offset;
}

final List<_Bubble> _bubbles = () {
  final r = math.Random(11);
  return List<_Bubble>.generate(
    16,
    (i) => _Bubble(
      0.1 + r.nextDouble() * 0.8,
      1 + r.nextInt(3),
      1.6 + r.nextDouble() * 3.2,
      r.nextDouble(),
    ),
  );
}();

class _GlassPainter extends CustomPainter {
  _GlassPainter({required this.page, required this.time})
      : super(repaint: Listenable.merge([page, time]));

  final ValueListenable<double> page;
  final Animation<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = page.value;
    final t = time.value;

    final level = tierLerp(p, (e) => e.fill);
    final liquid = tierColor(p, (e) => e.liquid);
    final deep = tierColor(p, (e) => e.liquidDeep);

    // Agitacion: maxima a mitad de camino entre dos planes.
    final frac = p - p.floorToDouble();
    final slosh = math.sin(math.pi * frac);
    final amp = h * (0.012 + 0.032 * slosh);

    // ---- Resplandor detras del vaso ----
    final glowC = Offset(w / 2, h * 0.55);
    final glowR = w * 0.58;
    canvas.drawCircle(
      glowC,
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [liquid.withValues(alpha: 0.38), liquid.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: glowC, radius: glowR)),
    );

    // ---- Sombra en el piso ----
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.965), width: w * 0.62, height: h * 0.05),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ---- Geometria del vaso ----
    final top = h * 0.06;
    final bottom = h * 0.94;
    final tl = w * 0.12;
    final tr = w * 0.88;
    final bl = w * 0.22;
    final br = w * 0.78;
    final r = w * 0.07;

    final outer = Path()
      ..moveTo(tl, top)
      ..lineTo(bl, bottom - r)
      ..quadraticBezierTo(bl, bottom, bl + r, bottom)
      ..lineTo(br - r, bottom)
      ..quadraticBezierTo(br, bottom, br, bottom - r)
      ..lineTo(tr, top)
      ..close();

    double leftAt(double y) => tl + (bl - tl) * ((y - top) / (bottom - top));
    double rightAt(double y) => tr + (br - tr) * ((y - top) / (bottom - top));

    final wall = w * 0.035;
    final iTop = top + h * 0.02;
    final iBottom = bottom - h * 0.12;

    final inner = Path()
      ..moveTo(leftAt(iTop) + wall, iTop)
      ..lineTo(leftAt(iBottom) + wall, iBottom)
      ..lineTo(rightAt(iBottom) - wall, iBottom)
      ..lineTo(rightAt(iTop) - wall, iTop)
      ..close();

    // ---- Cuerpo de cristal ----
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.42),
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.28),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // ---- Licor ----
    final top0 = iTop + h * 0.04;
    final surface = iBottom - (iBottom - top0) * level;
    final waveLen = w * 0.9;

    double yAt(double x, double phaseMul, double a, double dy) =>
        surface + dy + a * math.sin(2 * math.pi * (x / waveLen) + 2 * math.pi * t * phaseMul);

    Path wavePath(double phaseMul, double a, double dy) {
      final path = Path()..moveTo(0, h);
      for (double x = 0; x <= w + 4; x += 4) {
        path.lineTo(x, yAt(x, phaseMul, a, dy));
      }
      path
        ..lineTo(w + 4, h)
        ..close();
      return path;
    }

    canvas.save();
    canvas.clipPath(inner);

    // Ola trasera
    canvas.drawPath(
      wavePath(-1, amp * 0.9, -amp * 0.5),
      Paint()..color = liquid.withValues(alpha: 0.55),
    );

    // Ola frontal con degradado
    canvas.drawPath(
      wavePath(1, amp, 0),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [liquid, deep],
        ).createShader(Rect.fromLTRB(0, surface - amp, w, iBottom)),
    );

    // Brillo en la superficie
    final line = Path();
    for (double x = 0; x <= w + 4; x += 4) {
      final y = yAt(x, 1, amp, 0);
      if (x == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.55),
    );

    // Burbujas
    for (final b in _bubbles) {
      final tt = (t * b.speed + b.offset) % 1.0;
      final y = iBottom - tt * (iBottom - surface);
      final xl = leftAt(y) + wall + 8;
      final xr = rightAt(y) - wall - 8;
      final x = xl + (xr - xl) * b.x + math.sin(2 * math.pi * (t * b.speed + b.offset) * 2) * w * 0.012;
      final a = (0.55 * (1 - tt * 0.6)).clamp(0.0, 1.0).toDouble();
      canvas.drawCircle(Offset(x, y), b.size, Paint()..color = Colors.white.withValues(alpha: a * 0.35));
      canvas.drawCircle(
        Offset(x, y),
        b.size,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = Colors.white.withValues(alpha: a),
      );
    }
    canvas.restore();

    // ---- Base gruesa de cristal ----
    canvas.save();
    canvas.clipPath(outer);
    canvas.drawRect(
      Rect.fromLTRB(0, iBottom, w, bottom + 2),
      Paint()..color = Colors.white.withValues(alpha: 0.24),
    );
    canvas.restore();

    // ---- Contornos y reflejos ----
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.8),
    );
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.35),
    );
    canvas.drawOval(
      Rect.fromLTRB(tl, top - h * 0.02, tr, top + h * 0.045),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withValues(alpha: 0.7),
    );
    final hy1 = top + h * 0.10;
    final hy2 = top + h * 0.62;
    canvas.drawLine(
      Offset(leftAt(hy1) + wall + 5, hy1),
      Offset(leftAt(hy2) + wall + 5, hy2),
      Paint()
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.38),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassPainter oldDelegate) => false;
}