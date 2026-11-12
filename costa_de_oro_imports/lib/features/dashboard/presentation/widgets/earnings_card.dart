// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: EarningsCard
// ============================================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart';

class EarningsCard extends StatelessWidget {
  final double s;
  final double amount;
  final double balance;
  final VoidCallback? onTap; // NUEVO: Accion al tocar

  const EarningsCard({
    super.key, 
    required this.s, 
    required this.amount,
    required this.balance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Si el beneficio es igual a las ganancias, significa que no hay gastos.
    final noExpenses = amount == balance;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20 * s),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(18 * s),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20 * s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), 
                blurRadius: 12, 
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ganancias', 
                    style: AppFonts.style(size: 15 * s, weight: FontWeight.w600, color: AppColors.brownDark),
                  ),
                  Container(
                    width: 38 * s, 
                    height: 38 * s,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAD4D8), 
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedMoney01, 
                      color: AppColors.brownDark, 
                      size: 19 * s, 
                      strokeWidth: 2.0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6 * s),
              Text(
                Formatters.money(amount), 
                style: AppFonts.style(size: 30 * s, weight: FontWeight.w800, color: AppColors.brownDark),
              ),
              SizedBox(height: 2 * s),
              // ARREGLO: Si no hay gastos, no mostramos un Beneficio redundante.
              Text(
                noExpenses ? 'Promedio mensual: ${Formatters.money(amount / 11)}' : 'Beneficio: ${Formatters.money(balance)}', 
                style: AppFonts.style(size: 12 * s, weight: FontWeight.w500, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}