import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Respuesta guardada para usar sin conexión.
class CachedResponse {
  const CachedResponse({required this.data, required this.savedAt});

  final Object? data;
  final DateTime savedAt;
}

/// Guarda la última respuesta de cada consulta a la API en el dispositivo,
/// para poder mostrarla cuando no hay conexión.
///
/// - Solo guarda datos de lectura (no tokens ni contraseñas: esos van en
///   `SessionStorage`, que es almacenamiento seguro).
/// - Se borra al cerrar sesión, así otra cuenta nunca ve datos ajenos.
/// - Si el almacenamiento falla, la app sigue funcionando sin caché.
class ResponseCache {
  ResponseCache({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  /// Instancia compartida por todos los clientes HTTP.
  static final instance = ResponseCache();

  static const _prefix = 'api_cache:';

  /// Más allá de esto el dato se considera demasiado viejo para mostrarlo.
  static const maxAge = Duration(days: 7);

  final SharedPreferencesAsync _preferences;

  static String keyFor(String method, Uri uri) =>
      '$_prefix${method.toUpperCase()} ${uri.path}'
      '${uri.hasQuery ? '?${uri.query}' : ''}';

  Future<void> write(String key, Object? data) async {
    try {
      final entry = jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'data': data,
      });
      await _preferences.setString(key, entry);
    } catch (error) {
      _log('write', error);
    }
  }

  Future<CachedResponse?> read(String key) async {
    try {
      final raw = await _preferences.getString(key);
      if (raw == null) {
        return null;
      }
      final entry = jsonDecode(raw);
      if (entry is! Map) {
        return null;
      }
      final savedAt = DateTime.tryParse('${entry['savedAt']}');
      if (savedAt == null || DateTime.now().difference(savedAt) > maxAge) {
        await _preferences.remove(key);
        return null;
      }
      return CachedResponse(data: entry['data'], savedAt: savedAt);
    } catch (error) {
      _log('read', error);
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final keys = await _preferences.getKeys();
      for (final key in keys.where((key) => key.startsWith(_prefix))) {
        await _preferences.remove(key);
      }
    } catch (error) {
      _log('clear', error);
    }
  }

  static void _log(String action, Object error) {
    if (kDebugMode) {
      debugPrint('[ResponseCache] $action: $error');
    }
  }
}
