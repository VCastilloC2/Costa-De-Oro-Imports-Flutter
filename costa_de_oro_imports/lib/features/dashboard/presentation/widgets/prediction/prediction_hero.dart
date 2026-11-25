import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../domain/forecast_stats.dart';
import '../../../domain/sales_prediction_model.dart';
import 'prediction_formatters.dart';

/// Resume el primer mes pronosticado y su comparación interanual.
///
/// Se espera que el componente se construya cuando [ForecastStats.futuro] no
/// esté vacío. El rango mostrado es orientativo y usa la semiamplitud derivada
/// de las métricas de evaluación.
class PredictionHero extends StatelessWidget {
  /// Métricas que contienen el primer pronóstico y su contexto histórico.
  final ForecastStats stats;

  /// Factor de escala visual aplicado por el layout de la aplicación.
  final double s;

  /// Crea el resumen visual del siguiente mes pronosticado.
  const PredictionHero({super.key, required this.stats, required this.s});

  @override
  Widget build(BuildContext context) {
    final next = stats.futuro.first;
    final half = next.prediccion * stats.halfWidthPct(1);
    final yoy = stats.yoyPct;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22 * s),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B1A12), Color(0xFF4A3426)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brownDark.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedMagicWand01,
                size: 14 * s,
                color: AppColors.gold,
                strokeWidth: 2,
              ),
              SizedBox(width: 6 * s),
              Text(
                'PROXIMO MES  ·  ${labelFecha(next.fecha).toUpperCase()}',
                style: TextStyle(
                  fontSize: 10.5 * s,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * s),
          Text(
            formatCop(next.prediccion),
            style: TextStyle(
              fontSize: 28 * s,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4 * s),
          Text(
            'Rango orientativo  ${formatCompactCop(next.prediccion - half)} – ${formatCompactCop(next.prediccion + half)}',
            style: TextStyle(fontSize: 12 * s, color: Colors.white70),
          ),
          if (yoy != null) ...[
            SizedBox(height: 12 * s),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * s,
                vertical: 5 * s,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20 * s),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: yoy >= 0
                        ? HugeIcons.strokeRoundedTradeUp
                        : HugeIcons.strokeRoundedTradeDown,
                    size: 14 * s,
                    color: yoy >= 0
                        ? const Color(0xFF7FD3A5)
                        : const Color(0xFFFFB4A8),
                    strokeWidth: 2,
                  ),
                  SizedBox(width: 6 * s),
                  Text(
                    '${yoy >= 0 ? "+" : ""}${yoy.toStringAsFixed(1)}% vs mismo mes del año anterior',
                    style: TextStyle(fontSize: 11 * s, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
          if (yoy == null) ...[
            SizedBox(height: 12 * s),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * s,
                vertical: 5 * s,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20 * s),
              ),
              child: Text(
                'Comparacion anual no disponible',
                style: TextStyle(fontSize: 11 * s, color: Colors.white70),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
