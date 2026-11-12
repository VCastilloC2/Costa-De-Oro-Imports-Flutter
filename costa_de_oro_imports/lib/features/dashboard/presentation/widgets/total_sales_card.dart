// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: TotalSalesCard
// ============================================================================
// Gráfica de dona (PieChart) para las ventas totales. Recibe los datos reales
// de la API y los dibuja en sentido horario usando un CustomClipper.
// ============================================================================

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart'; // Para el formato de dinero.

class TotalSalesCard extends StatelessWidget {
  /// Factor de escala para responsividad.
  final double s;
  
  /// Bandera que activa la animación de dibujo.
  final bool isVisible;
  
  /// Valores de cada porción de la dona.
  final List<double> series;
  
  /// Nombres de cada porción (ej. "Envíos $29,881,614.00 (28%)").
  final List<String> labels;
  
  /// Total de ventas para mostrar en el centro.
  final double totalSales;

  const TotalSalesCard({
    super.key, 
    required this.s, 
    required this.isVisible,
    required this.series,
    required this.labels,
    required this.totalSales,
  });

  static const _startDegrees = 255.0;
  static const _colors = [Color(0xFF2E9E4F), Color(0xFFF5B800), Color(0xFFE53935), Color(0xFF1E88E5)];

  @override
  Widget build(BuildContext context) {
    // Si no hay datos, no dibujamos nada.
    if (series.isEmpty) return const SizedBox.shrink();
    
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
                      clipper: _DonutSweepClipper(progress, _startDegrees),
                      child: child,
                    ),
                    child: PieChart(
                      PieChartData(
                        startDegreeOffset: _startDegrees,
                        sectionsSpace: 2,
                        centerSpaceRadius: 62 * s,
                        // Generamos las secciones dinámicamente a partir de la lista 'series'.
                        sections: [
                          for (var i = 0; i < series.length; i++)
                            PieChartSectionData(
                              color: _colors[i % _colors.length],
                              value: series[i],
                              radius: radius,
                              showTitle: false,
                            ),
                        ],
                      ),
                      duration: Duration.zero, // Animación manejada por el clipper.
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Formateamos el total a algo compacto (ej. $107,7 M).
                      Text(
                        Formatters.compactMoney(totalSales), 
                        style: AppFonts.style(size: 24 * s, weight: FontWeight.w800, color: AppColors.brownDark)
                      ),
                      Text('Ventas totales', style: AppFonts.style(size: 10 * s, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 18 * s),
          // Generamos la leyenda dinámicamente a partir de la lista 'labels'.
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) SizedBox(height: 8 * s),
            _buildSalesLegend(
              color: _colors[i % _colors.length], 
              label: labels[i], 
              s: s,
            ),
          ],
        ],
      ),
    );
  }

  /// Construye una fila de la leyenda. Recibe el label completo (ej. "Envíos $29,8M (28%)")
  /// y lo divide para mostrar el título a la izquierda y el valor a la derecha.
  Widget _buildSalesLegend({required Color color, required String label, required double s}) {
    final parts = label.split(' ');
    final title = parts.first;
    final rest = label.replaceFirst(title, '').trim();

    return Row(
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 8 * s),
        Expanded(
          child: Text(
            title, 
            style: AppFonts.style(size: 12 * s, weight: FontWeight.w700, color: AppColors.brownDark)
          ),
        ),
        Text(rest, style: AppFonts.style(size: 11 * s, color: AppColors.muted)),
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