/// Typed view models for the JSON returned by the FastAPI dashboard routes.
int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
double _double(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
String _string(Object? value, [String fallback = '']) =>
    value?.toString() ?? fallback;
List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false)
    : const [];

class DashboardProfile {
  const DashboardProfile({
    required this.name,
    required this.email,
    required this.role,
    this.image,
  });

  final String name;
  final String email;
  final String role;
  final String? image;

  factory DashboardProfile.fromJson(Map<String, dynamic> json) =>
      DashboardProfile(
        name:
            [json['nombres'], json['apellidos']]
                .whereType<String>()
                .map((part) => part.trim())
                .where((part) => part.isNotEmpty)
                .join(' ')
                .trim()
                .isEmpty
            ? 'Administrador'
            : [json['nombres'], json['apellidos']]
                  .whereType<String>()
                  .map((part) => part.trim())
                  .where((part) => part.isNotEmpty)
                  .join(' '),
        email: _string(json['correo']),
        role: _string(json['rol']).toUpperCase(),
        image: json['imagen']?.toString(),
      );
}

class DashboardMetrics {
  const DashboardMetrics({
    this.totalProducts = 0,
    this.totalClients = 0,
    this.totalPurchases = 0,
    this.totalSuppliers = 0,
    this.totalSales = 0,
    this.pendingPurchases = 0,
  });

  final int totalProducts;
  final int totalClients;
  final int totalPurchases;
  final int totalSuppliers;
  final double totalSales;
  final int pendingPurchases;

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) =>
      DashboardMetrics(
        totalProducts: _int(json['totalProductos']),
        totalClients: _int(json['totalClientes']),
        totalPurchases: _int(json['totalCompras']),
        totalSuppliers: _int(json['totalProveedores']),
        totalSales: _double(json['ventasTotales']),
        pendingPurchases: _int(json['comprasPendientes']),
      );
}

class RevenueExpenses {
  const RevenueExpenses({this.income = 0, this.expenses = 0, this.balance = 0});

  final double income;
  final double expenses;
  final double balance;

  factory RevenueExpenses.fromJson(Map<String, dynamic> json) =>
      RevenueExpenses(
        income: _double(json['ingresos']),
        expenses: _double(json['gastos']),
        balance: _double(json['balance']),
      );
}

class SalesPoint {
  const SalesPoint({required this.date, required this.amount});

  final DateTime? date;
  final double amount;

  factory SalesPoint.fromJson(Map<String, dynamic> json) => SalesPoint(
    date: DateTime.tryParse(_string(json['fecha'])),
    amount: _double(json['total'] ?? json['ventas']),
  );
}

class StockSalesPoint {
  const StockSalesPoint({
    required this.product,
    required this.stock,
    required this.unitsSold,
  });

  final String product;
  final int stock;
  final int unitsSold;

  factory StockSalesPoint.fromJson(Map<String, dynamic> json) =>
      StockSalesPoint(
        product: _string(json['producto'], 'Producto'),
        stock: _int(json['stock']),
        unitsSold: _int(json['unidadesVendidas']),
      );
}

class CitySalesPoint {
  const CitySalesPoint({required this.city, required this.amount});

  final String city;
  final double amount;

  factory CitySalesPoint.fromJson(Map<String, dynamic> json) => CitySalesPoint(
    city: _string(json['ciudad'], 'Sin ciudad'),
    amount: _double(json['ventas']),
  );
}

class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.image,
    this.brand,
    this.description,
    this.unitsSold = 0,
    this.sales = 0,
  });

  final int id;
  final String name;
  final double price;
  final int stock;
  final String? image;
  final String? brand;
  final String? description;
  final int unitsSold;
  final double sales;

  factory ProductSummary.fromJson(Map<String, dynamic> json) => ProductSummary(
    id: _int(json['producto_id']),
    name: _string(json['nombre'], 'Producto'),
    price: _double(json['precio']),
    stock: _int(json['stock']),
    image: json['imagen']?.toString(),
    brand: json['marca']?.toString(),
    description: json['descripcion']?.toString(),
  );

  ProductSummary withSales({int? unitsSold, double? sales}) => ProductSummary(
    id: id,
    name: name,
    price: price,
    stock: stock,
    image: image,
    brand: brand,
    description: description,
    unitsSold: unitsSold ?? this.unitsSold,
    sales: sales ?? this.sales,
  );
}

class PurchaseSummary {
  const PurchaseSummary({
    required this.id,
    required this.total,
    required this.status,
    this.date,
    this.paymentMethod,
  });

  final int id;
  final double total;
  final String status;
  final DateTime? date;
  final String? paymentMethod;

  factory PurchaseSummary.fromJson(Map<String, dynamic> json) =>
      PurchaseSummary(
        id: _int(json['compra_id']),
        total: _double(json['total']),
        status: _string(json['estado'], 'PENDIENTE').toUpperCase(),
        date: DateTime.tryParse(_string(json['fecha'])),
        paymentMethod: json['metodo_pago']?.toString(),
      );
}

class ForecastPoint {
  const ForecastPoint({
    required this.date,
    required this.type,
    this.actual,
    this.prediction = 0,
  });

  final DateTime? date;
  final String type;
  final double? actual;
  final double prediction;

  factory ForecastPoint.fromJson(Map<String, dynamic> json) => ForecastPoint(
    date: DateTime.tryParse(_string(json['fecha'])),
    type: _string(json['tipo']),
    actual: json['real'] == null ? null : _double(json['real']),
    prediction: _double(json['prediccion']),
  );
}

class PredictionDashboard {
  const PredictionDashboard({
    this.monthlySales = const [],
    this.stockSales = const [],
    this.citySales = const [],
    this.forecast = const [],
    this.totalSales = 0,
    this.purchaseCount = 0,
    this.message,
  });

  final List<SalesPoint> monthlySales;
  final List<StockSalesPoint> stockSales;
  final List<CitySalesPoint> citySales;
  final List<ForecastPoint> forecast;
  final double totalSales;
  final int purchaseCount;
  final String? message;

  factory PredictionDashboard.fromJson(Map<String, dynamic> json) =>
      PredictionDashboard(
        monthlySales: _maps(json['ventas_mensuales'])
            .map(SalesPoint.fromJson)
            .toList(growable: false),
        stockSales: _maps(json['stock_vs_ventas'])
            .map(StockSalesPoint.fromJson)
            .toList(growable: false),
        citySales: _maps(json['ventas_por_ciudad'])
            .map(CitySalesPoint.fromJson)
            .toList(growable: false),
        forecast: _maps(json['proyeccion_ventas'])
            .map(ForecastPoint.fromJson)
            .toList(growable: false),
        totalSales: _double(json['total_ventas']),
        purchaseCount: _int(json['cantidad_compras']),
        message: json['mensaje']?.toString(),
      );

  PredictionDashboard withForecast(List<ForecastPoint> points) =>
      PredictionDashboard(
        monthlySales: monthlySales,
        stockSales: stockSales,
        citySales: citySales,
        forecast: points,
        totalSales: totalSales,
        purchaseCount: purchaseCount,
        message: message,
      );
}

class DashboardData {
  const DashboardData({
    required this.profile,
    required this.metrics,
    required this.finances,
    required this.stockTotal,
    required this.salesHistory,
    required this.products,
    required this.topProducts,
    required this.recentPurchases,
    required this.mapMessage,
  });

  final DashboardProfile profile;
  final DashboardMetrics metrics;
  final RevenueExpenses finances;
  final int stockTotal;
  final List<SalesPoint> salesHistory;
  final List<ProductSummary> products;
  final List<ProductSummary> topProducts;
  final List<PurchaseSummary> recentPurchases;
  final String mapMessage;

  factory DashboardData.fromResponses({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> metrics,
    required Map<String, dynamic> finances,
    required Map<String, dynamic> inventory,
    required List<dynamic> history,
    required List<dynamic> products,
    required Map<String, dynamic> topProducts,
    required List<dynamic> purchases,
    required Map<String, dynamic> map,
  }) {
    final catalog = products
        .whereType<Map>()
        .map((item) => ProductSummary.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final soldById = <int, Map<String, dynamic>>{
      for (final row in _maps(topProducts['datos']))
        _int(row['productoId']): row,
    };
    final rankedProducts = catalog.map((product) {
      final sales = soldById[product.id];
      return product.withSales(
        unitsSold: _int(sales?['unidades']),
        sales: _double(sales?['ventas']),
      );
    }).toList()..sort((a, b) => b.sales.compareTo(a.sales));

    return DashboardData(
      profile: DashboardProfile.fromJson(profile),
      metrics: DashboardMetrics.fromJson(metrics),
      finances: RevenueExpenses.fromJson(finances),
      stockTotal: _int(inventory['stockTotal']),
      salesHistory: history
          .whereType<Map>()
          .map((row) => SalesPoint.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false),
      products: catalog,
      topProducts: rankedProducts
          .where((product) => product.unitsSold > 0)
          .take(6)
          .toList(growable: false),
      recentPurchases: purchases
          .whereType<Map>()
          .map(
            (row) => PurchaseSummary.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList(growable: false),
      mapMessage: _string(
        map['mensaje'],
        'La API no devolvió datos de ubicación.',
      ),
    );
  }
}
