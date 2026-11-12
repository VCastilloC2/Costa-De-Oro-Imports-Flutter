// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: IncomeChartCard
// ============================================================================
// Gráfica de líneas para Ingresos vs Gastos. Utiliza un CustomClipper para
// dibujar la gráfica de izquierda a derecha cuando el widget se hace visible.
// ============================================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';

class IncomeChartCard extends StatelessWidget {
  final double s;
  final bool isVisible;

  const IncomeChartCard({super.key, required this.s, required this.isVisible});

  static const _green = Color(0xFF2E9E4F);
  static const _yellow = Color(0xFFF5B800);

  /// Construye una línea de la gráfica con sus puntos y su relleno inferior.
  LineChartBarData _line(List<double> ys, Color color) {
    return LineChartBarData(
      spots: [for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i])],
      isCurved: true,
      curveSmoothness: 0.3,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, xPercentage, bar, index, {double? size}) =>
            FlDotCirclePainter(radius: 3.5, color: Colors.white, strokeWidth: 2, strokeColor: color),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * s),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ingresos', style: AppFonts.style(size: 15 * s, weight: FontWeight.w600, color: AppColors.brownDark)),
          SizedBox(height: 6 * s),
          Row(
            children: [
              _buildLegend(color: _green, text: 'Ingresos total'),
              SizedBox(width: 14 * s),
              _buildLegend(color: _yellow, text: 'Gastos total'),
            ],
          ),
          SizedBox(height: 16 * s),
          SizedBox(
            height: 170 * s,
            // La animación se controla con el recorte (SweepClipper).
            // El TweenAnimationBuilder anima de 0 a 1 si isVisible es true.
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: isVisible ? 1 : 0),
              duration: const Duration(milliseconds: 2200),
              curve: Curves.easeInOutCubic,
              builder: (context, progress, child) => ClipRect(
                clipper: _SweepClipper(progress), 
                child: child
              ),
              child: LineChart(
                LineChartData(
                  minY: 0, maxY: 5, minX: 0, maxX: 5,
                  gridData: FlGridData(
                    show: true, drawVerticalLine: false, horizontalInterval: 1.25,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.18), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, interval: 1, reservedSize: 26 * s,
                        getTitlesWidget: (val, meta) {
                          const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'];
                          final i = val.toInt();
                          if (i >= 0 && i < months.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: 8 * s),
                              child: Text(months[i], style: AppFonts.style(size: 10 * s, color: AppColors.muted)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _line(const [3.3, 1.3, 1.8, 3.3, 1.4, 1.8], _yellow),
                    _line(const [1.3, 1.6, 1.2, 2.2, 1.7, 4.2], _green),
                  ],
                ),
                duration: Duration.zero, // La animación la da el clipper, no fl_chart.
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend({required Color color, required String text}) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: AppFonts.style(size: 11, color: AppColors.muted)),
      ],
    );
  }
}

/// Recorte que avanza de izquierda a derecha según [progress] (0 a 1).
/// Con 0 no se ve nada; con 1 se ve todo, con un pequeño margen para no cortar
/// el borde de los puntos de la gráfica.
class _SweepClipper extends CustomClipper<Rect> {
  _SweepClipper(this.progress);
  final double progress;
  static const _margin = 16.0;

  @override
  Rect getClip(Size size) {
    if (progress <= 0) return Rect.zero;
    final right = progress >= 1 ? size.width + _margin : size.width * progress;
    return Rect.fromLTRB(-_margin, -_margin, right, size.height + _margin);
  }

  @override
  bool shouldReclip(covariant _SweepClipper old) => old.progress != progress;
}