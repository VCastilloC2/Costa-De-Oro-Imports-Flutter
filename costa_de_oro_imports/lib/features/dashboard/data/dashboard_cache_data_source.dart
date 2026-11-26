import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Respuestas originales necesarias para reconstruir los datos del dashboard.
class CachedDashboardResponses {
  const CachedDashboardResponses({
    required this.dashboardRoot,
    required this.incomeExpense,
    required this.totalSales,
    required this.savedAt,
  });

  final Map<String, dynamic> dashboardRoot;
  final Map<String, dynamic> incomeExpense;
  final Map<String, dynamic> totalSales;
  final DateTime savedAt;
}

/// Persiste la última respuesta válida del dashboard en el almacenamiento local.
///
/// Cada archivo se separa por identificador de usuario para evitar mostrar los
/// datos de una cuenta en otra. El archivo queda dentro del directorio privado
/// de soporte de la aplicación.
class DashboardCacheDataSource {
  DashboardCacheDataSource({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const _schemaVersion = 1;
  static const _cacheDirectoryName = 'dashboard_cache';
  static const _filePrefix = 'dashboard_user_';

  final Future<Directory> Function() _directoryProvider;

  /// Lee la copia local del usuario, o devuelve `null` si aún no existe.
  Future<CachedDashboardResponses?> read(int userId) async {
    final file = await _fileFor(userId);
    if (!await file.exists()) return null;

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'El caché del dashboard no es un objeto JSON.',
      );
    }

    if (decoded['schema_version'] != _schemaVersion) {
      throw const FormatException(
        'La versión del caché del dashboard no es compatible.',
      );
    }

    final dashboardRoot = _asMap(decoded['dashboard_root']);
    final incomeExpense = _asMap(decoded['income_expense']);
    final totalSales = _asMap(decoded['total_sales']);
    final savedAtValue = decoded['saved_at'];
    if (savedAtValue is! String) {
      throw const FormatException('El caché no contiene una fecha válida.');
    }

    final savedAt = DateTime.tryParse(savedAtValue);
    if (savedAt == null) {
      throw const FormatException(
        'La fecha del caché no tiene un formato válido.',
      );
    }

    return CachedDashboardResponses(
      dashboardRoot: dashboardRoot,
      incomeExpense: incomeExpense,
      totalSales: totalSales,
      savedAt: savedAt,
    );
  }

  /// Guarda las respuestas y la fecha de consulta en un único archivo.
  Future<void> write({
    required int userId,
    required Map<String, dynamic> dashboardRoot,
    required Map<String, dynamic> incomeExpense,
    required Map<String, dynamic> totalSales,
    required DateTime savedAt,
  }) async {
    final file = await _fileFor(userId);
    await file.parent.create(recursive: true);

    final payload = jsonEncode({
      'schema_version': _schemaVersion,
      'saved_at': savedAt.toUtc().toIso8601String(),
      'dashboard_root': dashboardRoot,
      'income_expense': incomeExpense,
      'total_sales': totalSales,
    });
    await file.writeAsString(payload, flush: true);
  }

  Future<File> _fileFor(int userId) async {
    if (userId <= 0) {
      throw ArgumentError.value(userId, 'userId', 'Debe ser mayor que cero.');
    }

    final supportDirectory = await _directoryProvider();
    return File(
      '${supportDirectory.path}${Platform.pathSeparator}'
      '$_cacheDirectoryName${Platform.pathSeparator}'
      '$_filePrefix$userId.json',
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is! Map) {
      throw const FormatException('El caché contiene una respuesta inválida.');
    }
    return Map<String, dynamic>.from(value);
  }
}
