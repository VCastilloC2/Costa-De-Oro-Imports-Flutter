// RAMA: feature/Products
// ============================================================================
// PROVIDER: Resumen de Ventas
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/sales_overview_model.dart';

final salesOverviewProvider = FutureProvider.autoDispose<SalesOverviewData>((ref) async {
  final dio = ref.watch(dioProvider);
  
  // Hacemos las dos peticiones en paralelo para que sea más rápido
  final responses = await Future.wait([
    dio.get('/api/graficas/ingresos-gastos'),
    dio.get('/api/graficas/stock-compras'),
  ]);

  final ingresosGastos = responses[0].data;
  final stockCompras = responses[1].data;

  // 1. Extraer Ingresos y Gastos
  final double ingresos = (ingresosGastos['totalIngresos'] as num?)?.toDouble() ?? 0.0;
  final double gastos = (ingresosGastos['totalGastos'] as num?)?.toDouble() ?? 0.0;
  
  // 2. Calcular Beneficio
  final double beneficio = ingresos - gastos;

  // 3. Calcular porcentajes sobre los ingresos totales
  final double beneficioPct = ingresos > 0 ? (beneficio / ingresos) * 100 : 0.0;
  final double gastosPct = ingresos > 0 ? (gastos / ingresos) * 100 : 0.0;

  // 4. Extraer Stock Disponible (sumamos todo el arreglo de stock)
  final List<dynamic> stockList = stockCompras['stock'] ?? [];
  final int stockTotal = stockList.fold(0, (sum, item) => sum + (item as num).toInt());

  // 5. Simulamos una "meta" de stock (ej: 2070) para calcular el %
  // Como el backend no envía una meta, la inventamos para que la barra se vea bien.
  // Si en el futuro el backend envía 'metaStock', solo cambias el 2070 por ese valor.
  final double metaStock = 2070; 
  final double stockDiffPct = metaStock > 0 ? ((stockTotal - metaStock) / metaStock) * 100 : 0.0;

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