// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: EarningsCard
// ============================================================================
// Tarjeta que muestra las ganancias totales y el beneficio neto. Recibe los
// valores desde la API y les aplica el formato de moneda colombiano (puntos
// de miles y símbolo de peso).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart'; // Importamos el formateador de moneda.

class EarningsCard extends StatelessWidget {
  /// Factor de escala para responsividad.
  final double s;
  
  /// Monto total de los ingresos o ganancias brutas.
  final double amount;
  
  /// Balance o beneficio neto (Ingresos - Gastos).
  final double balance;

  const EarningsCard({
    super.key, 
    required this.s, 
    required this.amount,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Cabecera de la tarjeta: Título e Icono.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ganancias', 
                style: AppFonts.style(
                  size: 15 * s, 
                  weight: FontWeight.w600, 
                  color: AppColors.brownDark,
                ),
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
          
          // Monto principal formateado (ej. $16.318.827).
          Text(
            Formatters.money(amount), 
            style: AppFonts.style(
              size: 30 * s, 
              weight: FontWeight.w800, 
              color: AppColors.brownDark,
            ),
          ),
          SizedBox(height: 2 * s),
          
          // Subtítulo con el beneficio neto.
          Text(
            'Beneficio: ${Formatters.money(balance)}', 
            style: AppFonts.style(
              size: 12 * s, 
              weight: FontWeight.w500, 
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}