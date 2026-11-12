// RAMA: feature/Profile
// ============================================================================
// WIDGET: AccountDetailsTopBar
// ============================================================================
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';

const Color _kSheet = Color(0xFFF9F6F0);

class AccountDetailsTopBar extends StatelessWidget {
  const AccountDetailsTopBar({
    super.key,
    required this.s,
    required this.top,
    required this.t,
    required this.onBack,
    required this.onEdit,
  });

  final double s;
  final double top;
  final double t;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final fg = Color.lerp(AppColors.creamText, AppColors.brownDark, t)!;
    final accent = Color.lerp(AppColors.goldLight, AppColors.goldDark, t)!;
    final btnBg = Color.lerp(Colors.white.withValues(alpha: 0.14), Colors.white, t)!;
    final btnBorder = Color.lerp(
      Colors.white.withValues(alpha: 0.22),
      AppColors.border,
      t,
    )!;

    return Container(
      height: top + kToolbarHeight,
      padding: EdgeInsets.only(top: top),
      decoration: BoxDecoration(
        color: _kSheet.withValues(alpha: 0.96 * t),
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: t)),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Detalles de la cuenta',
            style: AppFonts.style(size: 18 * s, weight: FontWeight.w700, color: fg),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 16 * s),
              child: IconButton(
                tooltip: 'Volver',
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: fg,
                  size: 20,
                  strokeWidth: 2.0,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: btnBg,
                  side: BorderSide(color: btnBorder),
                  shape: const CircleBorder(),
                ),
                onPressed: onBack,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 8 * s),
              child: TextButton(
                onPressed: onEdit,
                child: Text(
                  'Editar',
                  style: AppFonts.style(
                    size: 16 * s,
                    weight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}