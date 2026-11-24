import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/sales_prediction_model.dart';

/// Carga en paralelo la serie gráfica, el backtest y el resumen del modelo.
///
/// Las tres respuestas se combinan en [SalesDashboardData]. Al ser
/// `autoDispose`, Riverpod libera el resultado cuando la pantalla deja de
/// observarlo; invalidar el provider fuerza una nueva lectura después de
/// generar una predicción. Consulta `GET /admin/prediccion/datos-grafica`,
/// `GET /api/prediccion/evaluar-ultimos-meses` y
/// `GET /api/v1/predictions/summary`.
final salesPredictionProvider = FutureProvider.autoDispose<SalesDashboardData>((
  ref,
) async {
  final dio = ref.watch(dioProvider);

  // Las fuentes independientes se consultan en paralelo para reducir espera.
  final responses = await Future.wait([
    dio.get('/admin/prediccion/datos-grafica'),
    dio.get('/api/prediccion/evaluar-ultimos-meses'),
    dio.get('/api/v1/predictions/summary'),
  ]);

  final graficaData = responses[0].data;
  final evaluacionData = responses[1].data;
  final summaryData = responses[2].data;

  // Convierte los puntos dinámicos del endpoint a modelos del dominio.
  final proyeccionRaw =
      graficaData['proyeccion_ventas'] as List<dynamic>? ?? [];
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
