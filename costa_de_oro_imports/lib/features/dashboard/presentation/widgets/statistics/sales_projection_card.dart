// RAMA: feature/Products
// ============================================================================
// WIDGET: SalesProjectionCard
// ============================================================================
// Gráfica que se dibuja de izquierda a derecha SOLO cuando es visible.
// ============================================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_fonts.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../domain/sales_projection_model.dart';
import '../../providers/sales_projection_provider.dart';

class SalesProjectionCard extends ConsumerStatefulWidget {
  final bool isVisible; // <-- PARÁMETRO NUEVO

  const SalesProjectionCard({super.key, required this.isVisible});

  @override
  ConsumerState<SalesProjectionCard> createState() => _SalesProjectionCardState();
}

class _SalesProjectionCardState extends ConsumerState<SalesProjectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Si ya es visible al cargar, animamos de inmediato
    if (widget.isVisible) {
      _sweepController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant SalesProjectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia a visible, disparamos la animación
    if (widget.isVisible && !oldWidget.isVisible) {
      _sweepController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final projectionAsync = ref.watch(salesProjectionProvider);

    return Container(
      padding: EdgeInsets.all(20 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proyeccion de ventas',
            style: AppFonts.style(
              size: 16 * s,
              weight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4 * s),
          Text(
            'Historico de ventas pagadas por año',
            style: AppFonts.style(size: 12 * s, color: Colors.black54),
          ),
          SizedBox(height: 24 * s),
          
          SizedBox(
            height: 220 * s,
            child: projectionAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Error al cargar la proyeccion',
                  style: TextStyle(color: Colors.red.shade400),
                ),
              ),
              data: (data) => _buildChart(data, s),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(SalesProjectionData data, double s) {
    if (data.series.isEmpty || data.categorias.isEmpty) {
      return const Center(child: Text('Sin datos historicos'));
    }

    final List<FlSpot> spots = [];
    for (int i = 0; i < data.series.length; i++) {
      if (i < data.categorias.length) {
        spots.add(
          FlSpot(
            data.categorias[i] / 1000,
            data.series[i],
          ),
        );
      }
    }

    final xMin = spots.first.x;
    final xMax = spots.last.x;
    final yMin = data.minVenta * 0.9;
    final yMax = data.maxVenta * 1.1;
    final yInterval = (yMax - yMin) == 0 ? 1.0 : (yMax - yMin) / 4;

    return AnimatedBuilder(
      animation: _sweepController,
      builder: (context, child) {
        return ClipRect(
          clipper: _SweepClipper(_sweepController.value),
          child: child,
        );
      },
      child: LineChart(
        duration: Duration.zero, // Apagamos la animación por defecto
        LineChartData(
          minX: xMin,
          maxX: xMax,
          minY: yMin,
          maxY: yMax,
          lineTouchData: LineTouchData(
            enabled: true,
            touchSpotThreshold: 20,
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((spotIndex) {
                return TouchedSpotIndicatorData(
                  const FlLine(color: Colors.transparent),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 5 * s,
                        color: const Color(0xFF3B82F6),
                        strokeWidth: 2 * s,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => const Color(0xFF1A1A1A),
              tooltipBorderRadius: BorderRadius.circular(8 * s), 
              tooltipPadding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
              tooltipMargin: 8 * s,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final millones = (spot.y / 1000000).toStringAsFixed(1);
                  final anio = spot.x.toInt();
                  return LineTooltipItem(
                    'Año $anio\n',
                    AppFonts.style(size: 12 * s, color: Colors.white70),
                    children: [
                      TextSpan(
                        text: '\$$millones M',
                        style: AppFonts.style(
                          size: 14 * s,
                          weight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30 * s,
                getTitlesWidget: (value, meta) {
                  if (value % 1 == 0) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8 * s),
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10 * s, color: Colors.grey),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45 * s,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  final millones = (value / 1000000).toStringAsFixed(0);
                  return Text(
                    '\$${millones}M',
                    style: TextStyle(fontSize: 10 * s, color: Colors.grey),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: const Color(0xFF3B82F6),
              barWidth: 3 * s,
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
    );
  }
}

class _SweepClipper extends CustomClipper<Rect> {
  _SweepClipper(this.progress);

  final double progress;
  static const _margin = 10.0;

  @override
  Rect getClip(Size size) {
    if (progress <= 0) return Rect.zero;
    final right = progress >= 1 ? size.width + _margin : size.width * progress;
    return Rect.fromLTRB(-_margin, -_margin, right, size.height + _margin);
  }

  @override
  bool shouldReclip(covariant _SweepClipper oldClipper) => 
      oldClipper.progress != progress;
}