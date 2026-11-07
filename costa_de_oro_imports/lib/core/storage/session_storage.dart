import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda la sesión devuelta por la API en almacenamiento seguro
/// (Keychain en iOS, Keystore/EncryptedSharedPreferences en Android).
///
/// Nunca guarda contraseñas: solo tokens y datos mínimos del usuario.
class SessionStorage {
  SessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  // Se mantiene la clave original para no cerrar sesiones ya guardadas.
  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const userKey = 'session_user';

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) =>
      _storage.write(key: accessTokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: accessTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: refreshTokenKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: refreshTokenKey);

  Future<void> saveUser(Map<String, dynamic> user) =>
      _storage.write(key: userKey, value: jsonEncode(user));

  Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: userKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }

  Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: accessTokenKey),
      _storage.delete(key: refreshTokenKey),
      _storage.delete(key: userKey),
    ]);
  }
}
