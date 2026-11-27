import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent cache for explicitly opted-in GET requests.
/// Entries are scoped to the current bearer token and expire automatically.
class ApiResponseCache {
  static const _prefix = 'api_cache_v1_';
  static const _maxEntries = 50;
  static const _maxEntryCharacters = 1000000;

  Future<Response<dynamic>?> read(
    RequestOptions request,
    String? token, {
    bool allowExpired = false,
  }) async {
    if (token == null || token.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(request, token));
    if (raw == null) return null;

    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(entry['expiresAt'] as String);
      final cachedAt = entry['cachedAt'] as String?;
      final stale = !expiresAt.isAfter(DateTime.now());
      if (stale && !allowExpired) {
        return null;
      }
      return Response<dynamic>(
        requestOptions: request,
        data: entry['data'],
        statusCode: entry['statusCode'] as int? ?? 200,
        headers: Headers.fromMap(const {}),
        extra: {
          'fromCache': true,
          'staleCache': stale,
          'cachedAt': cachedAt,
          'cacheExpiresAt': expiresAt.toIso8601String(),
        },
      );
    } catch (_) {
      await prefs.remove(_key(request, token));
      return null;
    }
  }

  Future<void> write(
    Response<dynamic> response,
    String? token,
    Duration ttl,
  ) async {
    if (token == null || token.isEmpty || ttl <= Duration.zero) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final encoded = jsonEncode({
        'data': response.data,
        'statusCode': response.statusCode,
        'cachedAt': now.toIso8601String(),
        'expiresAt': now.add(ttl).toIso8601String(),
      });
      // No llenes SharedPreferences con reportes grandes; la app aún puede
      // usar los datos en memoria durante la sesión actual.
      if (encoded.length > _maxEntryCharacters) return;
      await _prune(prefs, now);
      await prefs.setString(_key(response.requestOptions, token), encoded);
    } catch (_) {
      // A cache failure must never fail a successful API request.
    }
  }

  /// Invalida todas las variantes de una ruta para el token autenticado.
  Future<void> invalidatePath(
    Uri requestUri,
    String path,
    String? token,
  ) async {
    if (token == null || token.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final fingerprint = _tokenFingerprint(token).toRadixString(16);
      final prefix =
          '$_prefix${fingerprint}_${requestUri.host}_$path'
          '_';
      for (final key in prefs.getKeys().where(
        (key) => key.startsWith(prefix),
      )) {
        await prefs.remove(key);
      }
    } catch (_) {
      // Una falla de invalidación no debe convertir en error una operación exitosa.
    }
  }

  Future<void> _prune(SharedPreferences prefs, DateTime now) async {
    final entries = <(String, DateTime)>[];
    for (final key in prefs.getKeys().where((key) => key.startsWith(_prefix))) {
      try {
        final raw = prefs.getString(key);
        if (raw == null) {
          await prefs.remove(key);
          continue;
        }
        final entry = jsonDecode(raw) as Map<String, dynamic>;
        final expiresAt = DateTime.parse(entry['expiresAt'] as String);
        if (!expiresAt.isAfter(now)) {
          await prefs.remove(key);
          continue;
        }
        final cachedAt =
            DateTime.tryParse(entry['cachedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        entries.add((key, cachedAt));
      } catch (_) {
        await prefs.remove(key);
      }
    }
    entries.sort((a, b) => a.$2.compareTo(b.$2));
    final overflow = entries.length - _maxEntries + 1;
    for (final entry in entries.take(overflow > 0 ? overflow : 0)) {
      await prefs.remove(entry.$1);
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().where(
        (key) => key.startsWith(_prefix),
      )) {
        await prefs.remove(key);
      }
    } catch (_) {
      // Cache cleanup must not prevent logout or error handling.
    }
  }

  String _key(RequestOptions request, String token) {
    // Stable non-cryptographic fingerprint; the bearer token itself is never stored.
    final fingerprint = _tokenFingerprint(token).toRadixString(16);
    final query = request.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '$_prefix${fingerprint}_${request.uri.host}_${request.uri.path}_${jsonEncode(query.map((e) => [e.key, e.value]).toList())}';
  }

  int _tokenFingerprint(String token) {
    var fingerprint = 0x811c9dc5;
    for (final unit in token.codeUnits) {
      fingerprint = ((fingerprint ^ unit) * 0x01000193) & 0xffffffff;
    }
    return fingerprint;
  }
}
