import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_models.dart';

enum DashboardSyncStatus {
  loading,
  synced,
  offline,
  updateFailed,
  cacheSaveFailed,
}

class DashboardState {
  const DashboardState({
    this.isLoading = true,
    this.error,
    this.data,
    this.lastUpdated,
    this.syncStatus = DashboardSyncStatus.loading,
    this.syncMessage,
  });

  final bool isLoading;
  final String? error;
  final DashboardData? data;
  final DateTime? lastUpdated;
  final DashboardSyncStatus syncStatus;
  final String? syncMessage;

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    DashboardData? data,
    DateTime? lastUpdated,
    DashboardSyncStatus? syncStatus,
    String? syncMessage,
    bool clearSyncMessage = false,
  }) => DashboardState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    data: data ?? this.data,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    syncStatus: syncStatus ?? this.syncStatus,
    syncMessage: clearSyncMessage ? null : syncMessage ?? this.syncMessage,
  );
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dioProvider)),
);

final dashboardProvider = NotifierProvider<DashboardController, DashboardState>(
  DashboardController.new,
);

class DashboardController extends Notifier<DashboardState> {
  int? _loadedUserId;
  Future<void>? _inFlight;
  bool _knownOffline = false;
  int _requestGeneration = 0;

  @override
  DashboardState build() => const DashboardState();

  Future<void> load({int? userId, bool force = false}) {
    final accountChanged = userId != null && userId != _loadedUserId;
    if (accountChanged) {
      _loadedUserId = userId;
      _requestGeneration++;
      _inFlight = null;
      state = const DashboardState();
      force = true;
    }
    if (_inFlight != null) return _inFlight!;
    if (state.data != null && !force) return Future<void>.value();

    final generation = _requestGeneration;
    final operation = _load(
      userId: userId,
      force: force,
      generation: generation,
    );
    _inFlight = operation.whenComplete(() {
      if (generation == _requestGeneration) _inFlight = null;
    });
    return _inFlight!;
  }

  Future<void> _load({
    required int? userId,
    required bool force,
    required int generation,
  }) async {
    final previous = state;
    state = DashboardState(
      isLoading: true,
      data: previous.data,
      lastUpdated: previous.lastUpdated,
      syncStatus: previous.syncStatus,
      syncMessage: previous.syncMessage,
    );

    final repository = ref.read(dashboardRepositoryProvider);
    DashboardSnapshot? cached;
    Object? cacheReadError;
    try {
      cached = await repository.readCachedDashboard(userId);
      if (generation != _requestGeneration) return;
      if (cached != null && previous.data == null) {
        state = DashboardState(
          isLoading: true,
          data: cached.data,
          lastUpdated: cached.savedAt,
          syncStatus: _knownOffline
              ? DashboardSyncStatus.offline
              : DashboardSyncStatus.synced,
          syncMessage: _knownOffline
              ? 'Sin conexión. Mostrando los últimos datos guardados.'
              : null,
        );
      }
    } catch (error, stackTrace) {
      if (generation != _requestGeneration) return;
      cacheReadError = error;
      developer.log(
        'No se pudo leer la copia local del dashboard.',
        name: 'dashboard.controller',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      final fresh = await repository.fetchDashboard(
        userId,
        forceRefresh: force,
      );
      if (generation != _requestGeneration) return;
      final offline = fresh.isStale || _knownOffline;
      final syncStatus = fresh.cacheWarning != null
          ? DashboardSyncStatus.cacheSaveFailed
          : offline
          ? DashboardSyncStatus.offline
          : DashboardSyncStatus.synced;
      state = DashboardState(
        data: fresh.data,
        lastUpdated: fresh.savedAt,
        syncStatus: syncStatus,
        syncMessage:
            fresh.cacheWarning ??
            (offline
                ? 'Sin conexión. Mostrando los últimos datos guardados.'
                : null),
      );
    } on DioException catch (error, stackTrace) {
      if (generation != _requestGeneration) return;
      final fallback =
          cached ?? _snapshotFrom(state) ?? _snapshotFrom(previous);
      final canUseFallback = _canUseCachedData(error);
      developer.log(
        'No se pudo actualizar el dashboard desde el backend.',
        name: 'dashboard.controller',
        error: error,
        stackTrace: stackTrace,
      );
      if (fallback != null && canUseFallback) {
        final offline = _isConnectionFailure(error) || _knownOffline;
        state = DashboardState(
          data: fallback.data,
          lastUpdated: fallback.savedAt,
          syncStatus: offline
              ? DashboardSyncStatus.offline
              : DashboardSyncStatus.updateFailed,
          syncMessage: offline
              ? 'Sin conexión. Mostrando los últimos datos guardados.'
              : 'No se pudo actualizar. Mostrando los últimos datos guardados.',
        );
        return;
      }
      _setLoadFailure(error, cacheReadError);
    } catch (error, stackTrace) {
      if (generation != _requestGeneration) return;
      final fallback =
          cached ?? _snapshotFrom(state) ?? _snapshotFrom(previous);
      developer.log(
        'Ocurrió un error al procesar los datos del dashboard.',
        name: 'dashboard.controller',
        error: error,
        stackTrace: stackTrace,
      );
      if (fallback != null) {
        state = DashboardState(
          data: fallback.data,
          lastUpdated: fallback.savedAt,
          syncStatus: DashboardSyncStatus.updateFailed,
          syncMessage: 'No se pudo completar la actualización. Mostrando los últimos datos guardados.',
        );
        return;
      }
      _setLoadFailure(error, cacheReadError);
    }
  }

  void _setLoadFailure(Object error, Object? cacheReadError) {
    final offline = error is DioException && _isConnectionFailure(error);
    state = DashboardState(
      error: cacheReadError != null
          ? 'No se pudieron cargar los datos ni leer la copia guardada.'
          : offline
          ? 'No hay conexión ni datos guardados en este dispositivo.'
          : 'No se pudieron cargar los datos del dashboard.',
      syncStatus: offline
          ? DashboardSyncStatus.offline
          : DashboardSyncStatus.updateFailed,
      syncMessage: offline && _knownOffline
          ? 'Conéctate a internet para cargar el dashboard por primera vez.'
          : null,
    );
  }

  DashboardSnapshot? _snapshotFrom(DashboardState value) {
    final data = value.data;
    final lastUpdated = value.lastUpdated;
    if (data == null || lastUpdated == null) return null;
    return DashboardSnapshot(data: data, savedAt: lastUpdated);
  }

  bool _canUseCachedData(DioException error) =>
      _isConnectionFailure(error) ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      (error.response?.statusCode != null &&
          error.response!.statusCode! >= 500);

  bool _isConnectionFailure(DioException error) =>
      error.response == null &&
      (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.error is SocketException);

  void markConnectionUnavailable() {
    _knownOffline = true;
    final current = state;
    state = DashboardState(
      isLoading: current.isLoading,
      data: current.data,
      lastUpdated: current.lastUpdated,
      syncStatus: DashboardSyncStatus.offline,
      syncMessage: current.data == null
          ? 'Sin conexión. Se intentará cargar el dashboard al volver a conectarte.'
          : 'Sin conexión. Mostrando los últimos datos guardados.',
      error: current.data == null ? current.error : null,
    );
  }

  void markConnectionAvailable() {
    _knownOffline = false;
  }
}
