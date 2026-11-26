// RAMA: feature/Products
// ============================================================================
// PROVIDER: Proyección de Ventas
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/sales_projection_model.dart';
import 'statistics_data_provider.dart';

final salesProjectionProvider = FutureProvider.autoDispose<SalesProjectionData>(
  (ref) {
    return loadStatisticsData(
      ref,
      cacheKey: 'sales_projection',
      endpoint: '/api/graficas/historico-ventas',
      parse: (data) => SalesProjectionData.fromJson(statisticsMap(data)),
    );
  },
);
