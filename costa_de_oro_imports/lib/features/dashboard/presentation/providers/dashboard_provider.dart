// RAMA: feature/Dashboard
// ============================================================================
// PROVIDER: dashboardProvider
// Ubicacion: lib/features/dashboard/presentation/providers/dashboard_provider.dart
//
// Cambios respecto a la version anterior:
//  1. Estado inicial con isLoading = true (evita el parpadeo del aviso de
//     "Dashboard no disponible" antes del skeleton).
//  2. Si cambia la cuenta (otro userId), se descartan los datos en memoria
//     para no mostrar el dashboard de la cuenta anterior.
// ============================================================================

import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_models.dart';

enum DashboardSyncStatus { synced, offline, updateFailed, cacheSaveFailed }

class DashboardState {
  const DashboardState({
    this.isLoading = false,
    this.error,
    this.data,
    this.lastUpdated,
    this.syncStatus = DashboardSyncStatus.synced,
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
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      data: data ?? this.data,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      syncStatus: syncStatus ?? this.syncStatus,
      syncMessage: clearSyncMessage
          ? null
          : syncMessage ?? this.syncMessage,
    );
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

final dashboardProvider = NotifierProvider<DashboardController, DashboardState>(
  DashboardController.new,
);

class DashboardController extends Notifier<DashboardState> {
  /// Cuenta a la que pertenecen los datos que hay en memoria.
  int? _loadedUserId;

  // Arranca "cargando": la pantalla muestra el skeleton desde el primer frame
  // en lugar de un estado vacio que dura un instante.
  @override
  DashboardState build() => const DashboardState(isLoading: true);

  void markConnectionUnavailable() {
    final current = state;
    state = DashboardState(
      isLoading: current.isLoading,
      data: current.data,
      lastUpdated: current.lastUpdated,
      syncStatus: DashboardSyncStatus.offline,
      syncMessage: current.data == null
          ? null
          : 'Sin conexión. Mostrando los últimos datos guardados.',
      error: current.data == null
          ? 'No hay conexión. Se intentará cargar el dashboard al volver a conectarte.'
          : null,
    );
  }

  Future<void> load({int? userId, bool force = false}) async {
    // Otra cuenta: no reutilizar lo que hay en memoria.
    if (userId != null && userId != _loadedUserId) {
      _loadedUserId = userId;
      state = const DashboardState(isLoading: true);
      force = true;
    }

    if (state.data != null && !force) return;

    final previousState = state;
    state = DashboardState(
      isLoading: true,
      data: previousState.data,
      lastUpdated: previousState.lastUpdated,
      syncStatus: previousState.syncStatus,
      syncMessage: previousState.syncMessage,
    );

    final repository = ref.read(dashboardRepositoryProvider);
    DashboardSnapshot? cached;
    Object? cacheReadError;

    try {
      cached = await repository.readCachedDashboard(userId);
      if (cached != null) {
        state = DashboardState(
          isLoading: true,
          data: cached.data,
          lastUpdated: cached.savedAt,
        );
      }
    } catch (error, stackTrace) {
      cacheReadError = error;
      developer.log(
        'No se pudo leer la copia local del dashboard.',
        name: 'dashboard.controller',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      final fresh = await repository.fetchDashboard(userId);
      state = DashboardState(
        data: fresh.data,
        lastUpdated: fresh.savedAt,
        syncStatus: fresh.cacheWarning == null
            ? DashboardSyncStatus.synced
            : DashboardSyncStatus.cacheSaveFailed,
        syncMessage: fresh.cacheWarning,
      );
    } on DioException catch (error, stackTrace) {
      final fallback = cached ?? _snapshotFrom(previousState);
      final canUseFallback = _canUseCachedData(error);

      developer.log(
        'No se pudo actualizar el dashboard desde el servicio.',
        name: 'dashboard.controller',
        error: error,
        stackTrace: stackTrace,
      );

      if (canUseFallback && fallback != null) {
        final isOffline = _isConnectionFailure(error);
        state = DashboardState(
          data: fallback.data,
          lastUpdated: fallback.savedAt,
          syncStatus: isOffline
              ? DashboardSyncStatus.offline
              : DashboardSyncStatus.updateFailed,
          syncMessage: isOffline
              ? 'Sin conexión. Mostrando los últimos datos guardados.'
              : 'No se pudo actualizar. Mostrando los últimos datos guardados.',
        );
        return;
      }

      state = DashboardState(
        error: cacheReadError != null
            ? 'No se pudieron cargar los datos ni leer la copia guardada.'
            : _isConnectionFailure(error)
            ? 'No hay conexión ni datos guardados en este dispositivo.'
            : 'No se pudieron cargar los datos del dashboard.',
        syncStatus: _isConnectionFailure(error)
            ? DashboardSyncStatus.offline
            : DashboardSyncStatus.updateFailed,
      );
    } catch (error, stackTrace) {
      final fallback = cached ?? _snapshotFrom(previousState);
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
          syncMessage:
              'No se pudo completar la actualización. Mostrando los últimos datos guardados.',
        );
        return;
      }

      state = DashboardState(
        error: cacheReadError != null
            ? 'No se pudieron cargar los datos ni leer la copia guardada.'
            : 'Ocurrió un error al cargar el dashboard.',
        syncStatus: DashboardSyncStatus.updateFailed,
      );
    }
  }

  DashboardSnapshot? _snapshotFrom(DashboardState value) {
    final data = value.data;
    final lastUpdated = value.lastUpdated;
    if (data == null || lastUpdated == null) return null;
    return DashboardSnapshot(data: data, savedAt: lastUpdated);
  }

  bool _canUseCachedData(DioException error) {
    return _isConnectionFailure(error) ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }

  bool _isConnectionFailure(DioException error) {
    return error.response == null &&
        (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.error is SocketException);
  }
}
