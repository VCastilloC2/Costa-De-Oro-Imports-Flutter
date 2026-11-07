import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/chart_reveal_clippers.dart';
import '../../domain/dashboard_models.dart';
import 'sales_legend.dart';

/// Dona con el reparto de ventas entre los productos más vendidos.
///
/// El anillo aparece con un "barrido de reloj" cuando [revealed] pasa a true
/// (ver [DonutSweepClipper]).
class TotalSalesCard extends StatelessWidget {
  const TotalSalesCard({
    super.key,
    required this.totalSales,
    required this.topProducts,
    required this.revealed,
    this.maxSlices = 4,
  });

  final double totalSales;
  final List<ProductSummary> topProducts;
  final bool revealed;
  final int maxSlices;

  static const _startDegrees = 255.0;

  @override
  Widget build(BuildContext context) {
    final products = topProducts
        .where((p) => p.sales > 0)
        .take(maxSlices)
        .toList(growable: false);
    final shown = products.fold<double>(0, (sum, p) => sum + p.sales);

    return AppCard(
      title: 'Productos más vendidos',
      child: products.isEmpty
          ? const EmptySection(
              message: 'Aún no hay ventas por producto.',
              icon: Icons.donut_large_rounded,
            )
          : Column(
              children: [
                Center(child: _donut(products)),
                const SizedBox(height: AppSpacing.lg),
                for (var i = 0; i < products.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.xs),
                  SalesLegendRow(
                    color: _color(i),
                    title: products[i].name,
                    value: Formatters.compactMoney(products[i].sales),
                    percent: '(${(products[i].sales / shown * 100).round()} %)',
                  ),
                ],
              ],
            ),
    );
  }

  Color _color(int index) =>
      AppColors.chartPalette[index % AppColors.chartPalette.length];

  Widget _donut(List<ProductSummary> products) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: revealed ? 1 : 0),
            duration: const Duration(milliseconds: 2000),
            curve: Curves.easeInOutCubic,
            builder: (context, progress, child) => ClipPath(
              clipper: DonutSweepClipper(progress, _startDegrees),
              child: child,
            ),
            child: ExcludeSemantics(
              child: PieChart(
                PieChartData(
                  startDegreeOffset: _startDegrees,
                  sectionsSpace: 2,
                  centerSpaceRadius: 62,
                  sections: [
                    for (var i = 0; i < products.length; i++)
                      PieChartSectionData(
                        color: _color(i),
                        value: products[i].sales,
                        radius: 20,
                        showTitle: false,
                      ),
                  ],
                ),
                // Sin animación propia: el movimiento lo da el recorte.
                duration: Duration.zero,
              ),
            ),
          ),
          // Ancho limitado al hueco de la dona para que la cifra no lo pise.
          SizedBox(
            width: 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    Formatters.compactMoney(totalSales),
                    style: AppFonts.style(
                      size: 22,
                      weight: FontWeight.w800,
                      color: AppColors.brownDark,
                    ),
                  ),
                ),
                Text('Ventas totales', style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
