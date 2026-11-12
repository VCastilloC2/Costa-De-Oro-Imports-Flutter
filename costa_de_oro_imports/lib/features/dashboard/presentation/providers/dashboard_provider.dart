// RAMA: feature/Dashboard
// ============================================================================
// PROVIDER: Dashboard
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart'; // Tu dioProvider está aquí
import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_models.dart';

class DashboardState {
  const DashboardState({this.isLoading = false, this.error, this.data});
  
  final bool isLoading;
  final String? error;
  final DashboardData? data;

  DashboardState copyWith({bool? isLoading, String? error, bool clearError = false, DashboardData? data}) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      data: data ?? this.data,
    );
  }
}

final dashboardProvider = NotifierProvider<DashboardController, DashboardState>(DashboardController.new);

class DashboardController extends Notifier<DashboardState> {
  @override
  DashboardState build() => const DashboardState();

  Future<void> load({bool force = false}) async {
    if (state.data != null && !force) return;

    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Aquí usamos tu dioProvider
      final dio = ref.read(dioProvider);
      final repository = DashboardRepository(dio);
      
      final data = await repository.fetchDashboard();
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'No se pudieron cargar los datos.');
    }
  }
}