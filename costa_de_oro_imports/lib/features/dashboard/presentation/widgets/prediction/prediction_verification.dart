import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';
import '../../../domain/forecast_stats.dart';
import '../../../domain/sales_prediction_model.dart';
import 'prediction_formatters.dart';
import 'prediction_palette.dart';

/// Resume el backtest y permite seleccionar un mes para inspeccionarlo.
///
/// El sesgo y el error medio se calculan con los elementos disponibles en la
/// evaluación. Cada fila conserva su propia selección visual y comunica el
/// mes activo al componente padre.
class PredictionVerification extends StatelessWidget {
  /// Métricas y comparaciones históricas recibidas de los servicios.
  final SalesDashboardData data;

  /// Sesgo, cantidad de meses y fecha más reciente derivados para el dashboard.
  final ForecastStats stats;

  /// Factor de escala visual aplicado por el layout de la aplicación.
  final double s;

  /// Mes seleccionado en la gráfica; se usa para resaltar la fila relacionada.
  final String? selectedMonth;

  /// Notifica al padre cuando se selecciona una fila de evaluación.
  final ValueChanged<String> onMonthSelected;

  /// Crea el resumen y la lista ordenada de meses evaluados.
  const PredictionVerification({
    super.key,
    required this.data,
    required this.stats,
    required this.s,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = List<EvaluationItem>.of(data.evaluacion.comparacion)
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    final bias = stats.biasPct;
    final mae = data.evaluacion.mae > 0
        ? data.evaluacion.mae
        : items.isNotEmpty
        ? items.fold<double>(0, (sum, item) => sum + item.errorAbsoluto) /
              items.length
        : data.summary.mae;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verificacion Reciente',
          style: AppFonts.style(
            size: 16 * s,
            weight: FontWeight.bold,
            color: AppColors.brownDark,
          ),
        ),
        Text(
          'Backtest reciente · ${items.length} meses cerrados',
          style: TextStyle(fontSize: 12 * s, color: Colors.grey),
        ),
        SizedBox(height: 12 * s),

        // El MAE del endpoint tiene prioridad; se deriva de las filas si falta.
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                s: s,
                label: 'Sesgo promedio',
                value: stats.nBacktest > 0
                    ? '${bias >= 0 ? "+" : ""}${bias.toStringAsFixed(1)}%'
                    : '—',
                hint: stats.nBacktest == 0
                    ? 'Sin meses evaluados'
                    : bias.abs() < 2
                    ? 'Sin sesgo claro · ${stats.nBacktest} meses'
                    : '${bias > 0 ? "Sobreestima" : "Subestima"} · ${stats.nBacktest} meses',
              ),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: _MiniStat(
                s: s,
                label: 'Error medio (MAE)',
                value:
                    items.isNotEmpty ||
                        data.evaluacion.mae > 0 ||
                        data.summary.mae > 0
                    ? formatCompactCop(mae)
                    : '—',
                hint: 'Por mes · COP · ${items.length} meses evaluados',
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * s),

        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14 * s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14 * s),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Aun no hay meses cerrados para evaluar.',
              style: TextStyle(fontSize: 12 * s, color: Colors.grey.shade700),
            ),
          )
        else
          for (final it in items)
            _PredictionVerificationRow(
              item: it,
              s: s,
              selected: selectedMonth == it.fecha,
              onTap: () => onMonthSelected(it.fecha),
            ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value, hint;
  final double s;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.hint,
    required this.s,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(14 * s),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14 * s),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.5 * s, color: Colors.grey.shade600),
        ),
        SizedBox(height: 4 * s),
        Text(
          value,
          style: TextStyle(
            fontSize: 18 * s,
            fontWeight: FontWeight.w800,
            color: AppColors.brownDark,
          ),
        ),
        Text(
          hint,
          style: TextStyle(fontSize: 10 * s, color: Colors.grey),
        ),
      ],
    ),
  );
}

class _PredictionVerificationRow extends StatelessWidget {
  final EvaluationItem item;
  final double s;
  final bool selected;
  final VoidCallback onTap;

  const _PredictionVerificationRow({
    required this.item,
    required this.s,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasActual = item.valorReal > 0;
    final dev = item.desviacionPct;
    final abs = dev.abs();
    final over = dev > 0;

    // Los rangos de estado son umbrales de lectura visual, no métricas nuevas.
    late final Color color;
    late final String estado;
    if (!hasActual) {
      color = Colors.grey;
      estado = 'Sin base';
    } else if (abs <= 5) {
      color = PredictionPalette.green;
      estado = 'Preciso';
    } else if (abs <= 15) {
      color = PredictionPalette.amber;
      estado = 'Aceptable';
    } else {
      color = PredictionPalette.red;
      estado = 'Desviado';
    }

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${labelFecha(item.fecha)}. Real ${formatCompactCop(item.valorReal)}. Predicho ${formatCompactCop(item.valorPredicho)}. ${hasActual ? "Desviacion ${abs.toStringAsFixed(1)} por ciento." : "Sin valor real de referencia."}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16 * s),
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.only(bottom: 10 * s),
            padding: EdgeInsets.all(14 * s),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFFFBF4) : Colors.white,
              borderRadius: BorderRadius.circular(16 * s),
              border: Border.all(
                color: selected ? AppColors.gold : Colors.grey.shade200,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labelFecha(item.fecha),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14 * s,
                              color: AppColors.brownDark,
                            ),
                          ),
                          SizedBox(height: 2 * s),
                          Text(
                            estado,
                            style: TextStyle(
                              fontSize: 10.5 * s,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Real  ${formatCompactCop(item.valorReal)}',
                            style: TextStyle(
                              fontSize: 12 * s,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Pred  ${formatCompactCop(item.valorPredicho)}',
                            style: TextStyle(
                              fontSize: 12 * s,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10 * s,
                        vertical: 6 * s,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10 * s),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: !hasActual
                                ? HugeIcons.strokeRoundedInformationCircle
                                : over
                                ? HugeIcons.strokeRoundedTradeUp
                                : HugeIcons.strokeRoundedTradeDown,
                            size: 12 * s,
                            color: color,
                            strokeWidth: 2,
                          ),
                          SizedBox(width: 3 * s),
                          Text(
                            hasActual ? '${abs.toStringAsFixed(1)}%' : '—',
                            style: TextStyle(
                              fontSize: 12 * s,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasActual) ...[
                  SizedBox(height: 10 * s),
                  _DeviationBar(dev: dev, color: color, s: s),
                  SizedBox(height: 6 * s),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${over ? "Sobreestimo" : "Subestimo"} por ${formatCompactCop(item.diferencia.abs())}',
                      style: TextStyle(
                        fontSize: 10.5 * s,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ] else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8 * s),
                      child: Text(
                        'Sin ventas reales para calcular el desvio porcentual.',
                        style: TextStyle(
                          fontSize: 10.5 * s,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra centrada: izquierda indica subestimación y derecha sobreestimación.
///
/// La longitud se limita visualmente al 30 % para que desviaciones extremas no
/// desplacen la escala disponible para los demás meses.
class _DeviationBar extends StatelessWidget {
  final double dev;
  final Color color;
  final double s;
  const _DeviationBar({
    required this.dev,
    required this.color,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final frac = (dev.abs() / 30).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, c) {
        final half = c.maxWidth / 2;
        return SizedBox(
          height: 8 * s,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4 * s),
                ),
              ),
              Positioned(
                left: dev >= 0 ? half : half - half * frac,
                width: half * frac,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4 * s),
                  ),
                ),
              ),
              Positioned(
                left: half - 0.5,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: Colors.grey.shade400),
              ),
            ],
          ),
        );
      },
    );
  }
}
