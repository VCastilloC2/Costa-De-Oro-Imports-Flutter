import 'dart:io';

import 'package:costa_de_oro_imports/features/dashboard/data/dashboard_repository.dart';
import 'package:costa_de_oro_imports/features/dashboard/domain/dashboard_models.dart';
import 'package:costa_de_oro_imports/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shows the cached dashboard when the API is unreachable', () async {
    final cachedAt = DateTime.utc(2026, 11, 24, 19);
    final cachedData = _dashboardData();
    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          _OfflineDashboardRepository(
            DashboardSnapshot(data: cachedData, savedAt: cachedAt),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(dashboardProvider.notifier).load(userId: 12);

    final state = container.read(dashboardProvider);
    expect(state.data, same(cachedData));
    expect(state.lastUpdated, cachedAt);
    expect(state.syncStatus, DashboardSyncStatus.offline);
    expect(state.error, isNull);
  });

  test(
    'reports offline when neither API nor local data are available',
    () async {
      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            _OfflineDashboardRepository(null),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(dashboardProvider.notifier).load(userId: 12);

      final state = container.read(dashboardProvider);
      expect(state.data, isNull);
      expect(state.syncStatus, DashboardSyncStatus.offline);
      expect(state.error, contains('No hay conexión'));
    },
  );
}

class _OfflineDashboardRepository extends DashboardRepository {
  _OfflineDashboardRepository(this.cached)
    : super(Dio(BaseOptions(baseUrl: 'https://offline.invalid')));

  final DashboardSnapshot? cached;

  @override
  Future<DashboardSnapshot?> readCachedDashboard(int? userId) async => cached;

  @override
  Future<DashboardSnapshot> fetchDashboard(
    int? userId, {
    bool forceRefresh = false,
  }) async {
    throw DioException.connectionError(
      requestOptions: RequestOptions(path: '/api/graficas/dashboard'),
      reason: 'No network connection',
      error: const SocketException('No network connection'),
    );
  }
}

DashboardData _dashboardData() => const DashboardData(
  profile: UserProfile(name: 'Ana', role: 'ADMIN'),
  stats: DashboardStats(
    ingresosTotales: 100,
    gastosTotales: 40,
    beneficioTotal: 60,
    totalClientes: 2,
    comprasAnuales: 3,
    comprasAnioAnterior: 2,
    clientesAnioAnterior: 1,
  ),
  chartCategories: ['Ene'],
  chartIncomes: [100],
  chartExpenses: [40],
  donutItems: [],
  totalVentasDona: 100,
);
