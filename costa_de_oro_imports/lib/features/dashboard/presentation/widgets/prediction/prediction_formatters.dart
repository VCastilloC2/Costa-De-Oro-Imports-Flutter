import 'package:intl/intl.dart';

String formatCompactCop(double value) =>
    '\$${NumberFormat.compact(locale: 'es_CO').format(value)}';

String formatCop(double value) => NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
).format(value);
