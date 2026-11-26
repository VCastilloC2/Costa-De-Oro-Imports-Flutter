import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/statistics_repository.dart';
import 'dashboard_provider.dart';

class StatisticsSyncState {
  const StatisticsSyncState({
    this.hasNetwork,
    this.lastUpdated,
    this.loadingEndpoints = const {},
    this.cachedEndpoints = const {},
    this.offlineEndpoints = const {},
    this.failedEndpoints = const {},
    this.cacheSaveFailedEndpoints = const {},
  });

  final bool? hasNetwork;
  final DateTime? lastUpdated;
  final Set<String> loadingEndpoints;
  final Set<String> cachedEndpoints;
  final Set<String> offlineEndpoints;
  final Set<String> failedEndpoints;
  final Set<String> cacheSaveFailedEndpoints;

  bool get isLoading => loadingEndpoints.isNotEmpty;

  DashboardSyncStatus get status {
    if (hasNetwork == false || offlineEndpoints.isNotEmpty) {
      return DashboardSyncStatus.offline;
    }
    if (cacheSaveFailedEndpoints.isNotEmpty) {
      return DashboardSyncStatus.cacheSaveFailed;
    }
    if (cachedEndpoints.isNotEmpty || failedEndpoints.isNotEmpty) {
      return DashboardSyncStatus.updateFailed;
    }
    return DashboardSyncStatus.synced;
  }

  String? get message => switch (status) {
    DashboardSyncStatus.offline =>
      'Sin conexión. Mostrando los últimos datos guardados.',
    DashboardSyncStatus.updateFailed =>
      'No se pudo actualizar. Mostrando los últimos datos guardados.',
    DashboardSyncStatus.cacheSaveFailed =>
      'No se pudo guardar una copia local para usar el dashboard sin conexión.',
    DashboardSyncStatus.synced => null,
  };
}

final statisticsSyncProvider =
    NotifierProvider<StatisticsSyncController, StatisticsSyncState>(
      StatisticsSyncController.new,
    );

class StatisticsSyncController extends Notifier<StatisticsSyncState> {
  @override
  StatisticsSyncState build() {
    ref.watch(authControllerProvider.select((auth) => auth.user?.id));
    return const StatisticsSyncState();
  }

  void setConnection(bool hasNetwork) {
    state = StatisticsSyncState(
      hasNetwork: hasNetwork,
      lastUpdated: state.lastUpdated,
      loadingEndpoints: state.loadingEndpoints,
      cachedEndpoints: state.cachedEndpoints,
      offlineEndpoints: state.offlineEndpoints,
      failedEndpoints: state.failedEndpoints,
      cacheSaveFailedEndpoints: state.cacheSaveFailedEndpoints,
    );
  }

  void begin(String endpoint) {
    state = StatisticsSyncState(
      hasNetwork: state.hasNetwork,
      lastUpdated: state.lastUpdated,
      loadingEndpoints: {...state.loadingEndpoints, endpoint},
      cachedEndpoints: state.cachedEndpoints,
      offlineEndpoints: state.offlineEndpoints,
      failedEndpoints: state.failedEndpoints,
      cacheSaveFailedEndpoints: state.cacheSaveFailedEndpoints,
    );
  }

  void complete(String endpoint, StatisticsSnapshot snapshot) {
    final cached = {...state.cachedEndpoints};
    final offline = {...state.offlineEndpoints};
    final failed = {...state.failedEndpoints};
    final cacheSaveFailed = {...state.cacheSaveFailedEndpoints};
    if (snapshot.fromCache) {
      cached.add(endpoint);
      if (snapshot.isOffline) {
        offline.add(endpoint);
      } else {
        offline.remove(endpoint);
        failed.add(endpoint);
      }
    } else {
      cached.remove(endpoint);
      offline.remove(endpoint);
      failed.remove(endpoint);
    }
    if (snapshot.cacheWarning == null) {
      cacheSaveFailed.remove(endpoint);
    } else {
      cacheSaveFailed.add(endpoint);
    }

    state = StatisticsSyncState(
      hasNetwork: snapshot.isOffline ? state.hasNetwork : true,
      lastUpdated: snapshot.savedAt,
      loadingEndpoints: {...state.loadingEndpoints}..remove(endpoint),
      cachedEndpoints: cached,
      offlineEndpoints: offline,
      failedEndpoints: failed,
      cacheSaveFailedEndpoints: cacheSaveFailed,
    );
  }

  void fail(String endpoint, {required bool isOffline}) {
    final offline = {...state.offlineEndpoints};
    if (isOffline) {
      offline.add(endpoint);
    }
    state = StatisticsSyncState(
      hasNetwork: state.hasNetwork,
      lastUpdated: state.lastUpdated,
      loadingEndpoints: {...state.loadingEndpoints}..remove(endpoint),
      cachedEndpoints: state.cachedEndpoints,
      offlineEndpoints: offline,
      failedEndpoints: {...state.failedEndpoints, endpoint},
      cacheSaveFailedEndpoints: state.cacheSaveFailedEndpoints,
    );
  }
}
