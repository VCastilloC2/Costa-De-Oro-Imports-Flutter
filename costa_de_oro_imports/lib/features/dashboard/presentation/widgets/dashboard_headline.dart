// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: DashboardHeadline
// ============================================================================
// Genera un titular ejecutivo basado en los datos para lectura en 5 segundos.
// Calcula la variacion de ingresos y la tasa de pedidos no cobrados para
// mostrar una alerta visual al administrador.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart';

class DashboardHeadline extends StatelessWidget {
  final double s;
  final List<double> incomes;
  final List<double> donutSeries;

  const DashboardHeadline({
    super.key,
    required this.s,
    required this.incomes,
    required this.donutSeries,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay datos suficientes, no renderizamos nada para evitar errores.
    if (incomes.isEmpty || donutSeries.isEmpty) return const SizedBox.shrink();

    // LOGICA DE INGRESOS:
    // Tomamos el ultimo mes registrado y el anterior para calcular la variacion.
    final lastIncome = incomes.last;
    final prevIncome = incomes.length > 1 ? incomes[incomes.length - 2] : 0;
    final incomeDiff = prevIncome > 0
        ? ((lastIncome - prevIncome) / prevIncome * 100).round()
        : 0;
    final isUp = incomeDiff >= 0;

    // LOGICA DE LA DONA:
    // Calculamos el total y el porcentaje de pedidos no cobrados (indice 1).
    final totalDonut = donutSeries.fold(0.0, (a, b) => a + b);
    final unpaid = donutSeries.length > 1 ? donutSeries[1] : 0.0;
    final unpaidPct = totalDonut > 0 ? (unpaid / totalDonut * 100).round() : 0;

    // Si mas del 30 por ciento no se ha cobrado, mostramos la alerta.
    final showAlert = unpaidPct > 30;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        // Fondo amarillo suave si hay alerta, blanco si todo esta bien.
        color: showAlert ? AppColors.gold.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(
          color: showAlert
              ? AppColors.goldDark.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono representativo del resumen.
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
          // Textos del titular.
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
                // Texto enriquecido para colorear partes especificas.
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'El ultimo mes registro ',
                        style: AppFonts.style(
                          size: 13 * s,
                          color: AppColors.brownDark,
                        ),
                      ),
                      TextSpan(
                        text: Formatters.money(lastIncome),
                        style: AppFonts.style(
                          size: 13 * s,
                          weight: FontWeight.w800,
                          color: AppColors.brownDark,
                        ),
                      ),
                      TextSpan(
                        text: ' (${isUp ? "+" : ""}$incomeDiff%). ',
                        style: AppFonts.style(
                          size: 13 * s,
                          weight: FontWeight.w700,
                          color: isUp
                              ? const Color(0xFF2E9E4F)
                              : const Color(0xFFC0573E),
                        ),
                      ),
                      // Si hay alerta, agregamos la frase de advertencia.
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