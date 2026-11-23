// RAMA: feature/Products
// ============================================================================
// PROVIDER: Predicción Mensual
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/sales_prediction_model.dart';

final salesPredictionProvider = FutureProvider.autoDispose<SalesDashboardData>((ref) async {
  final dio = ref.watch(dioProvider);

  // Hacemos las 3 peticiones en paralelo
  final responses = await Future.wait([
    dio.get('/admin/prediccion/datos-grafica'),
    dio.get('/api/prediccion/evaluar-ultimos-meses'),
    dio.get('/api/v1/predictions/summary'),
  ]);

  final graficaData = responses[0].data;
  final evaluacionData = responses[1].data;
  final summaryData = responses[2].data;

  // Parseamos la gráfica
  final proyeccionRaw = graficaData['proyeccion_ventas'] as List<dynamic>? ?? [];
  final proyeccion = proyeccionRaw
      .map((e) => ProjectionPoint.fromJson(e as Map<String, dynamic>))
      .toList();

  return SalesDashboardData(
    proyeccionVentas: proyeccion,
    totalVentas: (graficaData['total_ventas'] as num?)?.toDouble() ?? 0.0,
    evaluacion: EvaluationData.fromJson(evaluacionData),
    summary: SummaryData.fromJson(summaryData),
  );
});