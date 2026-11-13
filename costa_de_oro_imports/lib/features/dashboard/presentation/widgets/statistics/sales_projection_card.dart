// RAMA: feature/Products
// ============================================================================
// WIDGET: SalesProjectionCard
// ============================================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../app/theme/app_fonts.dart';
import '../../../../../core/utils/responsive_utils.dart';

class SalesProjectionCard extends StatelessWidget {
  const SalesProjectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Container(
      padding: EdgeInsets.all(20 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Proyeccion de ventas', style: AppFonts.style(size: 16 * s, weight: FontWeight.w700, color: Colors.black87)),
          SizedBox(height: 4 * s),
          Text('Anos vs ventas totales', style: AppFonts.style(size: 12 * s, color: Colors.black54)),
          SizedBox(height: 24 * s),

          SizedBox(
            height: 180 * s,
            child: LineChart(
              LineChartData(
                minX: 2017,
                maxX: 2025,
                minY: 1000,
                maxY: 1500,
                lineTouchData: LineTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8 * s),
                          child: Text(value.toInt().toString(), style: TextStyle(fontSize: 10 * s, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40 * s,
                      interval: 250,
                      getTitlesWidget: (value, meta) {
                        return Text('\$${value.toInt()}', style: TextStyle(fontSize: 10 * s, color: Colors.grey));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 250,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(2017, 1100), FlSpot(2018, 1250), FlSpot(2019, 1150),
                      FlSpot(2020, 1050), FlSpot(2021, 1100), FlSpot(2022, 1300),
                      FlSpot(2023, 1400), FlSpot(2024, 1200), FlSpot(2025, 1180),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: const Color(0xFF3B82F6),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          const Color(0xFF3B82F6).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}