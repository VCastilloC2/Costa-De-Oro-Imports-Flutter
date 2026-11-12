// RAMA: feature/Dashboard
// ============================================================================
// MODELOS: Dashboard (Adaptados a los nuevos JSON del backend)
// ============================================================================

class UserProfile {
  final String name;
  final String role;
  
  const UserProfile({required this.name, required this.role});

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: '${json['nombres'] ?? ''} ${json['apellidos'] ?? ''}'.trim(),
    role: json['rol'] ?? 'ADMIN',
  );
}

class DashboardStats {
  final double ingresosTotales;
  final double gastosTotales;
  final double beneficioTotal;
  final int totalClientes;
  final int comprasAnuales;
  
  const DashboardStats({
    required this.ingresosTotales, 
    required this.gastosTotales, 
    required this.beneficioTotal,
    required this.totalClientes,
    required this.comprasAnuales,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json, Map<String, dynamic> root) => DashboardStats(
    ingresosTotales: (json['ingresosTotales'] as num?)?.toDouble() ?? 0.0,
    gastosTotales: (json['gastosTotales'] as num?)?.toDouble() ?? 0.0,
    beneficioTotal: (json['beneficioTotal'] as num?)?.toDouble() ?? 0.0,
    totalClientes: (root['totalClientes'] as num?)?.toInt() ?? 0,
    comprasAnuales: (root['comprasAnuales'] as num?)?.toInt() ?? 0,
  );
}

class DashboardData {
  final UserProfile profile;
  final DashboardStats stats;
  
  // Gráfica de líneas
  final List<String> chartCategories;
  final List<double> chartIncomes;
  final List<double> chartExpenses;
  
  // Gráfica de dona
  final List<double> donutSeries;
  final List<String> donutLabels;
  final double totalVentasDona;

  const DashboardData({
    required this.profile,
    required this.stats,
    required this.chartCategories,
    required this.chartIncomes,
    required this.chartExpenses,
    required this.donutSeries,
    required this.donutLabels,
    required this.totalVentasDona,
  });

  factory DashboardData.fromResponses({
    required Map<String, dynamic> dashboardRoot,
    required Map<String, dynamic> incomeExpense,
    required Map<String, dynamic> totalSales,
  }) {
    return DashboardData(
      profile: UserProfile.fromJson(dashboardRoot['usuario'] ?? {}),
      stats: DashboardStats.fromJson(dashboardRoot['estadisticas'] ?? {}, dashboardRoot),
      
      chartCategories: (incomeExpense['categorias'] as List?)?.map((e) => e.toString()).toList() ?? [],
      chartIncomes: (incomeExpense['ingresos'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      chartExpenses: (incomeExpense['gastos'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      
      donutSeries: (totalSales['series'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      donutLabels: (totalSales['labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
      totalVentasDona: (totalSales['totalVentas'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static final skeleton = DashboardData(
    profile: const UserProfile(name: 'Cargando...', role: 'ADMIN'),
    stats: const DashboardStats(ingresosTotales: 0, gastosTotales: 0, beneficioTotal: 0, totalClientes: 0, comprasAnuales: 0),
    chartCategories: ['Ene', 'Feb'],
    chartIncomes: [0, 0],
    chartExpenses: [0, 0],
    donutSeries: [1],
    donutLabels: ['Cargando'],
    totalVentasDona: 0,
  );
}