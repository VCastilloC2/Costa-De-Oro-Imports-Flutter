// RAMA: feature/Products
// ============================================================================
// PROVIDER: Top Productos
// ============================================================================
// Pide el reporte de ventas por producto, calcula la participacion de cada
// uno sobre el total general y devuelve los 4 mas vendidos por unidades.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/top_product_model.dart';

final topProductsProvider = FutureProvider.autoDispose<List<TopProduct>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/reportes/ventas-producto');

  final root = response.data as Map<String, dynamic>;
  final List<dynamic> data = root['ventasProducto'] ?? [];
  final products = data.map((e) => TopProduct.fromJson(e)).toList();

  // Total general del reporte (con IVA). Si no viene, se suma de los productos.
  final totalGeneral = root['totalGeneral'];
  final grand = (totalGeneral is Map ? (totalGeneral['totalGeneral'] as num?)?.toDouble() : null) ??
      products.fold<double>(0, (sum, p) => sum + p.total);

  // Mas vendidos por unidades; a igualdad, el que mas dinero genera.
  products.sort((a, b) {
    final byUnits = b.ventas.compareTo(a.ventas);
    return byUnits != 0 ? byUnits : b.total.compareTo(a.total);
  });

  return products
      .take(4)
      .map((p) => p.withShare(grand > 0 ? p.total / grand : 0))
      .toList();
});