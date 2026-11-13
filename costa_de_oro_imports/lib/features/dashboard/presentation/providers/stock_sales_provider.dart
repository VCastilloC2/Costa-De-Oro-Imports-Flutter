// RAMA: feature/Products
// ============================================================================
// PROVIDER: Stock y Ventas
// ============================================================================
// Hace la peticion HTTP al backend y le pasa los datos a la pantalla.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
// Asegurate de que esta ruta apunte a donde esta tu dioProvider
import '../../../../core/network/api_client.dart'; 
import '../../domain/stock_sales_model.dart';

// FutureProvider: maneja automaticamente los estados de carga y error.
final stockSalesProvider = FutureProvider.autoDispose<StockSalesData>((ref) async {
  // Obtenemos la instancia de Dio configurada
  final dio = ref.watch(dioProvider);
  
  // Hacemos la peticion GET
  final response = await dio.get('/api/graficas/stock-compras');
  
  // Retornamos el modelo parseado
  return StockSalesData.fromJson(response.data);
});