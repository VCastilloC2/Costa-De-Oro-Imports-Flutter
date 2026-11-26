// RAMA: feature/Products
// ============================================================================
// PROVIDER: Stock y Ventas
// ============================================================================
// Hace la peticion HTTP al backend y le pasa los datos a la pantalla.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/stock_sales_model.dart';
import 'statistics_data_provider.dart';

// FutureProvider: maneja automaticamente los estados de carga y error.
final stockSalesProvider = FutureProvider.autoDispose<StockSalesData>((ref) {
  return loadStatisticsData(
    ref,
    cacheKey: 'stock_sales',
    endpoint: '/api/graficas/stock-compras',
    parse: (data) => StockSalesData.fromJson(statisticsMap(data)),
  );
});
