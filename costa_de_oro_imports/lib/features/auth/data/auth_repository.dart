// RAMA: feature/Auth
// ============================================================================
// REPOSITORIO: AuthRepository
// ============================================================================
// Capa de datos encargada de comunicarse con los endpoints de autenticación.
// Maneja el almacenamiento del token JWT y la conversión de excepciones HTTP.
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:costa_de_oro_imports/core/network/api_client.dart';
import 'package:costa_de_oro_imports/core/network/api_exception.dart';
import 'package:costa_de_oro_imports/core/storage/response_cache.dart';
import 'package:costa_de_oro_imports/core/storage/session_storage.dart';
import 'package:costa_de_oro_imports/features/auth/data/models/user_model.dart';
import 'package:costa_de_oro_imports/features/auth/data/passkey_service.dart';
import 'package:costa_de_oro_imports/features/auth/data/social_auth_service.dart';

class AuthRepository {
  AuthRepository(
    this._dio,
    this._storage, {
    SocialAuthService? socialAuth,
    ResponseCache? cache,
    PasskeyService? passkeys,
  }) : _socialAuth = socialAuth ?? SocialAuthService(),
       _cache = cache ?? ResponseCache.instance,
       _passkeys = passkeys ?? PasskeyService();

  final Dio _dio;
  final SessionStorage _storage;
  final SocialAuthService _socialAuth;

  /// Ceremonias WebAuthn en el dispositivo (Face ID, Touch ID, huella).
  final PasskeyService _passkeys;

  /// Datos guardados para usar sin conexión; se borran al cambiar de sesión.
  final ResponseCache _cache;

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------
  /// Envía las credenciales al backend. Si la respuesta es exitosa, extrae el
  /// token y los datos del usuario, guardando el token localmente.
  Future<UserModel> login({required String correo, required String password}) {
    return _authenticate('/auth/login', {
      'correo': correo.trim(),
      'password': password,
    });
  }

  // ---------------------------------------------------------------------------
  // LOGIN SOCIAL
  // ---------------------------------------------------------------------------
  /// Envía el ID token de Google al backend, que lo valida y crea o inicia
  /// la sesión del usuario. Contrato: `POST /auth/google {"id_token": ...}`.
  Future<UserModel> loginWithGoogle(String idToken) {
    return _authenticate('/auth/google', {'id_token': idToken});
  }

  /// Envía el identity token de Apple al backend.
  /// Contrato: `POST /auth/apple {"id_token": ..., "nombres"?, "apellidos"?}`.
  /// Apple solo comparte el nombre en la primera autorización, por eso se
  /// reenvía cuando viene para que el backend pueda registrar al usuario.
  Future<UserModel> loginWithApple(
    String identityToken, {
    String? givenName,
    String? familyName,
  }) {
    return _authenticate('/auth/apple', {
      'id_token': identityToken,
      if (givenName != null && givenName.isNotEmpty) 'nombres': givenName,
      if (familyName != null && familyName.isNotEmpty) 'apellidos': familyName,
    });
  }

  /// Flujo común de login: llama al endpoint, guarda el token y devuelve el
  /// usuario (de la respuesta o, si no viene anidado, de `/perfil`).
  Future<UserModel> _authenticate(
    String path,
    Map<String, dynamic> body,
  ) async {
    final String token;
    try {
      final res = await _dio.post<dynamic>(path, data: body);

      final data = res.data;
      token = _extractToken(data);

      // El backend devuelve el objeto 'usuario' dentro del login.
      // Se extrae directamente para evitar peticiones adicionales a /perfil.
      if (data is Map && data['usuario'] is Map<String, dynamic>) {
        await _startSession(token);
        return UserModel.fromJson(data['usuario']);
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Error crudo del backend en $path: ${e.response?.data}');
      }
      throw ApiException.fromDio(e);
    }

    // Respaldo: Si el backend no anida el usuario, se solicita a /perfil.
    await _startSession(token);
    return await fetchProfile();
  }

  /// Guarda el token nuevo y descarta los datos sin conexión de cualquier
  /// sesión anterior (podría ser de otra cuenta).
  Future<void> _startSession(String token) async {
    await _cache.clear();
    await _storage.saveToken(token);
  }

  // ---------------------------------------------------------------------------
  // REGISTRO
  // ---------------------------------------------------------------------------
  /// Crea un nuevo usuario. El backend requiere múltiples campos, por lo que
  /// se inyectan datos genéricos que el usuario completará en feature/Profile.
  Future<UserModel> register({
    required String correo,
    required String password,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    final randomId = now.substring(now.length - 10);
    final nombreProvisional = correo.split('@').first;

    try {
      await _dio.post<dynamic>(
        '/auth/registro',
        data: {
          'correo': correo.trim(),
          'password': password,
          'tipoIdentificacion': 'CC',
          'numeroIdentificacion': randomId,
          'nombres': nombreProvisional,
          'apellidos': 'Pendiente',
          'telefono': randomId,
          'direccion': 'Por definir $randomId',
          'rol': 'PERSONA_NATURAL',
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }

    // Pausa para asegurar la transacción en la base de datos antes del auto-login.
    await Future.delayed(const Duration(seconds: 1));

    return login(correo: correo, password: password);
  }

  // ---------------------------------------------------------------------------
  // ACTUALIZAR PERFIL
  // ---------------------------------------------------------------------------
  /// Método utilizado por feature/Profile para actualizar los datos del usuario.
  Future<UserModel> updateProfile({
    required String nombres,
    required String apellidos,
    required String telefono,
    required String direccion,
    required String tipoIdentificacion,
    required String numeroIdentificacion,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/perfil',
        data: {
          'nombres': nombres.trim(),
          'apellidos': apellidos.trim(),
          'telefono': telefono.trim(),
          'direccion': direccion.trim(),
          'tipoIdentificacion': tipoIdentificacion,
          'numeroIdentificacion': numeroIdentificacion.trim(),
        },
      );
      return await fetchProfile();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // SESIÓN
  // ---------------------------------------------------------------------------
  Future<UserModel> fetchProfile() async {
    try {
      final res = await _dio.get<dynamic>('/perfil');
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Respuesta de perfil inesperada.');
      }
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel?> restoreSession() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      return await fetchProfile();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _storage.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<dynamic>('/auth/logout');
    } catch (_) {
      // La sesión local se borra aunque la API no responda.
    }
    await _storage.clear();
    await _cache.clear();
    // Para que el próximo login con Google permita elegir otra cuenta.
    await _socialAuth.signOut();
  }

  // ---------------------------------------------------------------------------
  // PASSKEYS (WebAuthn / FIDO2)
  // ---------------------------------------------------------------------------
  // Contrato (ver docs/passkeys.md):
  //   POST /auth/passkey/register/options  (con token)  -> {challenge_id, options}
  //   POST /auth/passkey/register/verify   (con token)  -> 200
  //   POST /auth/passkey/login/options     (público)    -> {challenge_id, options}
  //   POST /auth/passkey/login/verify      (público)    -> igual que /auth/login
  //
  // El backend genera challenges aleatorios de un solo uso con expiración,
  // guarda la clave pública + contador al registrar, y al iniciar sesión
  // verifica firma, origen, rpIdHash, flag UV y contador (anti-replay).

  /// `true` si `PASSKEY_RP_ID` está configurado y el dispositivo soporta
  /// passkeys. Si es `false`, la UI simplemente no muestra la opción.
  Future<bool> isPasskeyAvailable() => _passkeys.isAvailable();

  /// `true` si conviene lanzar Face ID / huella al abrir el login: el
  /// dispositivo ya registró o usó una passkey de esta app.
  Future<bool> shouldAutoPromptPasskey() async {
    if (!await isPasskeyAvailable()) return false;
    return await _storage.readPasskeyUser() != null;
  }

  /// `true` si se debe ofrecer activar la passkey tras un login exitoso.
  /// Con [ignoreDismissed] se ofrece aunque antes se haya rechazado
  /// (por ejemplo, justo después de crear la cuenta).
  Future<bool> shouldOfferPasskeyEnrollment({
    bool ignoreDismissed = false,
  }) async {
    if (!await isPasskeyAvailable()) return false;
    if (await _storage.readPasskeyUser() != null) return false;
    return ignoreDismissed || !await _storage.readPasskeyOfferDismissed();
  }

  /// Recuerda que el usuario no quiere activar la passkey por ahora.
  Future<void> dismissPasskeyOffer() => _storage.savePasskeyOfferDismissed();

  /// Inicia sesión con una passkey descubrible (no pide correo, así el
  /// backend no revela qué cuentas existen).
  ///
  /// Con [autoPrompt] solo se usan passkeys guardadas en este dispositivo y
  /// no se muestra nada si no hay ninguna.
  ///
  /// Lanza [PasskeyException] (cancelación, sin passkeys…) o [ApiException].
  Future<UserModel> loginWithPasskey({bool autoPrompt = false}) async {
    final challenge = await _requestPasskeyOptions(
      '/auth/passkey/login/options',
      const {},
    );

    final Map<String, dynamic> assertion;
    try {
      assertion = await _passkeys.getAssertion(
        challenge.options,
        preferImmediatelyAvailable: autoPrompt,
      );
    } on PasskeyException catch (e) {
      if (e.failure == PasskeyFailure.noCredentials) {
        // La passkey se borró del dispositivo: deja de ofrecerla sola.
        await _storage.clearPasskeyUser();
      }
      rethrow;
    }

    try {
      final user = await _authenticate('/auth/passkey/login/verify', {
        'challenge_id': ?challenge.id,
        'credential': assertion,
      });
      await _storage.savePasskeyUser(user.correo);
      PasskeyService.log('login', 'sesión iniciada con passkey');
      return user;
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.statusCode == 404) {
        // Credencial revocada o desconocida en el servidor.
        await _storage.clearPasskeyUser();
      }
      rethrow;
    }
  }

  /// Crea una passkey en este dispositivo y la vincula a la cuenta con
  /// sesión activa. El backend guarda el ID de credencial y la clave
  /// pública; la clave privada nunca sale del Secure Enclave / Keystore.
  ///
  /// Lanza [PasskeyException] o [ApiException].
  Future<void> registerPasskey() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Inicia sesión para activar la passkey.',
        statusCode: 401,
      );
    }

    final deviceName = _deviceName();
    final challenge = await _requestPasskeyOptions(
      '/auth/passkey/register/options',
      {'device_name': deviceName},
    );
    final user = challenge.options['user'];
    final correo = user is Map ? '${user['name'] ?? ''}' : '';

    final Map<String, dynamic> credential;
    try {
      credential = await _passkeys.createCredential(challenge.options);
    } on PasskeyException catch (e) {
      if (e.failure == PasskeyFailure.alreadyRegistered) {
        // `excludeCredentials` coincidió: ya está vinculada. No es error.
        await _storage.savePasskeyUser(correo);
        return;
      }
      rethrow;
    }

    try {
      await _dio.post<dynamic>(
        '/auth/passkey/register/verify',
        data: {
          'challenge_id': ?challenge.id,
          'credential': credential,
          'device_name': deviceName,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
    await _storage.savePasskeyUser(correo);
    PasskeyService.log('register', 'passkey vinculada');
  }

  /// Pide al backend un challenge nuevo. Acepta `{challenge_id, options}`,
  /// `{publicKey: {...}}` o las opciones directamente (py_webauthn).
  Future<({String? id, Map<String, dynamic> options})> _requestPasskeyOptions(
    String path,
    Map<String, dynamic> body,
  ) async {
    final dynamic data;
    try {
      data = (await _dio.post<dynamic>(path, data: body)).data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
    if (data is! Map) {
      throw const ApiException('Respuesta de passkey inesperada.');
    }

    Object? options = data['options'] ?? data['publicKey'] ?? data;
    if (options is Map && options['publicKey'] is Map) {
      options = options['publicKey'];
    }
    if (options is! Map) {
      throw const ApiException('Respuesta de passkey inesperada.');
    }

    final id = data['challenge_id'] ?? data['challengeId'];
    return (
      id: id is String && id.isNotEmpty ? id : null,
      options: options.cast<String, dynamic>(),
    );
  }

  static String _deviceName() => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'iOS',
    TargetPlatform.android => 'Android',
    final other => other.name,
  };

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  static const _tokenKeys = [
    'access_token',
    'accessToken',
    'token',
    'jwt',
    'id_token',
  ];

  /// Extrae el token JWT de la respuesta del servidor.
  String _extractToken(dynamic data) {
    // Caso 1: El backend devuelve un String plano.
    if (data is String && data.isNotEmpty) {
      return data.replaceAll('"', '');
    }

    // Caso 2: El backend devuelve un objeto JSON.
    if (data is Map) {
      String? find(Map map) {
        for (final key in _tokenKeys) {
          final value = map[key];
          if (value is String && value.isNotEmpty) return value;
        }
        return null;
      }

      final direct = find(data);
      if (direct != null) return direct;

      final inner = data['data'];
      if (inner is Map) {
        final nested = find(inner);
        if (nested != null) return nested;
      }
    }

    throw const ApiException(
      'Token no encontrado en la respuesta del servidor.',
    );
  }
}

/// Provider de Riverpod para inyección de dependencias.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(sessionStorageProvider),
    passkeys: ref.watch(passkeyServiceProvider),
  );
});
