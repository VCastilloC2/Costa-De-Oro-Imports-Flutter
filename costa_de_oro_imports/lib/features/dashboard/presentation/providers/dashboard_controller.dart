import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_models.dart';

class DashboardState {
  const DashboardState({
    this.isLoading = false,
    this.error,
    this.accessDenied = false,
    this.data,
    this.isPredictionLoading = false,
    this.isGeneratingPrediction = false,
    this.predictionError,
    this.prediction,
  });

  final bool isLoading;
  final String? error;

  /// El usuario no es administrador: reintentar no sirve de nada.
  final bool accessDenied;
  final DashboardData? data;
  final bool isPredictionLoading;
  final bool isGeneratingPrediction;
  final String? predictionError;
  final PredictionDashboard? prediction;

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? accessDenied,
    DashboardData? data,
    bool clearData = false,
    bool? isPredictionLoading,
    bool? isGeneratingPrediction,
    String? predictionError,
    bool clearPredictionError = false,
    PredictionDashboard? prediction,
    bool clearPrediction = false,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      accessDenied: accessDenied ?? this.accessDenied,
      data: clearData ? null : data ?? this.data,
      isPredictionLoading: isPredictionLoading ?? this.isPredictionLoading,
      isGeneratingPrediction:
          isGeneratingPrediction ?? this.isGeneratingPrediction,
      predictionError: clearPredictionError
          ? null
          : predictionError ?? this.predictionError,
      prediction: clearPrediction ? null : prediction ?? this.prediction,
    );
  }
}

final dashboardProvider = NotifierProvider<DashboardController, DashboardState>(
  DashboardController.new,
);

class DashboardController extends Notifier<DashboardState> {
  late final DashboardRepository _repository = DashboardRepository(ApiClient());
  Future<void>? _activeDashboardLoad;
  Future<void>? _activePredictionLoad;
  Future<void>? _activeGeneration;

  @override
  DashboardState build() => const DashboardState();

  /// Begins directly after a successful login; concurrent callers share the same request.
  Future<void> load({bool force = false}) {
    final activeLoad = _activeDashboardLoad;
    if (activeLoad != null) return activeLoad;
    if (state.data != null && !force) return Future<void>.value();

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      accessDenied: false,
    );
    final request = _fetchDashboard();
    _activeDashboardLoad = request;
    return request.whenComplete(() => _activeDashboardLoad = null);
  }

  Future<void> _fetchDashboard() async {
    try {
      final data = await _repository.fetchDashboard();
      state = state.copyWith(isLoading: false, data: data, clearError: true);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: _message(error),
        accessDenied: error is DashboardAccessException,
      );
    }
  }

  Future<void> loadPrediction({bool force = false}) {
    final activeLoad = _activePredictionLoad;
    if (activeLoad != null) return activeLoad;
    if (state.prediction != null && !force) return Future<void>.value();

    state = state.copyWith(
      isPredictionLoading: true,
      clearPredictionError: true,
    );
    final request = _fetchPrediction();
    _activePredictionLoad = request;
    return request.whenComplete(() => _activePredictionLoad = null);
  }

  Future<void> _fetchPrediction() async {
    try {
      final prediction = await _repository.fetchPredictionDashboard();
      state = state.copyWith(
        isPredictionLoading: false,
        prediction: prediction,
        clearPredictionError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isPredictionLoading: false,
        predictionError: _message(error),
      );
    }
  }

  Future<void> generatePrediction() {
    final activeGeneration = _activeGeneration;
    if (activeGeneration != null) return activeGeneration;

    state = state.copyWith(
      isGeneratingPrediction: true,
      clearPredictionError: true,
    );
    final request = _generatePrediction();
    _activeGeneration = request;
    return request.whenComplete(() => _activeGeneration = null);
  }

  Future<void> _generatePrediction() async {
    try {
      if (state.prediction == null) await loadPrediction();
      final points = await _repository.generateForecast();
      final current = state.prediction ?? const PredictionDashboard();
      state = state.copyWith(
        isGeneratingPrediction: false,
        prediction: current.withForecast(points),
        clearPredictionError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isGeneratingPrediction: false,
        predictionError: _message(error),
      );
    }
  }

  String _message(Object error) {
    if (error is DashboardAccessException) {
      return 'Este panel está disponible solo para usuarios administradores.';
    }
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401) return 'Tu sesión expiró. Inicia sesión de nuevo.';
      if (status == 403) return 'No tienes permisos para consultar este panel.';
      final response = error.response?.data;
      if (response is Map && response['detail'] != null) {
        return response['detail'].toString();
      }
      return 'No fue posible conectar con la API. Intenta nuevamente.';
    }
    return 'No se pudieron cargar los datos. Intenta nuevamente.';
  }
}
