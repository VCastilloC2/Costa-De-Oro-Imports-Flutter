// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: EarningsCard
// ============================================================================
// Tarjeta que muestra las ganancias totales. En el futuro, este valor deberá
// ser inyectado desde la API a través de los parámetros del widget.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';

class EarningsCard extends StatelessWidget {
  final double s;

  const EarningsCard({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18 * s),
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
              Text('Ganancias', style: AppFonts.style(size: 15 * s, weight: FontWeight.w600, color: AppColors.brownDark)),
              Container(
                width: 38 * s, height: 38 * s,
                decoration: const BoxDecoration(color: Color(0xFFFAD4D8), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: HugeIcon(icon: HugeIcons.strokeRoundedMoney01, color: AppColors.brownDark, size: 19 * s, strokeWidth: 2.0),
              ),
            ],
          ),
          SizedBox(height: 6 * s),
          // TODO: Reemplazar por el valor dinámico de la API.
          Text('\$1,589,420', style: AppFonts.style(size: 30 * s, weight: FontWeight.w800, color: AppColors.brownDark)),
          SizedBox(height: 2 * s),
          Text('Ingresos mensuales', style: AppFonts.style(size: 12 * s, weight: FontWeight.w500, color: AppColors.muted)),
        ],
      ),
    );
  }
}