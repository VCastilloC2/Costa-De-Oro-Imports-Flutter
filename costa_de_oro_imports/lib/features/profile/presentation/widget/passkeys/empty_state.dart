import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';

class EmptyKeys extends StatelessWidget {
  final double s;
  const EmptyKeys({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Toca "Activar con mi huella".',
      'Confirma con tu huella en la ventana de tu teléfono.',
      'Listo: la próxima vez entras sin contraseña.',
    ];

    return CustomPaint(
      painter: _DashedBorderPainter(color: AppColors.gold.withValues(alpha: 0.5), radius: 24 * s),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20 * s, 26 * s, 20 * s, 22 * s),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(24 * s),
        ),
        child: Column(
          children: [
            _PulseSlot(s: s),
            SizedBox(height: 16 * s),
            Text('Tu primera llave te espera', textAlign: TextAlign.center, style: AppFonts.style(size: 16 * s, weight: FontWeight.w800, color: AppColors.brownDark)),
            SizedBox(height: 4 * s),
            Text('Tarda menos de 10 segundos.', style: AppFonts.style(size: 13 * s, color: AppColors.muted)),
            SizedBox(height: 20 * s),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 12 * s),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24 * s,
                      height: 24 * s,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.goldLight.withValues(alpha: 0.3)),
                      child: Text('${i + 1}', style: AppFonts.style(size: 12 * s, weight: FontWeight.w800, color: AppColors.goldDark)),
                    ),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 2 * s),
                        child: Text(steps[i], style: AppFonts.style(size: 13.5 * s, weight: FontWeight.w500, color: AppColors.brown, height: 1.35)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulseSlot extends StatefulWidget {
  final double s;
  const _PulseSlot({required this.s});

  @override
  State<_PulseSlot> createState() => _PulseSlotState();
}

class _PulseSlotState extends State<_PulseSlot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final box = 84 * s;

    return SizedBox(
      width: box,
      height: box,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.7 + 0.3 * t,
                child: Container(
                  width: box,
                  height: box,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold.withValues(alpha: (1 - t) * 0.5), width: 1.6),
                  ),
                ),
              ),
              Container(
                width: 58 * s,
                height: 58 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1.5),
                  boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.18), blurRadius: 14)],
                ),
                child: Icon(Icons.add_rounded, size: 28 * s, color: AppColors.goldDark),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.4;

    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 7, metric.length)), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color || old.radius != radius;
}