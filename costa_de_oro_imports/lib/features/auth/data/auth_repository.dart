// RAMA: feature/Auth
// ============================================================================
// REPOSITORIO: AuthRepository (Versión Avanzada - Compañero)
// ============================================================================
// Capa de datos encargada de comunicarse con los endpoints de autenticación.
// Incluye Biometría Local (local_auth ^3.x) y Passkeys (WebAuthn).
// ============================================================================

import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/exceptions.dart';
import 'package:passkeys/types.dart';

import 'package:costa_de_oro_imports/core/network/api_client.dart';
import 'package:costa_de_oro_imports/core/network/api_exception.dart';
import 'package:costa_de_oro_imports/core/config/api_config.dart';
import 'package:costa_de_oro_imports/core/storage/session_storage.dart';
import 'package:costa_de_oro_imports/features/auth/data/models/user_model.dart';

class PasskeyCredential {
  const PasskeyCredential({
    required this.passkeyId,
    required this.deviceType,
    required this.backedUp,
    this.deviceName,
    this.createdAt,
    this.lastUsedAt,
  });

  final int passkeyId;
  final String? deviceName;
  final String? deviceType;
  final bool backedUp;
  final String? createdAt;
  final String? lastUsedAt;

  factory PasskeyCredential.fromJson(Map<String, dynamic> json) =>
      PasskeyCredential(
        passkeyId: (json['passkey_id'] as num).toInt(),
        deviceName: json['device_name'] as String?,
        deviceType: json['device_type'] as String?,
        backedUp: json['backed_up'] == true,
        createdAt: json['created_at'] as String?,
        lastUsedAt: json['last_used_at'] as String?,
      );
}

/// Dispositivo vinculado con biometría local (GET /auth/biometric/devices).
/// El servidor nunca devuelve el secreto.
class BiometricDevice {
  const BiometricDevice({
    required this.credentialId,
    required this.deviceId,
    this.deviceName,
    this.createdAt,
  });

  final int credentialId;
  final String deviceId;
  final String? deviceName;
  final String? createdAt;

  factory BiometricDevice.fromJson(Map<String, dynamic> json) {
    var created = json['created_at'] as String?;
    // El servidor manda la hora en UTC pero sin "Z": se agrega para que la
    // fecha se muestre en hora local.
    if (created != null && !created.endsWith('Z') && !created.contains('+')) {
      created = '${created}Z';
    }
    return BiometricDevice(
      credentialId: (json['credential_id'] as num).toInt(),
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String?,
      createdAt: created,
    );
  }
}

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SessionStorage _storage;

  final PasskeyAuthenticator _passkeyAuthenticator = PasskeyAuthenticator(
    debugMode: kDebugMode,
  );
  final LocalAuthentication _localAuth = LocalAuthentication();

  String _randomHex(int length) {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
  }

  // ==========================================================================
  // BIOMETRÍA LOCAL (local_auth ^3.x)
  // ==========================================================================
  // NOTA: en local_auth 3.x ya no existe AuthenticationOptions. Los parámetros
  // (biometricOnly, persistAcrossBackgrounding) van directo en authenticate().
  // "stickyAuth" (2.x) ahora se llama "persistAcrossBackgrounding".
  // ==========================================================================

  /// Vincula este dispositivo a la cuenta actual. El backend recibe el secreto
  /// aleatorio, nunca la huella; la biometría solo desbloquea localmente.
  Future<void> registerBiometric() async {
    try {
      if (!await _localAuth.canCheckBiometrics ||
          !await _localAuth.isDeviceSupported()) {
        throw const ApiException(
          'Este dispositivo no tiene biometría disponible.',
        );
      }

      final ok = await _localAuth.authenticate(
        localizedReason:
            'Confirma tu identidad para activar el ingreso con huella',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!ok) {
        throw const ApiException('Verificación biométrica cancelada.');
      }

      final deviceId = _randomHex(32);
      final secret = _randomHex(64);

      await _dio.post<dynamic>(
        '/auth/biometric/register',
        data: {
          'device_id': deviceId,
          'device_secret': secret,
          'device_name': _deviceName,
        },
      );
      await _storage.saveBiometricCredential(deviceId, secret);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel> loginWithBiometric({required String correo}) async {
    try {
      final deviceId = await _storage.readBiometricDeviceId();
      if (deviceId == null) {
        throw const ApiException('Activa primero la huella desde tu perfil.');
      }

      final ok = await _localAuth.authenticate(
        localizedReason: 'Verifica tu identidad para ingresar',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!ok) {
        throw const ApiException('Verificación biométrica cancelada.');
      }

      final secret = await _storage.readBiometricSecret();
      if (secret == null) {
        throw const ApiException('Activa primero la huella desde tu perfil.');
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/biometric/login',
        data: {
          'correo': correo.trim(),
          'device_id': deviceId,
          'device_secret': secret,
          'device_name': _deviceName,
        },
      );
      final data = response.data!;
      await _storage.saveToken(_extractToken(data));
      final userJson = Map<String, dynamic>.from(data['usuario'] as Map);
      _normalizeUserImage(userJson, data);
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Lista los dispositivos vinculados a la cuenta.
  Future<List<BiometricDevice>> listBiometricDevices() async {
    try {
      final response =
          await _dio.get<List<dynamic>>('/auth/biometric/devices');
      return (response.data ?? const <dynamic>[])
          .whereType<Map>()
          .map((j) => BiometricDevice.fromJson(Map<String, dynamic>.from(j)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Revoca un dispositivo: el servidor elimina su secreto.
  Future<void> revokeBiometricDevice(int credentialId) async {
    try {
      await _dio.delete<dynamic>('/auth/biometric/devices/$credentialId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ==========================================================================
  // PASSKEYS (WebAuthn)
  // ==========================================================================

  /// Completa options -> Credential Manager/biometría -> verify contra FastAPI.
  Future<void> registerPasskey({String? deviceName}) async {
    try {
      final optionsResponse = await _dio.post<Map<String, dynamic>>(
        '/auth/passkey/register/options',
        data: {'device_name': deviceName ?? _deviceName},
      );
      final options = Map<String, dynamic>.from(
        optionsResponse.data!['options'] as Map,
      );
      _validateRpId(
        options['rp'] is Map ? (options['rp'] as Map)['id'] as String? : null,
      );
      final challengeId = optionsResponse.data!['challenge_id'] as String;

      final credential = await _passkeyAuthenticator.register(
        RegisterRequestType.fromJson(options),
      );

      await _dio.post<dynamic>(
        '/auth/passkey/register/verify',
        data: {
          'challenge_id': challengeId,
          'device_name': deviceName ?? _deviceName,
          'credential': credential.toJson(),
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    } catch (e) {
      throw _passkeyError(e);
    }
  }

  /// Login descubrible: el sistema presenta las passkeys disponibles sin pedir correo.
  Future<UserModel> loginWithPasskey() async {
    try {
      final optionsResponse = await _dio.post<Map<String, dynamic>>(
        '/auth/passkey/login/options',
        data: <String, dynamic>{},
      );
      final options = Map<String, dynamic>.from(
        optionsResponse.data!['options'] as Map,
      );
      _validateRpId(options['rpId'] as String?);
      final challengeId = optionsResponse.data!['challenge_id'] as String;

      final assertion = await _passkeyAuthenticator.authenticate(
        AuthenticateRequestType.fromJson(
          options,
          preferImmediatelyAvailableCredentials: false,
          canBeSecurityKey: false,
        ),
      );

      final finishResponse = await _dio.post<Map<String, dynamic>>(
        '/auth/passkey/login/verify',
        data: {'challenge_id': challengeId, 'credential': assertion.toJson()},
      );
      final data = finishResponse.data!;
      final token = _extractToken(data);
      await _storage.saveToken(token);
      final userJson = Map<String, dynamic>.from(data['usuario'] as Map);
      _normalizeUserImage(userJson, data);
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    } catch (e) {
      throw _passkeyError(e);
    }
  }

  Future<List<PasskeyCredential>> listPasskeys() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/v1/auth/passkey/credentials',
      );
      return (response.data ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (json) =>
                PasskeyCredential.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> revokePasskey(int passkeyId) async {
    try {
      await _dio.delete<dynamic>('/api/v1/auth/passkey/credentials/$passkeyId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<bool> validateSession() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/auth/session/validate',
      );
      return response.data?['valid'] == true;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ==========================================================================
  // UTILIDADES INTERNAS
  // ==========================================================================

  String get _deviceName => Platform.isAndroid
      ? 'Android'
      : Platform.isIOS
      ? 'iOS'
      : Platform.operatingSystem;

  void _validateRpId(String? serverRpId) {
    if (serverRpId == null ||
        serverRpId.toLowerCase() != ApiConfig.passkeyRpId.toLowerCase()) {
      throw ApiException(
        'El RP ID del servidor (${serverRpId ?? 'vacío'}) no coincide con '
        'PASSKEY_RP_ID de Flutter (${ApiConfig.passkeyRpId}).',
      );
    }
  }

  ApiException _passkeyError(Object error) {
    if (error is ApiException) return error;
    if (error is PasskeyAuthCancelledException) {
      return const ApiException('Operación de Passkey cancelada.');
    }
    if (error is NoCredentialsAvailableException) {
      return const ApiException(
        'No hay una Passkey disponible en este dispositivo.',
      );
    }
    if (error is MissingGoogleSignInException ||
        error is SyncAccountNotAvailableException) {
      return const ApiException(
        'Inicia sesión en una cuenta de Google y configura el bloqueo de pantalla para usar Passkeys en Android.',
      );
    }
    if (error is DomainNotAssociatedException) {
      return ApiException(
        'El dominio del RP no está asociado a esta app. Revisa assetlinks.json. ${error.message ?? ''}',
      );
    }
    if (error is UnhandledAuthenticatorException &&
        error.code.contains('CREATE_PUBLIC_KEY_CREDENTIAL_DOM_EXCEPTION')) {
      return const ApiException(
        'Android no pudo crear la Passkey. El registro de este dispositivo '
        'también requiere que https://<RP_ID>/.well-known/assetlinks.json '
        'sea accesible y asocie el package name y certificado SHA-256 de la app. '
        'Revisa además que el certificado HTTPS del RP sea confiable.',
      );
    }
    if (error is ExcludeCredentialsCanNotBeRegisteredException) {
      return const ApiException(
        'Esta Passkey ya está registrada en el dispositivo.',
      );
    }
    final message = error.toString();
    if (message.toLowerCase().contains('cancel')) {
      return const ApiException('Operación de Passkey cancelada.');
    }
    return ApiException(
      'No se pudo completar la operación de Passkey: $message',
    );
  }

  void _normalizeUserImage(
    Map<String, dynamic> userJson,
    Map<String, dynamic> response,
  ) {
    if (response['urlImagenUsuario'] != null) {
      userJson['imagen'] = response['urlImagenUsuario'];
    } else if (userJson['imagen'] != null &&
        !userJson['imagen'].toString().startsWith('http')) {
      userJson['imagen'] =
          'https://res.cloudinary.com/dp2nofw2b/image/upload/${userJson['imagen']}';
    }
  }

  // ==========================================================================
  // LOGIN Y REGISTRO TRADICIONAL
  // ==========================================================================

  Future<UserModel> login({
    required String correo,
    required String password,
  }) async {
    final String token;
    try {
      final res = await _dio.post<dynamic>(
        '/auth/login',
        data: {'correo': correo.trim(), 'password': password},
      );
      final data = res.data;
      token = _extractToken(data);
      if (data is Map && data['usuario'] is Map<String, dynamic>) {
        await _storage.saveToken(token);
        final userJson = Map<String, dynamic>.from(data['usuario']);
        _normalizeUserImage(userJson, Map<String, dynamic>.from(data));
        return UserModel.fromJson(userJson);
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
    await _storage.saveToken(token);
    return await fetchProfile();
  }

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
          'rol': 'ADMIN',
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
    await Future.delayed(const Duration(seconds: 1));
    return login(correo: correo, password: password);
  }

  // ==========================================================================
  // ACTUALIZACIÓN DE PERFIL
  // ==========================================================================
  Future<UserModel> updateProfile({
    required String nombres,
    required String apellidos,
    required String correo,
    required String telefono,
    required String direccion,
    required String tipoIdentificacion,
    required String numeroIdentificacion,
    File? imagen,
  }) async {
    try {
      final Map<String, dynamic> map = {
        'nombres': nombres.trim(),
        'apellidos': apellidos.trim(),
        'correo': correo.trim(),
        'telefono': telefono.trim(),
        'direccion': direccion.trim(),
        'tipo_identificacion': tipoIdentificacion,
        'numero_identificacion': numeroIdentificacion.trim(),
      };

      if (imagen != null) {
        map['imagen'] = await MultipartFile.fromFile(
          imagen.path,
          filename: 'profile.jpg',
        );
      }

      final formData = FormData.fromMap(map);

      // Logs de depuración: solo en modo debug y sin volcar datos del usuario.
      if (kDebugMode) {
        debugPrint('[DEBUG] PATCH /perfil -> campos: ${map.keys.toList()}');
      }

      final response = await _dio.patch<dynamic>(
        '/perfil',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (kDebugMode) {
        debugPrint('[DEBUG] PATCH /perfil <- status: ${response.statusCode}');
      }

      return await fetchProfile();
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[DEBUG] Error al actualizar perfil -> status: '
          '${e.response?.statusCode}, mensaje: ${e.response?.data}',
        );
      }
      throw ApiException.fromDio(e);
    }
  }

  // ==========================================================================
  // OBTENER PERFIL
  // ==========================================================================
  Future<UserModel> fetchProfile() async {
    try {
      final res = await _dio.get<dynamic>('/api/graficas/dashboard');
      final data = res.data;

      if (data is! Map<String, dynamic>) {
        throw const ApiException('Respuesta de perfil inesperada.');
      }

      if (data['usuario'] is Map<String, dynamic>) {
        final userJson = Map<String, dynamic>.from(data['usuario']);
        _normalizeUserImage(userJson, data);
        return UserModel.fromJson(userJson);
      }

      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ==========================================================================
  // SESIÓN
  // ==========================================================================
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
    } catch (_) {}
    await _storage.clear();
  }

  // ==========================================================================
  // UTILIDADES
  // ==========================================================================
  static const _tokenKeys = [
    'access_token',
    'accessToken',
    'token',
    'jwt',
    'id_token',
  ];

  String _extractToken(dynamic data) {
    if (data is String && data.isNotEmpty) return data.replaceAll('"', '');
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

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(sessionStorageProvider),
  );
});