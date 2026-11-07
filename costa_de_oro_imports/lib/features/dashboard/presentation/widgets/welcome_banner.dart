import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../app/theme/app_spacing.dart';

/// Saludo con el nombre del usuario y un resumen de lo que requiere atención.
class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({
    super.key,
    required this.firstName,
    required this.pendingPurchases,
  });

  final String firstName;
  final int pendingPurchases;

  @override
  Widget build(BuildContext context) {
    final summary = switch (pendingPurchases) {
      0 => 'Todo al día: no tienes compras pendientes.',
      1 => 'Tienes 1 compra pendiente por revisar.',
      _ => 'Tienes $pendingPurchases compras pendientes por revisar.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.bannerGradient,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Bienvenido de nuevo, $firstName!',
            style: AppFonts.style(
              size: 17,
              weight: FontWeight.w700,
              color: AppColors.brownDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            summary,
            style: AppFonts.style(
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.brown.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
