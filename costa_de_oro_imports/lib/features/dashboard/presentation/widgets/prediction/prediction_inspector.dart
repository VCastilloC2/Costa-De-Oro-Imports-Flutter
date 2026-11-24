import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../domain/forecast_stats.dart';
import '../../../domain/sales_prediction_model.dart';
import 'prediction_chart_palette.dart';
import 'prediction_formatters.dart';

/// Muestra el detalle del mes seleccionado en cualquiera de las gráficas.
///
/// Distingue entre un cierre real, el mes parcial y un punto futuro. Para los
/// pronósticos presenta el valor base y un rango orientativo; para los cierres
/// compara el ajuste con el resultado real.
class PredictionInspector extends StatelessWidget {
  /// Punto correspondiente al mes seleccionado.
  final ProjectionPoint point;

  /// Estadísticas usadas para calcular el rango y contextualizar el sesgo.
  final ForecastStats stats;

  /// Índice del punto dentro de la lista futura, o un valor negativo si no es
  /// un pronóstico.
  final int forecastIndex;

  /// Factor de escala visual aplicado por el layout de la aplicación.
  final double s;

  /// Crea el detalle sincronizado con el punto seleccionado en la gráfica.
  const PredictionInspector({
    super.key,
    required this.point,
    required this.stats,
    required this.forecastIndex,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isForecast = point.tipo == 'prediccion' && forecastIndex >= 0;
    final half = isForecast
        ? point.prediccion * stats.halfWidthPct(forecastIndex + 1)
        : 0.0;
    final real = point.real;
    final difference = real != null ? point.prediccion - real : null;
    final deviation = real != null && real > 0 && difference != null
        ? difference / real * 100
        : null;
    final title = point.tipo == 'parcial'
        ? 'Mes en curso · parcial'
        : isForecast
        ? 'Proyección · ${labelFecha(point.fecha)}'
        : 'Cierre real · ${labelFecha(point.fecha)}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(14 * s),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12 * s,
              fontWeight: FontWeight.w700,
              color: AppColors.brownDark,
            ),
          ),
          SizedBox(height: 10 * s),
          if (isForecast)
            Row(
              children: [
                _InspectorValue(
                  label: 'Bajo*',
                  value: formatCompactCop(point.prediccion - half),
                  s: s,
                ),
                _InspectorValue(
                  label: 'Base',
                  value: formatCompactCop(point.prediccion),
                  s: s,
                ),
                _InspectorValue(
                  label: 'Alto*',
                  value: formatCompactCop(point.prediccion + half),
                  s: s,
                ),
              ],
            )
          else if (point.tipo == 'parcial')
            Text(
              'Acumulado: ${formatCompactCop(real ?? 0)} · No comparable con un mes cerrado.',
              style: TextStyle(fontSize: 12 * s, color: AppColors.brownDark),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real ${formatCompactCop(real ?? 0)}   ·   Ajuste ${formatCompactCop(point.prediccion)}',
                  style: TextStyle(
                    fontSize: 12 * s,
                    color: AppColors.brownDark,
                  ),
                ),
                if (difference != null && deviation != null)
                  Padding(
                    padding: EdgeInsets.only(top: 5 * s),
                    child: Text(
                      '${difference >= 0 ? "Sobreestimó" : "Subestimó"} por ${formatCompactCop(difference.abs())} (${deviation.abs().toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 11 * s,
                        color: deviation.abs() > 15
                            ? PredictionChartPalette.projection
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          if (isForecast)
            Padding(
              padding: EdgeInsets.only(top: 8 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stats.nBacktest > 0 && stats.biasPct.abs() >= 5)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4 * s),
                      child: Text(
                        'En el backtest (${stats.nBacktest} meses), el modelo tiende a ${stats.biasPct > 0 ? "sobreestimar" : "subestimar"} ${stats.biasPct.abs().toStringAsFixed(1)}%.',
                        style: TextStyle(
                          fontSize: 10.5 * s,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brownDark,
                        ),
                      ),
                    ),
                  Text(
                    'Los extremos son orientativos, no escenarios probabilisticos calibrados. Valida inventario y pedidos en transito antes de decidir.',
                    style: TextStyle(
                      fontSize: 10.5 * s,
                      height: 1.35,
                      color: Colors.grey.shade700,
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

class _InspectorValue extends StatelessWidget {
  final String label;
  final String value;
  final double s;

  const _InspectorValue({
    required this.label,
    required this.value,
    required this.s,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10 * s, color: Colors.grey),
        ),
        SizedBox(height: 3 * s),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13 * s,
              fontWeight: FontWeight.w700,
              color: AppColors.brownDark,
            ),
          ),
        ),
      ],
    ),
  );
}
