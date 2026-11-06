import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';

/// Tarjeta de encabezado: avatar con iniciales dentro de un anillo que se
/// llena según el avance del perfil, y un mensaje de cuánto falta.
class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.progress,
    required this.remaining,
    required this.firstName,
    required this.initials,
  });

  /// 0 a 1.
  final double progress;

  /// Cuántos datos faltan.
  final int remaining;
  final String firstName;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final complete = remaining == 0;
    final title = firstName.isEmpty ? 'Tu perfil' : 'Hola, $firstName';
    final subtitle = complete
        ? '¡Listo! Tu perfil está completo.'
        : (remaining == 1
            ? 'Te falta 1 dato para completar tu perfil.'
            : 'Te faltan $remaining datos para completar tu perfil.');

    return Semantics(
      label: 'Perfil completo al $percent por ciento',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E130C), AppColors.brown, Color(0xFFD4AF37)],
            stops: [0.0, 0.8, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E130C).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return SizedBox(
                  width: 82,
                  height: 82,
                  child: CustomPaint(
                    painter: _RingPainter(value),
                    child: Center(
                      child: initials.isEmpty
                          ? const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.creamText,
                              size: 32,
                            )
                          : Text(
                              initials,
                              style: AppFonts.style(
                                size: 24,
                                weight: FontWeight.w800,
                                color: AppColors.creamText,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.style(
                      size: 21,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: AppFonts.style(
                      size: 13.5,
                      weight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          complete
                              ? Icons.verified_rounded
                              : Icons.timelapse_rounded,
                          size: 15,
                          color: AppColors.goldLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$percent% completo',
                          style: AppFonts.style(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;

    // Pista
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.16),
    );

    if (progress <= 0) return;

    // Avance (empieza arriba y gira en el sentido del reloj)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = AppColors.goldLight,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}