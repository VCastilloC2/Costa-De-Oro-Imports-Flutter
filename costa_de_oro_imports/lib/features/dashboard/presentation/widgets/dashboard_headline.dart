// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: DashboardHeadline
// ============================================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/dashboard_models.dart'; // NUEVO IMPORT

class DashboardHeadline extends StatelessWidget {
  final double s;
  final List<double> incomes;
  final List<DonutItem> donutItems; // Cambiamos la lista

  const DashboardHeadline({
    super.key,
    required this.s,
    required this.incomes,
    required this.donutItems,
  });

  @override
  Widget build(BuildContext context) {
    if (incomes.isEmpty || donutItems.isEmpty) return const SizedBox.shrink();

    final lastIncome = incomes.last;
    final prevIncome = incomes.length > 1 ? incomes[incomes.length - 2] : 0;
    final incomeDiff = prevIncome > 0
        ? ((lastIncome - prevIncome) / prevIncome * 100).round()
        : 0;
    final isUp = incomeDiff >= 0;

    // Calculamos el total sumando los items
    final totalDonut = donutItems.fold(0.0, (sum, item) => sum + item.monto);
    // Buscamos el porcentaje de "No cobradas" (asumiendo que es el segundo item)
    final unpaidMonto = donutItems.length > 1 ? donutItems[1].monto : 0.0;
    final unpaidPct = totalDonut > 0 ? (unpaidMonto / totalDonut * 100).round() : 0;
    final showAlert = unpaidPct > 30;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: showAlert ? AppColors.gold.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(
          color: showAlert ? AppColors.goldDark.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8 * s),
            decoration: BoxDecoration(
              color: showAlert
                  ? AppColors.goldDark.withValues(alpha: 0.15)
                  : AppColors.brownDark.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: showAlert
                  ? HugeIcons.strokeRoundedAlert02
                  : HugeIcons.strokeRoundedAnalytics01,
              color: showAlert ? AppColors.goldDark : AppColors.brownDark,
              size: 20 * s,
            ),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen del periodo',
                  style: AppFonts.style(
                    size: 12 * s,
                    weight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                SizedBox(height: 4 * s),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'El ultimo mes registro ',
                        style: AppFonts.style(size: 13 * s, color: AppColors.brownDark),
                      ),
                      TextSpan(
                        text: Formatters.money(lastIncome),
                        style: AppFonts.style(size: 13 * s, weight: FontWeight.w800, color: AppColors.brownDark),
                      ),
                      TextSpan(
                        text: ' (${isUp ? "+" : ""}$incomeDiff%). ',
                        style: AppFonts.style(
                          size: 13 * s,
                          weight: FontWeight.w700,
                          color: isUp ? const Color(0xFF2E9E4F) : const Color(0xFFC0573E),
                        ),
                      ),
                      if (showAlert)
                        TextSpan(
                          text: 'Atencion: $unpaidPct% de las ventas no se cobraron.',
                          style: AppFonts.style(
                            size: 13 * s,
                            weight: FontWeight.w700,
                            color: AppColors.goldDark,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}