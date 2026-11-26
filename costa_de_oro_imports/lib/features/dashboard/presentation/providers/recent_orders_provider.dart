// RAMA: feature/Products
// ============================================================================
// PROVIDER: Pedidos Recientes
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/recent_order_model.dart';
import 'statistics_data_provider.dart';

final recentOrdersProvider = FutureProvider.autoDispose<List<RecentOrder>>((
  ref,
) {
  return loadStatisticsData(
    ref,
    cacheKey: 'recent_orders',
    endpoint: '/api/reportes/pedidos-recientes',
    parse: (data) {
      if (data == null) return <RecentOrder>[];
      final orders = statisticsMap(data)['pedidosRecientes'];
      if (orders == null) return <RecentOrder>[];
      if (orders is! List) {
        throw const FormatException('La respuesta de pedidos no es válida.');
      }
      return orders
          .map((order) => RecentOrder.fromJson(statisticsMap(order)))
          .toList();
    },
  );
});
