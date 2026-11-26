import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/sales_prediction_model.dart';

/// Carga los datos visibles del resumen sin esperar el backtest histórico.
///
/// Las respuestas principales se combinan en [SalesDashboardData]. Al ser
/// `autoDispose`, Riverpod libera el resultado cuando la pantalla deja de
/// observarlo. El backtest se carga por separado para no bloquear la vista.
final salesPredictionProvider = FutureProvider.autoDispose<SalesDashboardData>((
  ref,
) async {
  final dio = ref.watch(dioProvider);

  // La gráfica contiene la predicción guardada y es la fuente principal.
  final graficaFuture = dio.get('/admin/prediccion/datos-grafica');

  // El resumen sólo aporta métricas y metadatos. Si su endpoint falla, la
  // predicción sigue disponible y no se debe convertir toda la pantalla en error.
  final summaryFuture = dio
      .get('/api/v1/predictions/summary')
      .then((response) => response.data)
      .catchError((Object _) => const <String, dynamic>{});
  final graficaResponse = await graficaFuture;
  final summaryData = await summaryFuture;

  final graficaData = graficaResponse.data;

  // Convierte los puntos dinámicos del endpoint a modelos del dominio.
  final proyeccionRaw =
      graficaData['proyeccion_ventas'] as List<dynamic>? ?? [];
  final proyeccion = proyeccionRaw
      .map((e) => ProjectionPoint.fromJson(e as Map<String, dynamic>))
      .toList();

  return SalesDashboardData(
    proyeccionVentas: proyeccion,
    totalVentas: (graficaData['total_ventas'] as num?)?.toDouble() ?? 0.0,
    evaluacion: const EvaluationData(comparacion: [], mae: 0, mse: 0, wmape: 0),
    summary: SummaryData.fromJson(summaryData),
  );
}, retry: (retryCount, error) => null);

/// Backtest secundario: se consulta después de que el contenido principal ya
/// puede mostrarse, evitando que una evaluación lenta deje la pantalla vacía.
final salesPredictionEvaluationProvider = FutureProvider.autoDispose<EvaluationData>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/prediccion/evaluar-ultimos-meses');
  return EvaluationData.fromJson(response.data as Map<String, dynamic>);
}, retry: (retryCount, error) => null);
