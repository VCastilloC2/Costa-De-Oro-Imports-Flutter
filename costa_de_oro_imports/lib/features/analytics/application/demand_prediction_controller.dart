import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/demand_prediction_repository.dart';
import '../domain/demand_prediction.dart';

class DemandPredictionState {
  const DemandPredictionState({
    this.isLoading = false,
    this.prediction,
    this.error,
  });

  final bool isLoading;
  final DemandPrediction? prediction;
  final PredictionRequestException? error;

  DemandPredictionState copyWith({
    bool? isLoading,
    DemandPrediction? prediction,
    bool clearPrediction = false,
    PredictionRequestException? error,
    bool clearError = false,
  }) => DemandPredictionState(
    isLoading: isLoading ?? this.isLoading,
    prediction: clearPrediction ? null : prediction ?? this.prediction,
    error: clearError ? null : error ?? this.error,
  );
}

final demandPredictionProvider =
    NotifierProvider<DemandPredictionController, DemandPredictionState>(
      DemandPredictionController.new,
    );

class DemandPredictionController extends Notifier<DemandPredictionState> {
  late final DemandPredictionRepository _repository =
      DemandPredictionRepository(ApiClient());
  Future<void>? _activeRequest;

  @override
  DemandPredictionState build() => const DemandPredictionState();

  Future<void> load({bool force = false}) {
    final active = _activeRequest;
    if (active != null) return active;
    if (state.prediction != null && !force) return Future<void>.value();

    state = state.copyWith(isLoading: true, clearError: true);
    final request = _fetch();
    _activeRequest = request;
    return request.whenComplete(() => _activeRequest = null);
  }

  Future<void> _fetch() async {
    try {
      final prediction = await _repository.fetch();
      state = state.copyWith(
        isLoading: false,
        prediction: prediction,
        clearError: true,
      );
    } on PredictionRequestException catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: const PredictionRequestException(
          PredictionFailureKind.unexpected,
          'Ocurrió un error inesperado al cargar Analytics.',
        ),
      );
    }
  }
}
