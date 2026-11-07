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

  // ---------------------------------------------------------------------------
  // PASSKEYS
  // ---------------------------------------------------------------------------
  // Solo se guardan marcas no secretas: la clave privada vive en el Secure
  // Enclave / Keystore y la clave pública en el backend. [clear] (logout)
  // NO borra estas marcas a propósito: la passkey sigue existiendo en el
  // dispositivo y el siguiente login debe poder ofrecer Face ID / huella.

  static const _passkeyUserKey = 'passkey_user';
  static const _passkeyCredentialKey = 'passkey_credential_id';
  static const _passkeyOfferDismissedKey = 'passkey_offer_dismissed';

  /// Correo de la cuenta que registró o usó una passkey en este dispositivo.
  Future<String?> readPasskeyUser() => _safeRead(_passkeyUserKey);

  Future<void> savePasskeyUser(String correo) =>
      _safeWrite(_passkeyUserKey, correo);

  /// Borra la marca de passkey y el ID de credencial de este dispositivo.
  Future<void> clearPasskeyUser() async {
    await _safeDelete(_passkeyUserKey);
    await _safeDelete(_passkeyCredentialKey);
  }

  /// ID (base64url, público) de la última passkey usada en este dispositivo.
  /// Sirve para marcar "Este dispositivo" en la lista y para dejar de
  /// lanzar Face ID / huella si el usuario la revoca.
  Future<String?> readPasskeyCredentialId() => _safeRead(_passkeyCredentialKey);

  Future<void> savePasskeyCredentialId(String credentialId) =>
      _safeWrite(_passkeyCredentialKey, credentialId);

  /// `true` si el usuario rechazó activar la passkey tras iniciar sesión.
  Future<bool> readPasskeyOfferDismissed() async =>
      await _safeRead(_passkeyOfferDismissedKey) == 'true';

  Future<void> savePasskeyOfferDismissed() =>
      _safeWrite(_passkeyOfferDismissedKey, 'true');

  Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _safeWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Son marcas de conveniencia: si fallan, solo se pierde el aviso.
    }
  }

  Future<void> _safeDelete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }
}

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorage(),
);
