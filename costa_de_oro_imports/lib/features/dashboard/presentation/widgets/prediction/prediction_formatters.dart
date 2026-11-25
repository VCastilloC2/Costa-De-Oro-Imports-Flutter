import 'package:intl/intl.dart';

/// Formatea una cantidad de pesos colombianos con abreviatura localizada.
String formatCompactCop(double value) =>
    '\$${NumberFormat.compact(locale: 'es_CO').format(value)}';

/// Formatea una cantidad completa de pesos colombianos sin decimales.
String formatCop(double value) => NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
).format(value);
