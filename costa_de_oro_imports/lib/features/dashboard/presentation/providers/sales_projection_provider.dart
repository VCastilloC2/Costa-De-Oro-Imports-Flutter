// RAMA: feature/Products
// ============================================================================
// PROVIDER: Proyección de Ventas
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/sales_projection_model.dart';

final salesProjectionProvider = FutureProvider.autoDispose<SalesProjectionData>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/graficas/historico-ventas');
  
  return SalesProjectionData.fromJson(response.data);
});