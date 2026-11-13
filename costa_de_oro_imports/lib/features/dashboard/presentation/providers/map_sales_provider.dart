// RAMA: feature/Products
// ============================================================================
// PROVIDER: Ventas por Ciudad
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/map_sales_model.dart';

final mapSalesProvider = FutureProvider.autoDispose<List<CitySale>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/graficas/mapa-ventas');
  
  final List<dynamic> data = response.data['ventasPorCiudad'] ?? [];
  return data.map((e) => CitySale.fromJson(e)).toList();
});