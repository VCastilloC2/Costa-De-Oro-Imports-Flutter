import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Escena de carga: una botella de licor (derecha) se inclina y vierte su
/// contenido en un vaso (izquierda). Todo depende de [progress] (0 a 1):
///
///   0.00 - 0.10  la botella se levanta y se inclina hacia el vaso
///   0.10 - 0.96  sale el chorro: la botella se vacía y el vaso se llena
///   0.96 - 1.00  el chorro se corta y la botella vuelve a su sitio
///
/// El líquido de la botella se calcula con volumen real: la superficie siempre
/// queda horizontal y la botella se inclina justo lo necesario para que el
/// licor llegue a la boca, como en la vida real.
class LiquorPourLoader extends StatefulWidget {
  const LiquorPourLoader({super.key, required this.progress, this.width = 300});

  /// 0 = botella llena y vaso vacío, 1 = vaso lleno.
  final double progress;

  /// Ancho de toda la escena. El alto es 1,2 veces el ancho.
  final double width;

  @override
  State<LiquorPourLoader> createState() => _LiquorPourLoaderState();
}

class _LiquorPourLoaderState extends State<LiquorPourLoader>
    with SingleTickerProviderStateMixin {
  // Movimiento continuo de olas, burbujas y ondas del chorro.
  late final AnimationController _t;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _t = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) _t.repeat();
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: 'Cargando',
      value: '${(widget.progress * 100).round()} por ciento',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: widget.progress.clamp(0.0, 1.0)),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, p, _) {
          return AnimatedBuilder(
            animation: _t,
            builder: (context, _) {
              return CustomPaint(
                size: Size(widget.width, widget.width * 1.2),
                painter: _PourPainter(
                  progress: p,
                  phase: _t.value * 2 * math.pi,
                  animate: !reduce,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Constantes de la animación
// ---------------------------------------------------------------------------

const double _pourStart = 0.10; // aquí termina de inclinarse y empieza a verter
const double _pourEnd = 0.90; // aquí se corta el chorro
const double _fFull = 0.80; // la botella empieza llena al 80 % de su volumen
const double _fEmpty = 0.22; // y termina con un 22 % (se ve que queda un poco)
const double _maxTilt = 135 * math.pi / 180; // inclinación máxima

// Medidas de la botella (en fracciones del ancho de la escena)
const double _lipHalf = 0.034;
const double _neckHalf = 0.026;
const double _bodyHalf = 0.092;
const double _cornerR = 0.030;

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _smooth(double t) => t * t * (3 - 2 * t);

Offset _rot(Offset q, double a) {
  final c = math.cos(a);
  final s = math.sin(a);
  return Offset(q.dx * c - q.dy * s, q.dx * s + q.dy * c);
}

// ---------------------------------------------------------------------------
// Geometría: polígonos, área y recorte (para el volumen real del líquido)
// ---------------------------------------------------------------------------

/// Contorno de la botella con la boca en (0,0) y el cuerpo hacia +y.
List<Offset> _bottlePolygon(double w, double len) {
  const n = 90;
  final lip = _lipHalf * w;
  final neck = _neckHalf * w;
  final body = _bodyHalf * w;
  final rb = _cornerR * w;

  double halfWidth(double y) {
    if (y < 0.035 * len) return lip;
    if (y < 0.30 * len) return neck;
    if (y < 0.44 * len) {
      final t = (y - 0.30 * len) / (0.14 * len);
      return neck + (body - neck) * _smooth(t);
    }
    if (y < len - rb) return body;
    final d = y - (len - rb);
    return body - rb + math.sqrt(math.max(0.0, rb * rb - d * d));
  }

  final right = <Offset>[];
  final left = <Offset>[];
  for (var i = 0; i <= n; i++) {
    final y = len * i / n;
    final h = halfWidth(y);
    right.add(Offset(h, y));
    left.add(Offset(-h, y));
  }
  return [...right, ...left.reversed];
}

double _area(List<Offset> p) {
  if (p.length < 3) return 0;
  var s = 0.0;
  for (var i = 0; i < p.length; i++) {
    final a = p[i];
    final b = p[(i + 1) % p.length];
    s += a.dx * b.dy - b.dx * a.dy;
  }
  return s.abs() / 2;
}

/// Parte del polígono que queda por debajo de la línea horizontal [y]
/// (en pantalla "abajo" es y mayor). Es el recorte de Sutherland-Hodgman.
List<Offset> _clipBelow(List<Offset> poly, double y) {
  final out = <Offset>[];
  for (var i = 0; i < poly.length; i++) {
    final a = poly[i];
    final b = poly[(i + 1) % poly.length];
    final aIn = a.dy >= y;
    final bIn = b.dy >= y;
    if (aIn) out.add(a);
    if (aIn != bIn) {
      final t = (y - a.dy) / (b.dy - a.dy);
      out.add(Offset(a.dx + (b.dx - a.dx) * t, y));
    }
  }
  return out;
}

/// Altura (y) de la superficie horizontal para que el líquido ocupe [vol].
double _levelForVolume(List<Offset> poly, double vol) {
  var lo = poly.map((q) => q.dy).reduce(math.min);
  var hi = poly.map((q) => q.dy).reduce(math.max);
  for (var i = 0; i < 24; i++) {
    final mid = (lo + hi) / 2;
    if (_area(_clipBelow(poly, mid)) > vol) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

/// Ángulo mínimo para que el líquido [vol] llegue justo a la boca.
double _solveTilt(List<Offset> local, double vol) {
  var lo = 0.0;
  var hi = _maxTilt;
  for (var i = 0; i < 22; i++) {
    final mid = (lo + hi) / 2;
    final poly = [for (final q in local) _rot(q, -mid)];
    // Volumen que queda por debajo de la línea de la boca (y = 0)
    if (_area(_clipBelow(poly, 0)) > vol) {
      lo = mid; // todavía cabe: hay que inclinar más
    } else {
      hi = mid;
    }
  }
  return hi;
}

/// Contorno del vaso (tipo "rocks") dentro del rectángulo [r].
Path _glassPath(Rect r) {
  final rad = r.width * 0.06;
  double x(double u) => r.left + r.width * u;
  return Path()
    ..moveTo(x(0), r.top)
    ..lineTo(x(1), r.top)
    ..lineTo(x(0.9), r.bottom - rad)
    ..quadraticBezierTo(x(0.9), r.bottom, x(0.9) - rad, r.bottom)
    ..lineTo(x(0.1) + rad, r.bottom)
    ..quadraticBezierTo(x(0.1), r.bottom, x(0.1), r.bottom - rad)
    ..close();
}

// ---------------------------------------------------------------------------
// Pintor
// ---------------------------------------------------------------------------

class _PourPainter extends CustomPainter {
  _PourPainter({
    required this.progress,
    required this.phase,
    required this.animate,
  });

  final double progress; // 0 a 1
  final double phase; // 0 a 2π
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = progress.clamp(0.0, 1.0);

    // --- Fases de la animación ---------------------------------------
    final g = ((p - _pourStart) / (_pourEnd - _pourStart)).clamp(0.0, 1.0);
    final tIn = _smooth((p / _pourStart).clamp(0.0, 1.0));
    final tOut = _smooth(((p - _pourEnd) / (1 - _pourEnd)).clamp(0.0, 1.0));
    final e = tIn * (1 - tOut); // 0 = botella de pie, 1 = vertiendo
    final bottleFill = _lerp(_fFull, _fEmpty, g);
    final strength = math.min(
      ((p - _pourStart) / 0.03).clamp(0.0, 1.0),
      ((_pourEnd - p) / 0.03).clamp(0.0, 1.0),
    );

    // --- Disposición de la escena ------------------------------------
    final glassRect = Rect.fromLTWH(w * 0.03, h * 0.62, w * 0.40, h * 0.33);
    final tableY = glassRect.bottom;
    final len = w * 0.50; // largo de la botella
    final restMouth = Offset(w * 0.78, tableY - len); // botella de pie
    final pourMouth = Offset(w * 0.38, w * 0.58); // boca sobre el vaso

    // Mesa
    canvas.drawLine(
      Offset(w * 0.02, tableY + 3),
      Offset(w * 0.98, tableY + 3),
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.12),
    );

    // --- VASO ----------------------------------------------------------
    final glass = _glassPath(glassRect);

    if (p >= 0.999) {
      canvas.drawPath(
        glass,
        Paint()
          ..color = AppColors.goldLight.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    canvas.drawPath(
      glass,
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );

    // Líquido del vaso
    final baseY = glassRect.bottom - glassRect.height * 0.03;
    final usable = glassRect.height * 0.90;
    final liquidTop = baseY - usable * g;

    if (g > 0.002) {
      canvas.save();
      canvas.clipPath(glass);

      final amp = animate ? h * 0.010 * (1 - g * 0.5) : 0.0;

      Path wave(double ph, double a, double yOffset) {
        final path = Path()
          ..moveTo(glassRect.left, glassRect.bottom + 2)
          ..lineTo(glassRect.left, liquidTop + yOffset);
        for (double x = glassRect.left; x <= glassRect.right; x += 4) {
          path.lineTo(
            x,
            liquidTop +
                yOffset +
                math.sin(
                      (x - glassRect.left) /
                              glassRect.width *
                              2 *
                              math.pi *
                              1.3 +
                          ph,
                    ) *
                    a,
          );
        }
        path
          ..lineTo(glassRect.right, glassRect.bottom + 2)
          ..close();
        return path;
      }

      canvas.drawPath(
        wave(phase + 1.6, amp, -h * 0.006),
        Paint()..color = AppColors.goldLight.withValues(alpha: 0.55),
      );

      final liquidRect = Rect.fromLTRB(
        glassRect.left,
        liquidTop - 10,
        glassRect.right,
        glassRect.bottom,
      );
      canvas.drawPath(
        wave(phase, amp, 0),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.goldLight, AppColors.gold, Color(0xFF8A5A12)],
          ).createShader(liquidRect),
      );

      // Burbujas
      if (animate && g > 0.05) {
        final bubble = Paint()..color = Colors.white.withValues(alpha: 0.35);
        for (var i = 0; i < 7; i++) {
          final seed = i * 0.6180339;
          final x =
              glassRect.left + glassRect.width * (0.30 + 0.40 * (seed % 1));
          final speed = 1 + (i % 3);
          final k = (phase / (2 * math.pi) * speed + seed) % 1;
          final y = baseY - (baseY - liquidTop) * k;
          if (y < liquidTop + 6) continue;
          canvas.drawCircle(
            Offset(x + math.sin(k * 8 + i) * 3, y),
            1.8 + (i % 3),
            bubble,
          );
        }
      }
      canvas.restore();
    }

    // --- BOTELLA -------------------------------------------------------
    final local = _bottlePolygon(w, len);
    final totalArea = _area(local);
    final vol = bottleFill * totalArea;

    // Inclinación: la justa para que el licor llegue a la boca (+3° de margen)
    final solved = math.min(_solveTilt(local, vol) + 0.05, _maxTilt);
    final tilt = e * solved;
    final a = -tilt; // negativo = hacia la izquierda
    final mouth = Offset.lerp(restMouth, pourMouth, e)!;

    final world = [for (final q in local) mouth + _rot(q, a)];
    final bottlePath = Path()..addPolygon(world, true);

    // Cristal de la botella
    canvas.drawPath(
      bottlePath,
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );

    // Licor dentro de la botella (superficie siempre horizontal)
    final level = _levelForVolume(world, vol);
    final liquidPoly = _clipBelow(world, level);
    if (liquidPoly.length >= 3) {
      final lp = Path()..addPolygon(liquidPoly, true);
      canvas.drawPath(
        lp,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.goldLight, AppColors.gold, Color(0xFF8A5A12)],
          ).createShader(lp.getBounds()),
      );

      // Línea brillante en la superficie
      final surf = liquidPoly
          .where((q) => (q.dy - level).abs() < 0.01)
          .toList();
      if (surf.length >= 2) {
        canvas.drawLine(
          surf.first,
          surf.last,
          Paint()
            ..strokeWidth = 1.5
            ..color = AppColors.goldLight.withValues(alpha: 0.9),
        );
      }
    }

    // Etiqueta y reflejo (se dibujan en el sistema de la botella)
    canvas.save();
    canvas.translate(mouth.dx, mouth.dy);
    canvas.rotate(a);
    final body = _bodyHalf * w;

    canvas.drawRRect(
      RRect.fromLTRBR(
        -body * 0.98,
        0.58 * len,
        body * 0.98,
        0.80 * len,
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.creamText.withValues(alpha: 0.88),
    );
    final stripe = Paint()
      ..strokeWidth = 2
      ..color = AppColors.gold;
    canvas.drawLine(
      Offset(-body * 0.98, 0.62 * len),
      Offset(body * 0.98, 0.62 * len),
      stripe,
    );
    canvas.drawLine(
      Offset(-body * 0.98, 0.76 * len),
      Offset(body * 0.98, 0.76 * len),
      stripe,
    );
    canvas.drawLine(
      Offset(-body * 0.70, 0.46 * len),
      Offset(-body * 0.70, 0.54 * len),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.30),
    );
    canvas.restore();

    // Contorno de la botella
    canvas.drawPath(
      bottlePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.85),
    );

    // --- CHORRO --------------------------------------------------------
    if (strength > 0 && liquidTop > mouth.dy) {
      final yLand = liquidTop;
      double xAt(double y) => mouth.dx - 0.18 * math.sqrt((y - mouth.dy) * w);

      final stream = Path()..moveTo(mouth.dx, mouth.dy);
      const n = 28;
      for (var i = 1; i <= n; i++) {
        final y = mouth.dy + (yLand - mouth.dy) * i / n;
        stream.lineTo(xAt(y), y);
      }
      final sw = w * 0.022 * strength;
      canvas.drawPath(
        stream,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = AppColors.gold,
      );
      canvas.drawPath(
        stream,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw * 0.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = AppColors.goldLight.withValues(alpha: 0.8),
      );

      // Ondas donde cae el chorro
      if (animate) {
        final xLand = xAt(yLand);
        for (var k = 0; k < 2; k++) {
          final t = (phase / (2 * math.pi) * 2 + k * 0.5) % 1;
          final rx = w * (0.03 + 0.05 * t);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(xLand, yLand),
              width: rx * 2,
              height: rx * 0.7,
            ),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = AppColors.goldLight.withValues(
                alpha: 0.5 * (1 - t) * strength,
              ),
          );
        }
      }
    }

    // --- CONTORNO Y REFLEJOS DEL VASO ---------------------------------
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.85),
    );

    canvas.drawPath(
      Path()
        ..moveTo(
          glassRect.left + glassRect.width * 0.12,
          glassRect.top + glassRect.height * 0.12,
        )
        ..lineTo(
          glassRect.left + glassRect.width * 0.20,
          glassRect.top + glassRect.height * 0.78,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.28),
    );

    canvas.drawLine(
      Offset(
        glassRect.left + glassRect.width * 0.22,
        glassRect.bottom - glassRect.height * 0.10,
      ),
      Offset(
        glassRect.left + glassRect.width * 0.78,
        glassRect.bottom - glassRect.height * 0.10,
      ),
      Paint()
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant _PourPainter old) =>
      old.progress != progress || old.phase != phase || old.animate != animate;
}
