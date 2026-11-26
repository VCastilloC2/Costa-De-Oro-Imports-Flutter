// RAMA: feature/Products
// ============================================================================
// PROVIDER: Top Productos
// ============================================================================
// Pide el reporte de ventas por producto, calcula la participacion de cada
// uno sobre el total general y devuelve los 4 mas vendidos por unidades.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/top_product_model.dart';
import 'statistics_data_provider.dart';

final topProductsProvider = FutureProvider.autoDispose<List<TopProduct>>((ref) {
  return loadStatisticsData(
    ref,
    cacheKey: 'top_products',
    endpoint: '/api/reportes/ventas-producto',
    parse: (data) {
      final root = statisticsMap(data);
      final productsData = root['ventasProducto'];
      if (productsData == null) return <TopProduct>[];
      if (productsData is! List) {
        throw const FormatException(
          'La respuesta de productos vendidos no es válida.',
        );
      }
      final products = productsData
          .map((product) => TopProduct.fromJson(statisticsMap(product)))
          .toList();

      final totalGeneral = root['totalGeneral'];
      final grand =
          (totalGeneral is Map
              ? (totalGeneral['totalGeneral'] as num?)?.toDouble()
              : null) ??
          products.fold<double>(0, (sum, product) => sum + product.total);

      products.sort((a, b) {
        final byUnits = b.ventas.compareTo(a.ventas);
        return byUnits != 0 ? byUnits : b.total.compareTo(a.total);
      });

      return products
          .take(4)
          .map(
            (product) =>
                product.withShare(grand > 0 ? product.total / grand : 0),
          )
          .toList();
    },
  );
});
