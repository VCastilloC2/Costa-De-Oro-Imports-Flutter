import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';

/// Cabecera del panel: título, aviso de compras pendientes y avatar.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.userName,
    required this.pendingPurchases,
    required this.onProfileTap,
  });

  final String userName;
  final int pendingPurchases;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final pendingLabel = pendingPurchases == 1
        ? '1 compra pendiente'
        : '$pendingPurchases compras pendientes';

    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text('Panel de control', style: AppTextStyles.title),
          ),
        ),
        Tooltip(
          message: pendingLabel,
          child: Semantics(
            label: pendingLabel,
            child: Badge.count(
              count: pendingPurchases,
              isLabelVisible: pendingPurchases > 0,
              backgroundColor: AppColors.red,
              child: const _SquareIcon(icon: Icons.notifications_none_rounded),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          button: true,
          label: 'Ver perfil de $userName',
          child: InkResponse(
            onTap: onProfileTap,
            radius: 28,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.beige,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldLight, width: 1.5),
              ),
              alignment: Alignment.center,
              child: ExcludeSemantics(
                child: Text(
                  Formatters.initials(userName),
                  style: AppFonts.style(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.brownDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.brownDark, size: 22),
    );
  }
}
