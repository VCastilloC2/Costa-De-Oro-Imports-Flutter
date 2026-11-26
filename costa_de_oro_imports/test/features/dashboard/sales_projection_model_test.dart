import 'package:costa_de_oro_imports/features/dashboard/domain/sales_projection_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts backend year categories to chart years', () {
    final data = SalesProjectionData.fromJson({
      'series': [117900000],
      'categorias': [2021000],
      'maxVenta': 250000000,
      'minVenta': 50000000,
      'promedioVentas': 117900000,
    });

    expect(data.categorias, [2021]);
  });
}
