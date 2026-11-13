// RAMA: feature/Products
// ============================================================================
// WIDGET: SalesOverviewCard
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_fonts.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../providers/sales_overview_provider.dart';

class SalesOverviewCard extends ConsumerWidget {
  const SalesOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final overviewAsync = ref.watch(salesOverviewProvider);

    return Container(
      padding: EdgeInsets.all(20 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descripción general de ventas',
            style: AppFonts.style(
              size: 16 * s,
              weight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 20 * s),
          
          overviewAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text(
                'Error al cargar resumen: $err',
                style: TextStyle(color: Colors.red.shade400, fontSize: 12 * s),
              ),
            ),
            data: (data) {
              final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);
              final percentFormatter = NumberFormat('0.0', 'es');

              return Column(
                children: [
                  _buildMetricRow(
                    s: s,
                    title: 'Beneficio total',
                    value: currencyFormatter.format(data.beneficioTotal),
                    percent: '(${percentFormatter.format(data.beneficioPorcentaje)}%)',
                    progressValue: data.beneficioPorcentaje / 100,
                    color: const Color(0xFF4CD04A), // Verde
                  ),
                  SizedBox(height: 16 * s),
                  
                  _buildMetricRow(
                    s: s,
                    title: 'Ingresos totales',
                    value: currencyFormatter.format(data.ingresosTotales),
                    percent: '(100%)', // Siempre es el 100% de la base
                    progressValue: 1.0, // Barra llena
                    color: const Color(0xFF3B9EFF), // Azul
                  ),
                  SizedBox(height: 16 * s),
                  
                  _buildMetricRow(
                    s: s,
                    title: 'Gastos totales',
                    value: currencyFormatter.format(data.gastosTotales),
                    percent: '(${percentFormatter.format(data.gastosPorcentaje)}%)',
                    progressValue: data.gastosPorcentaje / 100,
                    color: const Color(0xFFE53E3E), // Rojo
                  ),
                  SizedBox(height: 16 * s),
                  
                  _buildMetricRow(
                    s: s,
                    title: 'Stock disponible',
                    value: '${data.stockDisponible} unidades',
                    percent: '(${data.stockEsPositivo ? '+' : ''}${percentFormatter.format(data.stockPorcentajeMeta)}% vs meta)',
                    percentColor: data.stockEsPositivo ? const Color(0xFF4CD04A) : const Color(0xFF1A1A1A),
                    // Lógica visual para la barra amarilla
                    progressValue: (data.stockPorcentajeMeta.abs() + 100) / 100 > 1 ? 1.0 : (data.stockPorcentajeMeta.abs() + 50) / 100,
                    color: const Color(0xFFECC94B), // Amarillo
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required double s,
    required String title,
    required String value,
    required String percent,
    required double progressValue,
    required Color color,
    Color? percentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppFonts.style(
                size: 14 * s,
                weight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: AppFonts.style(
                    size: 14 * s,
                    weight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(width: 4 * s),
                Text(
                  percent,
                  style: AppFonts.style(
                    size: 12 * s,
                    weight: FontWeight.w500,
                    color: percentColor ?? color,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8 * s),
        
        ClipRRect(
          borderRadius: BorderRadius.circular(10 * s),
          child: LinearProgressIndicator(
            value: progressValue.clamp(0.0, 1.0),
            minHeight: 8 * s,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}