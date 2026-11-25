import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent cache for explicitly opted-in GET requests.
/// Entries are scoped to the current bearer token and expire automatically.
class ApiResponseCache {
  static const _prefix = 'api_cache_v1_';

  Future<Response<dynamic>?> read(RequestOptions request, String? token) async {
    if (token == null || token.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(request, token));
    if (raw == null) return null;

    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(entry['expiresAt'] as String);
      if (!expiresAt.isAfter(DateTime.now())) {
        await prefs.remove(_key(request, token));
        return null;
      }
      return Response<dynamic>(
        requestOptions: request,
        data: entry['data'],
        statusCode: entry['statusCode'] as int? ?? 200,
        headers: Headers.fromMap(const {}),
        extra: const {'fromCache': true},
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
      await prefs.setString(
        _key(response.requestOptions, token),
        jsonEncode({
          'data': response.data,
          'statusCode': response.statusCode,
          'expiresAt': DateTime.now().add(ttl).toIso8601String(),
        }),
      );
    } catch (_) {
      // A cache failure must never fail a successful API request.
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().where((key) => key.startsWith(_prefix))) {
        await prefs.remove(key);
      }
    } catch (_) {
      // Cache cleanup must not prevent logout or error handling.
    }
  }

  String _key(RequestOptions request, String token) {
    // Stable non-cryptographic fingerprint; the bearer token itself is never stored.
    var fingerprint = 0x811c9dc5;
    for (final unit in token.codeUnits) {
      fingerprint = ((fingerprint ^ unit) * 0x01000193) & 0xffffffff;
    }
    final query = request.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '$_prefix${fingerprint.toRadixString(16)}_${request.uri.path}_${jsonEncode(query.map((e) => [e.key, e.value]).toList())}';
  }
}
