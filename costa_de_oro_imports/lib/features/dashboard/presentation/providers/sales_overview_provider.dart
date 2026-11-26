// RAMA: feature/Products
// ============================================================================
// PROVIDER: Resumen de Ventas
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/sales_overview_model.dart';
import 'statistics_data_provider.dart';
import 'stock_sales_provider.dart';

final salesOverviewProvider = FutureProvider.autoDispose<SalesOverviewData>((
  ref,
) async {
  final stockCompras = await ref.watch(stockSalesProvider.future);
  final ingresosGastos = await loadStatisticsData<Map<String, dynamic>>(
    ref,
    cacheKey: 'income_expense',
    endpoint: '/api/graficas/ingresos-gastos',
    parse: statisticsMap,
  );

  final ingresos = (ingresosGastos['totalIngresos'] as num?)?.toDouble() ?? 0.0;
  final gastos = (ingresosGastos['totalGastos'] as num?)?.toDouble() ?? 0.0;
  final beneficio = ingresos - gastos;

  final beneficioPct = ingresos > 0 ? (beneficio / ingresos) * 100 : 0.0;
  final gastosPct = ingresos > 0 ? (gastos / ingresos) * 100 : 0.0;

  final stockTotal = stockCompras.stock.fold<int>(
    0,
    (sum, item) => sum + item.toInt(),
  );

  const double metaStock = 2070;
  final stockDiffPct = metaStock > 0
      ? ((stockTotal - metaStock) / metaStock) * 100
      : 0.0;

  return SalesOverviewData(
    beneficioTotal: beneficio,
    beneficioPorcentaje: beneficioPct,
    ingresosTotales: ingresos,
    ingresosPorcentaje: 100.0,
    gastosTotales: gastos,
    gastosPorcentaje: gastosPct,
    stockDisponible: stockTotal,
    stockPorcentajeMeta: stockDiffPct,
    stockEsPositivo: stockDiffPct >= 0,
  );
});