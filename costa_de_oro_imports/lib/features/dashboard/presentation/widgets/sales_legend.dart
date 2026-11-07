import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../app/theme/app_spacing.dart';

/// Punto de color + texto, para leyendas de gráficas.
class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: color),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

/// Fila de la leyenda de la dona: nombre, valor y porcentaje.
class SalesLegendRow extends StatelessWidget {
  const SalesLegendRow({
    super.key,
    required this.color,
    required this.title,
    required this.value,
    required this.percent,
  });

  final Color color;
  final String title;
  final String value;
  final String percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Dot(color: color, size: 9),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.style(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.brownDark,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          value,
          style: AppFonts.style(size: 12, color: AppColors.brownDark),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(percent, style: AppTextStyles.caption),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
