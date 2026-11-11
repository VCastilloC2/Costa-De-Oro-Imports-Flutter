// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: TotalSalesCard
// ============================================================================
// Gráfica de dona (PieChart) para las ventas totales. Utiliza un CustomClipper
// en forma de cuña para simular que la dona se va dibujando en sentido horario.
// ============================================================================

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';

class TotalSalesCard extends StatelessWidget {
  final double s;
  final bool isVisible;

  const TotalSalesCard({super.key, required this.s, required this.isVisible});

  static const _green = Color(0xFF2E9E4F);
  static const _yellow = Color(0xFFF5B800);
  static const _red = Color(0xFFE53935);
  static const _blue = Color(0xFF1E88E5);

  @override
  Widget build(BuildContext context) {
    const startDegrees = 255.0;
    final radius = 20.0 * s;

    return Container(
      width: double.infinity,
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
          Text('Ventas totales', style: AppFonts.style(size: 15 * s, weight: FontWeight.w600, color: AppColors.brownDark)),
          SizedBox(height: 16 * s),
          Center(
            child: SizedBox(
              width: 170 * s,
              height: 170 * s,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: isVisible ? 1 : 0),
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.easeInOutCubic,
                    builder: (context, progress, child) => ClipPath(
                      clipper: _DonutSweepClipper(progress, startDegrees),
                      child: child,
                    ),
                    child: PieChart(
                      PieChartData(
                        startDegreeOffset: startDegrees,
                        sectionsSpace: 2,
                        centerSpaceRadius: 62 * s,
                        sections: [
                          PieChartSectionData(color: _blue, value: 7, radius: radius, showTitle: false),
                          PieChartSectionData(color: _green, value: 65, radius: radius, showTitle: false),
                          PieChartSectionData(color: _yellow, value: 18, radius: radius, showTitle: false),
                          PieChartSectionData(color: _red, value: 10, radius: radius, showTitle: false),
                        ],
                      ),
                      duration: Duration.zero, // Animación manejada por el clipper.
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('9,600', style: AppFonts.style(size: 24 * s, weight: FontWeight.w800, color: AppColors.brownDark)),
                      Text('Ventas totales', style: AppFonts.style(size: 10 * s, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 18 * s),
          _buildSalesLegend(color: _green, title: 'Envíos', value: '\$32,98', percent: '(2%)', s: s),
          SizedBox(height: 8 * s),
          _buildSalesLegend(color: _yellow, title: 'Reembolsos', value: '\$11', percent: '(11%)', s: s),
          SizedBox(height: 8 * s),
          _buildSalesLegend(color: _red, title: 'Pedidos', value: '\$14,87', percent: '(1%)', s: s),
          SizedBox(height: 8 * s),
          _buildSalesLegend(color: _blue, title: 'Ingresos', value: '\$3.271', percent: '(86%)', s: s),
        ],
      ),
    );
  }

  Widget _buildSalesLegend({required Color color, required String title, required String value, required String percent, required double s}) {
    return Row(
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 8 * s),
        Text(title, style: AppFonts.style(size: 12 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
        Text(' $value ', style: AppFonts.style(size: 12 * s, color: AppColors.brownDark)),
        Text(percent, style: AppFonts.style(size: 11 * s, color: AppColors.muted)),
      ],
    );
  }
}

/// Recorte en forma de "barrido de reloj": una cuña que gira en el sentido de
/// las manecillas desde [startDegrees] hasta completar la vuelta.
class _DonutSweepClipper extends CustomClipper<Path> {
  _DonutSweepClipper(this.progress, this.startDegrees);
  final double progress;
  final double startDegrees;

  @override
  Path getClip(Size size) {
    if (progress <= 0) return Path();
    if (progress >= 1) return Path()..addRect(Offset.zero & size);
    final center = size.center(Offset.zero);
    return Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: size.longestSide),
        startDegrees * math.pi / 180,
        2 * math.pi * progress,
        false,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant _DonutSweepClipper old) => 
      old.progress != progress || old.startDegrees != startDegrees;
}