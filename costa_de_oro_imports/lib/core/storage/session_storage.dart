// RAMA: chore/Core
// ============================================================================
// STORAGE: SessionStorage
// ============================================================================
// Guarda el token de sesión y las credenciales biométricas de forma segura.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStorage {
  SessionStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  
  static const _tokenKey = 'auth_token';
  static const _biometricDeviceIdKey = 'biometric_device_id';
  static const _biometricSecretKey = 'biometric_device_secret';

  // ==========================================================================
  // BIOMETRÍA LOCAL
  // ==========================================================================
  Future<String?> readBiometricDeviceId() =>
      _storage.read(key: _biometricDeviceIdKey);
      
  Future<String?> readBiometricSecret() =>
      _storage.read(key: _biometricSecretKey);
      
  Future<void> saveBiometricCredential(String deviceId, String secret) async {
    await _storage.write(key: _biometricDeviceIdKey, value: deviceId);
    await _storage.write(key: _biometricSecretKey, value: secret);
  }

  /// Borra SOLO las credenciales biométricas (para desactivar la huella).
  Future<void> clearBiometricCredential() async {
    try {
      await _storage.delete(key: _biometricDeviceIdKey);
      await _storage.delete(key: _biometricSecretKey);
    } catch (_) {}
  }

  // ==========================================================================
  // TOKEN JWT
  // ==========================================================================
  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  /// Borra la sesión (token). Mantiene la huella para el próximo login.
  Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }
}

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorage(),
);