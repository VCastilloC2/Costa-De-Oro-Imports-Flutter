import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/chart_reveal_clippers.dart';
import '../../domain/dashboard_models.dart';
import 'sales_legend.dart';

/// Gráfica de líneas con las ventas de los últimos meses.
///
/// La línea se dibuja de izquierda a derecha cuando [revealed] pasa a true
/// (ver [SweepClipper]).
class IncomeChartCard extends StatelessWidget {
  const IncomeChartCard({
    super.key,
    required this.history,
    required this.revealed,
    this.maxPoints = 6,
  });

  final List<SalesPoint> history;
  final bool revealed;
  final int maxPoints;

  static const _lineColor = AppColors.success;

  @override
  Widget build(BuildContext context) {
    final points = history.length > maxPoints
        ? history.sublist(history.length - maxPoints)
        : history;

    return AppCard(
      title: 'Ventas por mes',
      trailing: points.isEmpty
          ? null
          : const LegendDot(color: _lineColor, label: 'Ventas'),
      child: points.isEmpty
          ? const EmptySection(
              message: 'Todavía no hay ventas registradas.',
              icon: Icons.show_chart_rounded,
            )
          : Semantics(
              label: _description(points),
              excludeSemantics: true,
              child: SizedBox(height: 180, child: _chart(points)),
            ),
    );
  }

  /// Resumen para lectores de pantalla (la gráfica en sí no es accesible).
  String _description(List<SalesPoint> points) {
    final parts = points.map((point) {
      final date = point.date;
      final label = date == null ? '' : '${Formatters.monthShort(date)}: ';
      return '$label${Formatters.money(point.amount)}';
    });
    return 'Ventas por mes. ${parts.join('; ')}';
  }

  Widget _chart(List<SalesPoint> points) {
    final maxAmount = points.map((p) => p.amount).fold<double>(0, math.max);
    final maxY = maxAmount <= 0 ? 1.0 : maxAmount * 1.2;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: revealed ? 1 : 0),
      duration: const Duration(milliseconds: 2200),
      curve: Curves.easeInOutCubic,
      builder: (context, progress, child) =>
          ClipRect(clipper: SweepClipper(progress), child: child),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          minX: 0,
          maxX: (points.length - 1).toDouble().clamp(1, double.infinity),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) =>
                const FlLine(color: AppColors.divider, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  final date = i >= 0 && i < points.length
                      ? points[i].date
                      : null;
                  if (date == null || value != i.toDouble()) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      Formatters.monthShort(date),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.brownDark,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    Formatters.money(spot.y),
                    const TextStyle(
                      color: AppColors.creamText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].amount),
              ],
              isCurved: true,
              curveSmoothness: 0.3,
              preventCurveOverShooting: true,
              color: _lineColor,
              barWidth: 2.5,
              dotData: FlDotData(
                getDotPainter: (spot, xPercentage, bar, index, {size}) =>
                    FlDotCirclePainter(
                      radius: 3.5,
                      color: AppColors.surface,
                      strokeWidth: 2,
                      strokeColor: _lineColor,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _lineColor.withValues(alpha: 0.22),
                    _lineColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Sin animación propia: el movimiento lo da el recorte.
        duration: Duration.zero,
      ),
    );
  }
}
