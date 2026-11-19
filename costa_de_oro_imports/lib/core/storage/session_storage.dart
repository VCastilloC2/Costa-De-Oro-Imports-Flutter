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
  static const _biometricDeviceIdKey = 'biometric_device_id';
  static const _biometricSecretKey = 'biometric_device_secret';

  Future<String?> readBiometricDeviceId() => _storage.read(key: _biometricDeviceIdKey);
  Future<String?> readBiometricSecret() => _storage.read(key: _biometricSecretKey);
  Future<void> saveBiometricCredential(String deviceId, String secret) async {
    await _storage.write(key: _biometricDeviceIdKey, value: deviceId);
    await _storage.write(key: _biometricSecretKey, value: secret);
  }

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
