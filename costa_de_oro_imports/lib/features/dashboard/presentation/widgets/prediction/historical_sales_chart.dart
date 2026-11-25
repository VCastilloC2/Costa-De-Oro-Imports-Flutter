import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../domain/sales_prediction_model.dart';
import 'chart_sweep_clipper.dart';
import 'prediction_chart_palette.dart';

/// Formateadores reutilizados para evitar recrearlos por cada punto.
final _cop = NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
);
final _compact = NumberFormat.compact(locale: 'es_CO');

/// Dibuja las ventas reales, los ajustes y el mes parcial del historial.
///
/// La animación de revelado comienza cuando al menos el 40 % del gráfico es
/// visible. La selección de un punto se comunica al componente padre para
/// sincronizar el detalle con la verificación y el pronóstico.
class HistoricalSalesChart extends StatefulWidget {
  /// Puntos históricos y parciales del rango actualmente visible.
  final List<ProjectionPoint> points;

  /// Ventana seleccionada: 12, 36 o cero para todo el historial.
  final int range;

  /// Mes enfocado actualmente en la página.
  final String? selectedMonth;

  /// Controla la serie de ventas reales cerradas.
  final bool showActual;

  /// Controla los valores de ajuste del modelo en meses cerrados.
  final bool showAdjustment;

  /// Controla el punto del mes en curso, que es parcial.
  final bool showCurrentMonth;

  /// Controla el resaltado de meses con desviaciones superiores al 30 %.
  final bool showOutliers;

  /// Factor de escala visual aplicado por el layout de la aplicación.
  final double s;

  /// Notifica el mes seleccionado tras una interacción con la gráfica.
  final ValueChanged<String> onMonthSelected;

  /// Crea la gráfica histórica con sus series y estado de selección.
  const HistoricalSalesChart({
    super.key,
    required this.points,
    required this.range,
    required this.selectedMonth,
    required this.showActual,
    required this.showAdjustment,
    required this.showCurrentMonth,
    required this.showOutliers,
    required this.s,
    required this.onMonthSelected,
  });

  @override
  State<HistoricalSalesChart> createState() => _HistoricalSalesChartState();
}

class _HistoricalSalesChartState extends State<HistoricalSalesChart>
    with SingleTickerProviderStateMixin {
  /// Revela la gráfica de izquierda a derecha cuando entra en pantalla.
  late final AnimationController _sweepController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  /// Registra si la primera animación ya se inició.
  bool _isVisible = false;

  @override
  void didUpdateWidget(covariant HistoricalSalesChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Un rango distinto cambia los puntos y reinicia el revelado si ya se vio.
    if (oldWidget.range != widget.range && _isVisible) {
      _sweepController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  /// Inicia la animación al superar el umbral de visibilidad.
  ///
  /// Respeta la preferencia del sistema para reducir movimiento.
  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction <= 0.4 || _isVisible) return;
    _isVisible = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweepController.value = 1;
    } else {
      _sweepController.forward(from: 0);
    }
  }

  /// Elige un intervalo legible para las divisiones del eje vertical.
  double _niceStep(double raw) {
    final exp = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final f = raw / exp;
    final nf = f <= 1 ? 1 : (f <= 2 ? 2 : (f <= 5 ? 5 : 10));
    return nf * exp;
  }

  @override
  Widget build(BuildContext context) {
    final pts = widget.points;
    final range = widget.range;
    final selectedMonth = widget.selectedMonth;
    final showActual = widget.showActual;
    final showAdjustment = widget.showAdjustment;
    final showCurrentMonth = widget.showCurrentMonth;
    final showOutliers = widget.showOutliers;
    final s = widget.s;
    final onMonthSelected = widget.onMonthSelected;
    final selectedHistoryIndex = pts.indexWhere(
      (point) => point.fecha == selectedMonth,
    );
    final real = <FlSpot>[];
    final ajuste = <FlSpot>[];
    final parcial = <FlSpot>[];
    final outliers = <int>{};

    double maxY = 0;

    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      final x = i.toDouble();

      if (p.tipo == 'real' || p.tipo == 'parcial') {
        if (p.prediccion > 0) {
          ajuste.add(FlSpot(x, p.prediccion));
          if (showAdjustment) {
            maxY = math.max(maxY, p.prediccion);
          }
        }
        if (p.real != null && p.real! > 0) {
          if (p.tipo == 'parcial') {
            // Un mes parcial se muestra aislado: no es comparable con un cierre.
            parcial.add(FlSpot(x, p.real!));
            if (showCurrentMonth) {
              maxY = math.max(maxY, p.real!);
            }
          } else {
            real.add(FlSpot(x, p.real!));
            if (showActual) {
              maxY = math.max(maxY, p.real!);
            }
            if (p.prediccion > 0 &&
                (p.real! - p.prediccion).abs() / p.prediccion > 0.30) {
              outliers.add(i);
            }
          }
        }
      }
    }

    final selectedAdjustmentSpotIndex = selectedHistoryIndex < 0
        ? -1
        : ajuste.indexWhere((spot) => spot.x.round() == selectedHistoryIndex);
    final hasVisibleHistory =
        (showActual && real.isNotEmpty) ||
        (showAdjustment && ajuste.isNotEmpty) ||
        (showCurrentMonth && parcial.isNotEmpty);
    final step = _niceStep(math.max(maxY * 1.15, 1) / 4);
    final yMax = step * 4;
    final maxX = math.max(1, pts.length - 1).toDouble();
    const leftReserved = 46.0;

    // El tooltip usa solo las series activas y distingue mes parcial de cierre.
    LineTooltipItem? tooltipFor(int idx) {
      if (idx < 0 || idx >= pts.length) return null;
      final p = pts[idx];
      final base = TextStyle(color: Colors.white70, fontSize: 11 * s);
      final bold = TextStyle(
        color: Colors.white,
        fontSize: 12 * s,
        fontWeight: FontWeight.bold,
      );
      final lines = <TextSpan>[];

      if (p.tipo == 'parcial' && showCurrentMonth) {
        lines.add(
          TextSpan(
            text: 'Mes en curso (incompleto)\n',
            style: bold.copyWith(color: PredictionChartPalette.projection),
          ),
        );
        lines.add(
          TextSpan(text: 'Acumulado ${_cop.format(p.real ?? 0)}', style: base),
        );
      } else if (p.tipo == 'real' && showActual && p.real != null) {
        lines.add(
          TextSpan(text: 'Real  ${_cop.format(p.real ?? 0)}\n', style: bold),
        );
      }

      if (p.tipo == 'real' && showAdjustment) {
        lines.add(
          TextSpan(text: 'Ajuste  ${_cop.format(p.prediccion)}', style: base),
        );
      }

      if (p.tipo == 'real' &&
          showActual &&
          showAdjustment &&
          p.real != null &&
          p.real! > 0 &&
          p.prediccion > 0) {
        final difference = p.prediccion - p.real!;
        final deviation = difference / p.real! * 100;
        lines.add(
          TextSpan(
            text:
                '\n${difference >= 0 ? "Sobreestimo" : "Subestimo"} ${_cop.format(difference.abs())} (${deviation.abs().toStringAsFixed(1)}%)',
            style: base.copyWith(
              color: deviation.abs() > 15
                  ? const Color(0xFFFFB4A8)
                  : AppColors.gold,
            ),
          ),
        );
      }

      return LineTooltipItem(
        '${labelFecha(p.fecha)}\n',
        TextStyle(
          color: AppColors.gold,
          fontSize: 11 * s,
          fontWeight: FontWeight.w600,
        ),
        children: lines,
        textAlign: TextAlign.left,
      );
    }

    return VisibilityDetector(
      key: const Key('prediction-historical-chart-visibility'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grafica historica
          if (!hasVisibleHistory)
            SizedBox(
              height: 220 * s,
              child: Center(
                child: Text(
                  'Activa una serie de la leyenda para verla.',
                  style: TextStyle(fontSize: 12 * s, color: Colors.grey),
                ),
              ),
            )
          else
            SizedBox(
              height: 270 * s,
              child: LayoutBuilder(
                builder: (context, c) {
                  return Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _sweepController,
                        builder: (context, child) => ClipRect(
                          clipper: ChartSweepClipper(_sweepController.value),
                          child: child,
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(top: 22 * s),
                          child: LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: maxX,
                              minY: 0,
                              maxY: yMax,
                              clipData: const FlClipData.all(),
                              gridData: FlGridData(
                                drawVerticalLine: false,
                                horizontalInterval: step,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: Colors.grey.shade200,
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: leftReserved * s,
                                    interval: step,
                                    getTitlesWidget: (v, meta) {
                                      if (v == 0) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: EdgeInsets.only(right: 6 * s),
                                        child: Text(
                                          '\$${_compact.format(v)}',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 10 * s,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28 * s,
                                    interval: 1,
                                    getTitlesWidget: (v, meta) {
                                      if (v != v.roundToDouble()) {
                                        return const SizedBox.shrink();
                                      }
                                      final i = v.toInt();
                                      if (i < 0 || i >= pts.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final f = pts[i].fecha;
                                      if (f.length < 7) {
                                        return const SizedBox.shrink();
                                      }
                                      final m =
                                          int.tryParse(f.substring(5, 7)) ?? 0;
                                      final isJan = m == 1;
                                      final showMonth =
                                          range == 12 &&
                                          !isJan &&
                                          (m - 1) % 3 == 0;
                                      if (!isJan && !showMonth) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: EdgeInsets.only(top: 8 * s),
                                        child: Text(
                                          isJan
                                              ? f.substring(0, 4)
                                              : labelFecha(f).split(' ')[0],
                                          style: TextStyle(
                                            fontSize: 10 * s,
                                            color: isJan
                                                ? AppColors.brownDark
                                                : Colors.grey,
                                            fontWeight: isJan
                                                ? FontWeight.w700
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              extraLinesData: ExtraLinesData(
                                verticalLines: [
                                  if (selectedHistoryIndex >= 0)
                                    VerticalLine(
                                      x: selectedHistoryIndex.toDouble(),
                                      color: AppColors.gold.withValues(
                                        alpha: 0.8,
                                      ),
                                      strokeWidth: 1.2,
                                      dashArray: [3, 3],
                                    ),
                                ],
                              ),
                              lineTouchData: LineTouchData(
                                touchSpotThreshold: 22,
                                touchCallback: (event, response) {
                                  final spots = response?.lineBarSpots;
                                  if (spots == null || spots.isEmpty) return;
                                  final index = spots.first.x.round();
                                  if (index >= 0 && index < pts.length) {
                                    onMonthSelected(pts[index].fecha);
                                  }
                                },
                                getTouchedSpotIndicator: (bar, idxs) => idxs
                                    .map(
                                      (_) => TouchedSpotIndicatorData(
                                        FlLine(
                                          color: AppColors.gold.withValues(
                                            alpha: 0.6,
                                          ),
                                          strokeWidth: 1,
                                          dashArray: [3, 3],
                                        ),
                                        const FlDotData(show: false),
                                      ),
                                    )
                                    .toList(),
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (_) => AppColors.brownDark,
                                  tooltipPadding: EdgeInsets.symmetric(
                                    horizontal: 12 * s,
                                    vertical: 8 * s,
                                  ),
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  getTooltipItems: (touched) {
                                    var done = false;
                                    return touched.map((t) {
                                      if (done) return null;
                                      done = true;
                                      return tooltipFor(t.x.toInt());
                                    }).toList();
                                  },
                                ),
                              ),
                              lineBarsData: [
                                if (showActual)
                                  LineChartBarData(
                                    spots: real,
                                    isCurved: true,
                                    curveSmoothness: 0.2,
                                    preventCurveOverShooting: true,
                                    color: PredictionChartPalette.real,
                                    barWidth: 2.5 * s,
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          PredictionChartPalette.real
                                              .withValues(alpha: 0.18),
                                          PredictionChartPalette.real
                                              .withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                    dotData: const FlDotData(show: false),
                                  ),
                                if (showAdjustment)
                                  LineChartBarData(
                                    spots: ajuste,
                                    isCurved: true,
                                    curveSmoothness: 0.2,
                                    preventCurveOverShooting: true,
                                    color: PredictionChartPalette.adjustment,
                                    barWidth: 2 * s,
                                    showingIndicators:
                                        selectedAdjustmentSpotIndex >= 0
                                        ? [selectedAdjustmentSpotIndex]
                                        : const [],
                                    dotData: FlDotData(
                                      show: selectedAdjustmentSpotIndex >= 0,
                                      getDotPainter: (_, _, _, _) =>
                                          FlDotCirclePainter(
                                            radius: 4.6 * s,
                                            color: PredictionChartPalette
                                                .adjustment,
                                            strokeColor: AppColors.gold,
                                            strokeWidth: 2,
                                          ),
                                    ),
                                  ),
                                if (showActual)
                                  LineChartBarData(
                                    spots: real,
                                    color: Colors.transparent,
                                    barWidth: 0,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, _, _, _) {
                                        final pointIndex = spot.x.round();
                                        final selected =
                                            pointIndex == selectedHistoryIndex;
                                        if (selected) {
                                          return FlDotCirclePainter(
                                            radius: 5.2 * s,
                                            color: PredictionChartPalette.real,
                                            strokeColor: AppColors.gold,
                                            strokeWidth: 2,
                                          );
                                        }
                                        if (showOutliers &&
                                            outliers.contains(pointIndex)) {
                                          return FlDotCirclePainter(
                                            radius: 4.2 * s,
                                            color: Colors.white,
                                            strokeColor: AppColors.brownDark,
                                            strokeWidth: 2,
                                          );
                                        }
                                        return FlDotCirclePainter(
                                          radius: 3.2 * s,
                                          color: PredictionChartPalette.real,
                                          strokeWidth: 0,
                                        );
                                      },
                                    ),
                                  ),
                                if (showCurrentMonth)
                                  LineChartBarData(
                                    spots: parcial,
                                    color: Colors.transparent,
                                    barWidth: 0,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, _, _, _) {
                                        final selected =
                                            spot.x.round() ==
                                            selectedHistoryIndex;
                                        return FlDotCirclePainter(
                                          radius: selected ? 5.2 * s : 4.5 * s,
                                          color: Colors.white,
                                          strokeColor: selected
                                              ? AppColors.gold
                                              : PredictionChartPalette
                                                    .projection,
                                          strokeWidth: selected ? 2.2 : 2,
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
