import 'package:costa_de_oro_imports/features/dashboard/domain/dashboard_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductSummary.fromJson', () {
    test('parses the fields returned by the API', () {
      final product = ProductSummary.fromJson({
        'producto_id': 7,
        'nombre': 'Ron Añejo',
        'precio': 92000,
        'stock': '30',
        'marca': 'Costa de Oro',
      });

      expect(product.id, 7);
      expect(product.name, 'Ron Añejo');
      expect(product.price, 92000.0);
      expect(product.stock, 30);
      expect(product.brand, 'Costa de Oro');
      expect(product.image, isNull);
    });

    test('falls back to defaults when fields are missing', () {
      final product = ProductSummary.fromJson({});

      expect(product.id, 0);
      expect(product.name, 'Producto');
      expect(product.price, 0);
      expect(product.stock, 0);
    });
  });

  group('DashboardData.skeleton', () {
    test('has data in every section so the skeleton fills the panel', () {
      final data = DashboardData.skeleton;

      expect(data.salesHistory, isNotEmpty);
      expect(data.topProducts.where((p) => p.sales > 0), isNotEmpty);
      expect(data.metrics.totalSales, greaterThan(0));
      expect(data.profile.name, isNotEmpty);
    });
  });
}
