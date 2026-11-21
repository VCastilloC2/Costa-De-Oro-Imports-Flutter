import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';

class ShieldMedallion extends StatefulWidget {
  final int level;
  final double size;
  final Animation<double> pulse;

  const ShieldMedallion({
    super.key,
    required this.level,
    required this.size,
    required this.pulse,
  });

  @override
  State<ShieldMedallion> createState() => _ShieldMedallionState();
}

class _ShieldMedallionState extends State<ShieldMedallion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final bright = widget.level >= 2;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: widget.level.toDouble()),
        duration: const Duration(milliseconds: 1300),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return AnimatedBuilder(
            animation: Listenable.merge([_breath, widget.pulse]),
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: progress,
                        breath: _breath.value,
                        pulse: widget.pulse.value,
                      ),
                    ),
                  ),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (r) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: bright
                          ? const [AppColors.goldLight, AppColors.gold, AppColors.goldDark]
                          : [
                              AppColors.gold.withValues(alpha: 0.55),
                              AppColors.goldDark.withValues(alpha: 0.45),
                            ],
                    ).createShader(r),
                    child: Icon(
                      Icons.fingerprint,
                      size: size * 0.38,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    right: size * 0.16,
                    bottom: size * 0.16,
                    child: AnimatedScale(
                      scale: bright ? 1 : 0,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      child: Container(
                        width: size * 0.2,
                        height: size * 0.2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.goldLight, AppColors.gold],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: size * 0.13,
                          color: AppColors.brownDark,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.breath, required this.pulse});
  final double progress;
  final double breath;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final unit = size.width / 150;
    final r = size.width * 0.40;

    final haloR = r * 1.3;
    canvas.drawCircle(
      c,
      haloR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.10 + 0.12 * breath),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: haloR)),
    );

    final discR = r * 0.82;
    canvas.drawCircle(
      c,
      discR,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF3B2716), Color(0xFF17100A)],
        ).createShader(Rect.fromCircle(center: c, radius: discR)),
    );
    canvas.drawCircle(
      c,
      discR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * unit
        ..color = AppColors.gold.withValues(alpha: 0.35),
    );

    const gap = 0.32;
    final step = 2 * math.pi / 3;
    final seg = step - gap;
    final rect = Rect.fromCircle(center: c, radius: r);

    for (var i = 0; i < 3; i++) {
      final start = -math.pi / 2 + gap / 2 + i * step;

      canvas.drawArc(
        rect, start, seg, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * unit
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.10),
      );

      final f = (progress - i).clamp(0.0, 1.0);
      if (f > 0) {
        canvas.drawArc(
          rect, start, seg * f, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 9 * unit
            ..strokeCap = StrokeCap.round
            ..color = AppColors.goldLight.withValues(alpha: 0.45)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * unit),
        );
        canvas.drawArc(
          rect, start, seg * f, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5 * unit
            ..strokeCap = StrokeCap.round
            ..color = Color.lerp(AppColors.gold, AppColors.goldLight, f)!,
        );
      }
    }

    if (pulse > 0 && pulse < 1) {
      final e = Curves.easeOutCubic.transform(pulse);
      canvas.drawCircle(
        c,
        r * (1.05 + 0.4 * e),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * unit
          ..color = AppColors.goldLight.withValues(alpha: (1 - pulse) * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.breath != breath || old.pulse != pulse;
}