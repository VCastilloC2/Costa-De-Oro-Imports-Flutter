// RAMA: feature/Profile
// ============================================================================
// WIDGET: ProfileHero
// ============================================================================
// Tarjeta de encabezado con avatar de iniciales y anillo de progreso.
// Utiliza Hugeicons y diseño responsivo.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/responsive_utils.dart';

const String kProfileAvatarHeroTag = 'profile-avatar';

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.progress,
    required this.remaining,
    required this.firstName,
    required this.initials,
  });

  final double progress;
  final int remaining;
  final String firstName;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
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
        padding: EdgeInsets.all(20 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28 * s),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E130C), AppColors.brown]),
          boxShadow: [BoxShadow(color: const Color(0xFF1E130C).withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28 * s),
          gradient: RadialGradient(center: const Alignment(1.0, -1.0), radius: 0.9, colors: [AppColors.goldLight.withValues(alpha: 0.22), AppColors.goldLight.withValues(alpha: 0.0)]),
        ),
        child: Row(
          children: [
            Hero(
              tag: kProfileAvatarHeroTag,
              child: Material(
                type: MaterialType.transparency,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return SizedBox(
                      width: 82 * s, height: 82 * s,
                      child: CustomPaint(
                        painter: _RingPainter(value),
                        child: Center(
                          child: initials.isEmpty
                              ? HugeIcon(icon: HugeIcons.strokeRoundedUser, color: AppColors.creamText, size: 32 * s, strokeWidth: 2.2)
                              : Text(initials, style: AppFonts.style(size: 24 * s, weight: FontWeight.w800, color: AppColors.creamText)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 18 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.style(size: 21 * s, weight: FontWeight.w800, color: Colors.white, height: 1.1)),
                  SizedBox(height: 6 * s),
                  Text(subtitle, style: AppFonts.style(size: 13.5 * s, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85), height: 1.35)),
                  SizedBox(height: 12 * s),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20 * s), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: complete ? HugeIcons.strokeRoundedCheckmarkBadge01 : HugeIcons.strokeRoundedTimer01,
                          size: 15 * s, color: AppColors.goldLight, strokeWidth: 2.2,
                        ),
                        SizedBox(width: 6 * s),
                        Text('$percent% completo', style: AppFonts.style(size: 12.5 * s, weight: FontWeight.w600, color: Colors.white)),
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

    canvas.drawCircle(center, radius, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = Colors.white.withValues(alpha: 0.16));

    if (progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = AppColors.goldLight,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}