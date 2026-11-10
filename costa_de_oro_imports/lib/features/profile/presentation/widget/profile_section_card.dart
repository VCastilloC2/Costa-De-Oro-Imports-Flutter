// RAMA: feature/Profile
// ============================================================================
// WIDGET: ProfileSectionCard
// ============================================================================
// Tarjeta de sección con estado "Completo" o "Faltan X datos".
// Utiliza Hugeicons y diseño responsivo. El icono está centrado y con un
// grosor de trazo estandarizado (2.0) para mantener la consistencia.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/responsive_utils.dart';

class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.listenable,
    required this.missingCount,
    required this.children,
    this.footer,
  });

  final List<List<dynamic>> icon;
  final String title;
  final Listenable listenable;
  final int Function() missingCount;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34 * s, 
              height: 34 * s, 
              alignment: Alignment.center, // Centra el icono perfectamente
              decoration: BoxDecoration(
                color: AppColors.brownDark, 
                borderRadius: BorderRadius.circular(10 * s)
              ),
              child: HugeIcon(
                icon: icon, 
                size: 18 * s, 
                color: AppColors.goldLight, 
                strokeWidth: 2.0
              ),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Text(
                title, 
                style: AppFonts.style(size: 16 * s, weight: FontWeight.w700, color: AppColors.brownDark)
              )
            ),
            SizedBox(width: 8 * s),
            ListenableBuilder(
              listenable: listenable,
              builder: (context, _) => _StatusChip(missing: missingCount(), s: s),
            ),
          ],
        ),
        SizedBox(height: 16 * s),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: 12 * s),
          children[i],
        ],
        if (footer != null) ...[
          SizedBox(height: 14 * s),
          footer!,
        ],
      ],
    );

    return ListenableBuilder(
      listenable: listenable,
      child: content,
      builder: (context, child) {
        final pending = missingCount() > 0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          padding: EdgeInsets.all(18 * s),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24 * s),
            border: Border.all(
              color: pending ? AppColors.goldDark.withValues(alpha: 0.5) : Colors.transparent, 
              width: 1.5
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 5))
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.missing, required this.s});

  final int missing;
  final double s;

  @override
  Widget build(BuildContext context) {
    final done = missing == 0;
    final label = done ? 'Completo' : (missing == 1 ? 'Falta 1 dato' : 'Faltan $missing datos');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        color: done ? AppColors.goldDark.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: done ? Colors.transparent : AppColors.goldDark.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done)
            HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, size: 14 * s, color: AppColors.goldDark, strokeWidth: 2.0)
          else
            Container(width: 7 * s, height: 7 * s, decoration: const BoxDecoration(color: AppColors.goldDark, shape: BoxShape.circle)),
          SizedBox(width: 5 * s),
          Text(label, style: AppFonts.style(size: 12 * s, weight: FontWeight.w700, color: AppColors.brown)),
        ],
      ),
    );
  }
}