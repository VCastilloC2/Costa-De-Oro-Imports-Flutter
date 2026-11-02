import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/demand_prediction.dart';

enum PredictionFailureKind {
  noInternet,
  serverUnavailable,
  timeout,
  unauthorized,
  unexpected,
}

class PredictionRequestException implements Exception {
  const PredictionRequestException(this.kind, this.message);

  final PredictionFailureKind kind;
  final String message;
}

class DemandPredictionRepository {
  DemandPredictionRepository(this._api, {Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final ApiClient _api;
  final Connectivity _connectivity;

  Future<DemandPrediction> fetch({int? year, int? month}) async {
    if (!await _hasNetwork()) {
      throw const PredictionRequestException(
        PredictionFailureKind.noInternet,
        'Activa Wi-Fi o datos móviles e inténtalo de nuevo.',
      );
    }

    try {
      final response = await _api.dio.post<dynamic>(
        '/api/v1/predictions/demand',
        data: {'target_year': year, 'target_month': month},
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
      if (response.data is! Map) {
        throw const PredictionRequestException(
          PredictionFailureKind.unexpected,
          'La API devolvió una respuesta de predicción no válida.',
        );
      }
      return DemandPrediction.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on PredictionRequestException {
      rethrow;
    } on DioException catch (error) {
      throw await _classify(error);
    } catch (_) {
      throw const PredictionRequestException(
        PredictionFailureKind.unexpected,
        'No se pudo interpretar la respuesta de Analytics.',
      );
    }
  }

  Future<PredictionRequestException> _classify(DioException error) async {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return const PredictionRequestException(
        PredictionFailureKind.unauthorized,
        'Tu sesión no tiene permiso para consultar Analytics. Vuelve a iniciar sesión.',
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return const PredictionRequestException(
        PredictionFailureKind.serverUnavailable,
        'El servidor de predicciones no está disponible. Inténtalo en unos momentos.',
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      if (!await _hasNetwork()) {
        return const PredictionRequestException(
          PredictionFailureKind.noInternet,
          'No hay una conexión de red activa. Activa Wi-Fi o datos móviles.',
        );
      }
      return const PredictionRequestException(
        PredictionFailureKind.timeout,
        'La API tardó demasiado en responder. Comprueba tu conexión e inténtalo de nuevo.',
      );
    }
    if (!await _hasNetwork()) {
      return const PredictionRequestException(
        PredictionFailureKind.noInternet,
        'No hay una conexión de red activa. Activa Wi-Fi o datos móviles.',
      );
    }
    return const PredictionRequestException(
      PredictionFailureKind.serverUnavailable,
      'No se pudo alcanzar el servidor de predicciones. Inténtalo nuevamente.',
    );
  }

  /// Connectivity reports available transports, not verified Internet access.
  /// The actual Dio request above remains the source of truth for reachability.
  Future<bool> _hasNetwork() async {
    try {
      final connections = await _connectivity.checkConnectivity();
      return connections.isNotEmpty &&
          connections.any((result) => result != ConnectivityResult.none);
    } catch (_) {
      // Let Dio provide the definitive network/server classification.
      return true;
    }
  }
}
