// RAMA: feature/Products
// ============================================================================
// PROVIDER: Resumen de Ventas
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/sales_overview_model.dart';
import 'stock_sales_provider.dart';
import 'statistics_data_provider.dart';

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

  // 1. Extraer Ingresos y Gastos
  final double ingresos =
      (ingresosGastos['totalIngresos'] as num?)?.toDouble() ?? 0.0;
  final double gastos =
      (ingresosGastos['totalGastos'] as num?)?.toDouble() ?? 0.0;

  // 2. Calcular Beneficio
  final double beneficio = ingresos - gastos;

  // 3. Calcular porcentajes sobre los ingresos totales
  final double beneficioPct = ingresos > 0 ? (beneficio / ingresos) * 100 : 0.0;
  final double gastosPct = ingresos > 0 ? (gastos / ingresos) * 100 : 0.0;

  // 4. Extraer Stock Disponible (sumamos todo el arreglo de stock)
  final stockTotal = stockCompras.stock.fold<int>(
    0,
    (sum, item) => sum + item.toInt(),
  );

  // 5. Simulamos una "meta" de stock (ej: 2070) para calcular el %
  // Como el backend no envía una meta, la inventamos para que la barra se vea bien.
  // Si en el futuro el backend envía 'metaStock', solo cambias el 2070 por ese valor.
  final double metaStock = 2070;
  final double stockDiffPct = metaStock > 0
      ? ((stockTotal - metaStock) / metaStock) * 100
      : 0.0;

  return SalesOverviewData(
    beneficioTotal: beneficio,
    beneficioPorcentaje: beneficioPct,
    ingresosTotales: ingresos,
    ingresosPorcentaje: 100.0, // Los ingresos son el 100% base
    gastosTotales: gastos,
    gastosPorcentaje: gastosPct,
    stockDisponible: stockTotal,
    stockPorcentajeMeta: stockDiffPct,
    stockEsPositivo: stockDiffPct >= 0,
  );
});
