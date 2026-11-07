import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el token de sesión de forma segura (Keystore en Android,
/// Keychain en iOS). Ninguna otra parte de la app toca el almacenamiento
/// directamente.
class SessionStorage {
  SessionStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'auth_token';

  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      // Si el almacenamiento falla, se trata como "sin sesión".
      return null;
    }
  }

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }
}

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorage(),
);
