// RAMA: feature/Products
// ============================================================================
// PROVIDER: Ventas por Ciudad
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/map_sales_model.dart';
import 'statistics_data_provider.dart';

final mapSalesProvider = FutureProvider.autoDispose<List<CitySale>>((ref) {
  return loadStatisticsData(
    ref,
    cacheKey: 'map_sales',
    endpoint: '/api/graficas/mapa-ventas',
    parse: (data) {
      if (data == null) return <CitySale>[];
      final root = statisticsMap(data);
      final cities = root['ventasPorCiudad'];
      if (cities == null) return <CitySale>[];
      if (cities is! List) {
        throw const FormatException(
          'La respuesta del mapa no contiene ventas.',
        );
      }
      return cities
          .map((city) => CitySale.fromJson(statisticsMap(city)))
          .toList();
    },
  );
});
