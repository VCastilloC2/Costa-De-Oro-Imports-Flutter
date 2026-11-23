import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../domain/sales_prediction_model.dart';
import 'prediction_chart_palette.dart';

final _cop = NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
);
final _compact = NumberFormat.compact(locale: 'es_CO');

class HistoricalSalesChart extends StatelessWidget {
  final List<ProjectionPoint> points;
  final int range;
  final String? selectedMonth;
  final bool showActual;
  final bool showAdjustment;
  final bool showCurrentMonth;
  final double s;
  final ValueChanged<String> onMonthSelected;

  const HistoricalSalesChart({
    super.key,
    required this.points,
    required this.range,
    required this.selectedMonth,
    required this.showActual,
    required this.showAdjustment,
    required this.showCurrentMonth,
    required this.s,
    required this.onMonthSelected,
  });

  double _niceStep(double raw) {
    final exp = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final f = raw / exp;
    final nf = f <= 1 ? 1 : (f <= 2 ? 2 : (f <= 5 ? 5 : 10));
    return nf * exp;
  }

  @override
  Widget build(BuildContext context) {
    final pts = points;
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
            // Mes en curso: punto aislado para evitar comparar periodos parciales.
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

    // ---- Tooltip rico ----
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

    return Column(
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
                    Padding(
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
                                  if (v == 0) return const SizedBox.shrink();
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
                                      range == 12 && !isJan && (m - 1) % 3 == 0;
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
                                  color: AppColors.gold.withValues(alpha: 0.8),
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
                                        color:
                                            PredictionChartPalette.adjustment,
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
                                    if (outliers.contains(pointIndex)) {
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
                                        spot.x.round() == selectedHistoryIndex;
                                    return FlDotCirclePainter(
                                      radius: selected ? 5.2 * s : 4.5 * s,
                                      color: Colors.white,
                                      strokeColor: selected
                                          ? AppColors.gold
                                          : PredictionChartPalette.projection,
                                      strokeWidth: selected ? 2.2 : 2,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
