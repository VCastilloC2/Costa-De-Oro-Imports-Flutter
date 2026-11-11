// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: StatCard
// ============================================================================
// Tarjeta reutilizable para mostrar estadísticas rápidas (Compras, Clientes).
// Recibe sus datos y su icono a través del constructor.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';

class StatCard extends StatelessWidget {
  final double s;
  final String title;
  final String value;
  final String highlight;
  final String subtitle;
  final List<List<dynamic>> icon;
  final Color iconBg;

  const StatCard({
    super.key,
    required this.s,
    required this.title,
    required this.value,
    required this.highlight,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * s),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppFonts.style(size: 13 * s, weight: FontWeight.w600, color: AppColors.brownDark)),
              Container(
                width: 34 * s, height: 34 * s,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: HugeIcon(icon: icon, color: AppColors.brownDark, size: 16 * s, strokeWidth: 2.0),
              ),
            ],
          ),
          SizedBox(height: 6 * s),
          Text(value, style: AppFonts.style(size: 23 * s, weight: FontWeight.w800, color: AppColors.brownDark)),
          SizedBox(height: 2 * s),
          // Usamos Text.rich para resaltar el porcentaje de crecimiento.
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: highlight, style: AppFonts.style(size: 10.5 * s, weight: FontWeight.w800, color: AppColors.brownDark)),
                TextSpan(text: subtitle, style: AppFonts.style(size: 10.5 * s, weight: FontWeight.w500, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}