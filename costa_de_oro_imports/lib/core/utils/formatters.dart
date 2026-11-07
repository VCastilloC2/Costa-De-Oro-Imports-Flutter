import 'package:intl/intl.dart';

/// Formatos de números y fechas para toda la app (pesos colombianos).
class Formatters {
  Formatters._();

  static final _money = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 0,
  );
  static final _compactMoney = NumberFormat.compactCurrency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 1,
  );
  static final _number = NumberFormat.decimalPattern('es_CO');

  static const _months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  /// `$1.589.420`
  static String money(num value) => _money.format(value);

  /// `$1,6 M`: para cifras grandes en espacios pequeños.
  static String compactMoney(num value) =>
      value.abs() < 100000 ? money(value) : _compactMoney.format(value);

  /// `42.339`
  static String number(num value) => _number.format(value);

  /// `Ene`, `Feb`… (sin depender de los datos de fecha de `intl`).
  static String monthShort(DateTime date) => _months[date.month - 1];

  /// `12/01/2026`
  static String date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  /// Iniciales para avatares: "Ana Pérez" → "AP", "admin@x.com" → "A".
  static String initials(String value) {
    final parts = value
        .split('@')
        .first
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase());
    final result = parts.join();
    return result.isEmpty ? '?' : result;
  }
}
