// RAMA: feature/Products
// ============================================================================
// WIDGET: HourlySalesCard
// ============================================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../app/theme/app_fonts.dart';
import '../../../../../core/utils/responsive_utils.dart';

class HourlySalesCard extends StatelessWidget {
  const HourlySalesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    final days = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];

    return Container(
      padding: EdgeInsets.all(20 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ventas por hora y dia de la semana', style: AppFonts.style(size: 16 * s, weight: FontWeight.w700, color: Colors.black87)),
          SizedBox(height: 16 * s),
          
          Wrap(
            spacing: 12 * s,
            runSpacing: 8 * s,
            children: [
              _buildLegend(const Color(0xFF22C55E), '12AM-2AM', s),
              _buildLegend(const Color(0xFFF5B800), '6AM-8AM', s),
              _buildLegend(const Color(0xFFE53935), '12PM-2PM', s),
              _buildLegend(const Color(0xFF3B82F6), '6PM-8PM', s),
            ],
          ),
          SizedBox(height: 24 * s),

          SizedBox(
            height: 200 * s,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 240,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < days.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8 * s),
                            child: Text(days[index], style: TextStyle(fontSize: 11 * s, color: Colors.black54)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30 * s,
                      interval: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(), style: TextStyle(fontSize: 10 * s, color: Colors.grey));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 60,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(days.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 2 * s,
                    barRods: [
                      BarChartRodData(toY: 180, color: const Color(0xFF22C55E), width: 6 * s),
                      BarChartRodData(toY: 220, color: const Color(0xFFF5B800), width: 6 * s),
                      BarChartRodData(toY: 160, color: const Color(0xFFE53935), width: 6 * s),
                      BarChartRodData(toY: 120, color: const Color(0xFF3B82F6), width: 6 * s),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text, double s) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8 * s, height: 8 * s, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 4 * s),
        Text(text, style: AppFonts.style(size: 11 * s, color: Colors.black54)),
      ],
    );
  }
}