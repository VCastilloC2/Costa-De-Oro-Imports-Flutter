// RAMA: feature/Dashboard
// ============================================================================
// MODELOS: Dashboard
// ============================================================================
// Define las clases necesarias para parsear la respuesta del backend.
// Incluye los nuevos campos para calcular las tendencias anuales.
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
  
  // NUEVOS CAMPOS PARA CALCULAR LAS TENDENCIAS REALES
  final int comprasAnioAnterior;
  final int clientesAnioAnterior;
  
  const DashboardStats({
    required this.ingresosTotales, 
    required this.gastosTotales, 
    required this.beneficioTotal,
    required this.totalClientes,
    required this.comprasAnuales,
    required this.comprasAnioAnterior,
    required this.clientesAnioAnterior,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json, Map<String, dynamic> root) => DashboardStats(
    ingresosTotales: (json['ingresosTotales'] as num?)?.toDouble() ?? 0.0,
    gastosTotales: (json['gastosTotales'] as num?)?.toDouble() ?? 0.0,
    beneficioTotal: (json['beneficioTotal'] as num?)?.toDouble() ?? 0.0,
    totalClientes: (root['totalClientes'] as num?)?.toInt() ?? 0,
    comprasAnuales: (root['comprasAnuales'] as num?)?.toInt() ?? 0,
    
    // Extraemos los nuevos datos desde la raiz del JSON
    comprasAnioAnterior: (root['comprasAnioAnterior'] as num?)?.toInt() ?? 0,
    clientesAnioAnterior: (root['clientesAnioAnterior'] as num?)?.toInt() ?? 0,
  );
}

// Clase para leer los items del nuevo JSON de la dona
class DonutItem {
  final String estado;
  final String nombre;
  final double monto;
  final int pedidos;
  final double montoAnterior;

  const DonutItem({
    required this.estado,
    required this.nombre,
    required this.monto,
    required this.pedidos,
    required this.montoAnterior,
  });

  factory DonutItem.fromJson(Map<String, dynamic> json) => DonutItem(
    estado: json['estado'] ?? '',
    nombre: json['nombre'] ?? '',
    monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
    pedidos: (json['pedidos'] as num?)?.toInt() ?? 0,
    montoAnterior: (json['montoAnterior'] as num?)?.toDouble() ?? 0.0,
  );
}

class DashboardData {
  final UserProfile profile;
  final DashboardStats stats;
  
  // Grafica de lineas
  final List<String> chartCategories;
  final List<double> chartIncomes;
  final List<double> chartExpenses;
  
  // Grafica de dona
  final List<DonutItem> donutItems;
  final double totalVentasDona;

  const DashboardData({
    required this.profile,
    required this.stats,
    required this.chartCategories,
    required this.chartIncomes,
    required this.chartExpenses,
    required this.donutItems,
    required this.totalVentasDona,
  });

  factory DashboardData.fromResponses({
    required Map<String, dynamic> dashboardRoot,
    required Map<String, dynamic> incomeExpense,
    required Map<String, dynamic> totalSales,
  }) {
    // Parseamos el arreglo "items" del backend
    final List<dynamic> rawItems = totalSales['items'] ?? [];
    final List<DonutItem> parsedItems = rawItems.map((e) => DonutItem.fromJson(e)).toList();

    return DashboardData(
      profile: UserProfile.fromJson(dashboardRoot['usuario'] ?? {}),
      stats: DashboardStats.fromJson(dashboardRoot['estadisticas'] ?? {}, dashboardRoot),
      
      chartCategories: (incomeExpense['categorias'] as List?)?.map((e) => e.toString()).toList() ?? [],
      chartIncomes: (incomeExpense['ingresos'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      chartExpenses: (incomeExpense['gastos'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      
      donutItems: parsedItems,
      totalVentasDona: (totalSales['totalMonto'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static final skeleton = DashboardData(
    profile: const UserProfile(name: 'Cargando...', role: 'ADMIN'),
    stats: const DashboardStats(
      ingresosTotales: 0, 
      gastosTotales: 0, 
      beneficioTotal: 0, 
      totalClientes: 0, 
      comprasAnuales: 0,
      comprasAnioAnterior: 0, 
      clientesAnioAnterior: 0,
    ),
    chartCategories: ['Ene', 'Feb'],
    chartIncomes: [0, 0],
    chartExpenses: [0, 0],
    donutItems: [],
    totalVentasDona: 0,
  );
}