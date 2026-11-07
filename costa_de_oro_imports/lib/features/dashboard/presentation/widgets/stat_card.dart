import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';

/// Tarjeta de una métrica: título, cifra principal y un detalle.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
    this.highlight,
    this.detail,
    this.large = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconBackground;

  /// Parte del detalle en negrita (por ejemplo, un número).
  final String? highlight;
  final String? detail;

  /// Versión grande para la cifra principal del panel.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final highlight = this.highlight;
    final detail = this.detail;

    return Semantics(
      container: true,
      label: [title, value, ?highlight, ?detail].join(', '),
      excludeSemantics: true,
      child: AppCard(
        padding: EdgeInsets.all(large ? AppSpacing.lg : AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: large
                        ? AppTextStyles.cardTitle
                        : AppFonts.style(
                            size: 13,
                            weight: FontWeight.w600,
                            color: AppColors.brownDark,
                          ),
                  ),
                ),
                IconBadge(
                  icon: icon,
                  background: iconBackground,
                  size: large ? 38 : 34,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // Las cifras largas se reducen en vez de desbordar la tarjeta.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: large ? AppTextStyles.display : AppTextStyles.metric,
              ),
            ),
            if (highlight != null || detail != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text.rich(
                TextSpan(
                  children: [
                    if (highlight != null)
                      TextSpan(
                        text: highlight,
                        style: AppFonts.style(
                          size: 12,
                          weight: FontWeight.w800,
                          color: AppColors.brownDark,
                        ),
                      ),
                    if (detail != null)
                      TextSpan(text: detail, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
