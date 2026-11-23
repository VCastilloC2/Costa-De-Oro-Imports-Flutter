import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../domain/forecast_stats.dart';
import '../../../domain/sales_prediction_model.dart';
import 'prediction_chart_palette.dart';
import 'prediction_formatters.dart';

class ForecastChart extends StatelessWidget {
  final ForecastStats stats;
  final double s;
  final String? selectedMonth;
  final bool showProjection;
  final bool showRange;
  final ValueChanged<String> onMonthSelected;

  const ForecastChart({
    super.key,
    required this.stats,
    required this.s,
    required this.selectedMonth,
    required this.showProjection,
    required this.showRange,
    required this.onMonthSelected,
  });

  double _niceStep(double raw) {
    final exp = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final factor = raw / exp;
    final niceFactor = factor <= 1
        ? 1
        : (factor <= 2 ? 2 : (factor <= 5 ? 5 : 10));
    return niceFactor * exp;
  }

  @override
  Widget build(BuildContext context) {
    final forecast = stats.futuro;
    if (forecast.isEmpty) return const SizedBox.shrink();

    final line = <FlSpot>[];
    final upper = <FlSpot>[];
    final lower = <FlSpot>[];
    var maxY = 0.0;

    for (var i = 0; i < forecast.length; i++) {
      final point = forecast[i];
      final x = i.toDouble();
      final half = point.prediccion * stats.halfWidthPct(i + 1);
      line.add(FlSpot(x, point.prediccion));
      upper.add(FlSpot(x, point.prediccion + half));
      lower.add(FlSpot(x, math.max(0, point.prediccion - half)));
      maxY = math.max(
        maxY,
        showRange ? point.prediccion + half : point.prediccion,
      );
    }

    final step = _niceStep(math.max(maxY * 1.15, 1) / 4);
    final yMax = step * 4;
    final maxX = math.max(1, forecast.length - 1).toDouble();
    final selectedIndex = forecast.indexWhere(
      (point) => point.fecha == selectedMonth,
    );
    if (!showProjection && !showRange) {
      return SizedBox(
        height: 190 * s,
        child: Center(
          child: Text(
            'Activa la proyeccion o el rango desde la leyenda.',
            style: TextStyle(fontSize: 12 * s, color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 230 * s,
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
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
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
                reservedSize: 46 * s,
                interval: step,
                getTitlesWidget: (value, _) {
                  if (value == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(right: 6 * s),
                    child: Text(
                      '\$${NumberFormat.compact(locale: 'es_CO').format(value)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 10 * s, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30 * s,
                interval: 1,
                getTitlesWidget: (value, _) {
                  if (value != value.roundToDouble()) {
                    return const SizedBox.shrink();
                  }
                  final index = value.toInt();
                  if (index < 0 || index >= forecast.length) {
                    return const SizedBox.shrink();
                  }
                  final date = forecast[index].fecha;
                  if (date.length < 7) return const SizedBox.shrink();
                  final month = int.tryParse(date.substring(5, 7)) ?? 0;
                  final showLabel =
                      forecast.length <= 6 ||
                      index == 0 ||
                      month == 1 ||
                      index % 3 == 0;
                  if (!showLabel) return const SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(top: 8 * s),
                    child: Text(
                      month == 1 || index == 0
                          ? date.substring(0, 4)
                          : labelFecha(date).split(' ')[0],
                      style: TextStyle(
                        fontSize: 10 * s,
                        color: month == 1 || index == 0
                            ? AppColors.brownDark
                            : Colors.grey,
                        fontWeight: month == 1 || index == 0
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
              if (selectedIndex >= 0)
                VerticalLine(
                  x: selectedIndex.toDouble(),
                  color: AppColors.gold.withValues(alpha: 0.8),
                  strokeWidth: 1.2,
                  dashArray: [3, 3],
                ),
            ],
          ),
          betweenBarsData: showRange
              ? [
                  BetweenBarsData(
                    fromIndex: 0,
                    toIndex: 1,
                    color: PredictionChartPalette.projection.withValues(
                      alpha: 0.16,
                    ),
                  ),
                ]
              : const [],
          lineTouchData: LineTouchData(
            touchSpotThreshold: 22,
            touchCallback: (event, response) {
              final spots = response?.lineBarSpots;
              if (spots == null || spots.isEmpty) return;
              final index = spots.first.x.round();
              if (index >= 0 && index < forecast.length) {
                onMonthSelected(forecast[index].fecha);
              }
            },
            getTouchedSpotIndicator: (bar, indexes) => indexes
                .map(
                  (_) => TouchedSpotIndicatorData(
                    FlLine(
                      color: PredictionChartPalette.projection.withValues(
                        alpha: 0.65,
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
              getTooltipItems: (touched) => touched.map((spot) {
                if (spot.barIndex != 2) return null;
                final index = spot.x.toInt();
                if (index < 0 || index >= forecast.length) return null;
                final point = forecast[index];
                final half = point.prediccion * stats.halfWidthPct(index + 1);
                return LineTooltipItem(
                  '${labelFecha(point.fecha)}\n',
                  TextStyle(
                    color: AppColors.gold,
                    fontSize: 11 * s,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: 'Base  ${formatCop(point.prediccion)}\n',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12 * s,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (showRange)
                      TextSpan(
                        text:
                            'Rango orientativo: ${formatCop(point.prediccion - half)} – ${formatCop(point.prediccion + half)}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11 * s,
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: upper,
              isCurved: true,
              color: Colors.transparent,
              barWidth: 0,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: lower,
              isCurved: true,
              color: Colors.transparent,
              barWidth: 0,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: line,
              isCurved: true,
              curveSmoothness: 0.2,
              preventCurveOverShooting: true,
              color: showProjection
                  ? PredictionChartPalette.projection
                  : Colors.transparent,
              barWidth: showProjection ? 2.6 * s : 1 * s,
              dashArray: [7, 4],
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, _, _) {
                  final selected = spot.x.round() == selectedIndex;
                  return FlDotCirclePainter(
                    radius: selected ? 5.2 * s : 3.8 * s,
                    color: showProjection
                        ? PredictionChartPalette.projection
                        : Colors.transparent,
                    strokeColor: selected
                        ? AppColors.gold
                        : showProjection
                        ? PredictionChartPalette.projection
                        : Colors.transparent,
                    strokeWidth: selected ? 2 : 0,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
