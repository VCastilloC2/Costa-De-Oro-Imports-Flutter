// RAMA: feature/Products
// ============================================================================
// PROVIDER: Pedidos Recientes
// ============================================================================
// Consume el endpoint real GET /api/reportes/pedidos-recientes
// Utiliza el dioProvider global (que inyecta el token automáticamente).
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// IMPORTANTE: Ajusta esta ruta si tu api_client.dart está en otra carpeta.
// Por lo general suele ser: core/network/api_client.dart
import '../../../../core/network/api_client.dart'; 
import '../../domain/recent_order_model.dart';

final recentOrdersProvider = FutureProvider.autoDispose<List<RecentOrder>>((ref) async {
  // 1. Obtenemos la instancia de Dio configurada con el token
  final dio = ref.watch(dioProvider);

  try {
    // 2. Hacemos la petición (el interceptor de tu api_client pone el Bearer token)
    final response = await dio.get('/api/reportes/pedidos-recientes');
    
    final data = response.data;
    if (data == null || data['pedidosRecientes'] == null) {
      return [];
    }

    final List<dynamic> listJson = data['pedidosRecientes'];
    
    // 3. Mapeamos la lista de JSON a objetos RecentOrder
    return listJson
        .map((json) => RecentOrder.fromJson(json as Map<String, dynamic>))
        .toList();
        
  } on DioException catch (e) {
    // Manejo de errores de red (usando el DioException que ya tienes)
    print('Error de Dio al cargar pedidos: ${e.message}');
    if (e.response != null) {
      print('Respuesta del servidor: ${e.response?.data}');
    }
    throw Exception('Error al cargar pedidos');
  } catch (e) {
    print('Error inesperado parseando pedidos: $e');
    throw Exception('Error inesperado al parsear pedidos');
  }
});