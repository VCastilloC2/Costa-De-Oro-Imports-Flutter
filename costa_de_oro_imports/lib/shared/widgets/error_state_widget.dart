import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';
import '../../app/theme/app_spacing.dart';

/// Pantalla o sección de error con un mensaje claro y la opción de reintentar.
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onAction,
    this.actionLabel = 'Reintentar',
    this.actionIcon = Icons.refresh_rounded,
    this.icon = Icons.cloud_off_rounded,
  });

  final String message;

  /// Acción principal; por defecto, reintentar.
  final VoidCallback? onAction;
  final String actionLabel;
  final IconData actionIcon;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final onAction = this.onAction;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.creamDark,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: AppColors.brown),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
          if (onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(minimumSize: const Size(160, 48)),
            ),
          ],
        ],
      ),
    );
  }
}
