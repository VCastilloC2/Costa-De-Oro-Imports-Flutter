// RAMA: feature/Auth
// ============================================================================
// REPOSITORIO: AuthRepository
// ============================================================================
// Capa de datos encargada de comunicarse con los endpoints de autenticación.
//
// ACTUALIZACIÓN IMPORTANTE:
// El método `updateProfile` ha sido refactorizado para enviar los datos
// utilizando `multipart/form-data`, tal como lo exige el backend (verificado
// en Swagger). Además, ahora incluye el campo `correo` y permite adjuntar
// la imagen de perfil en la misma petición, eliminando la necesidad de un
// endpoint separado para la subida de la foto.
// ============================================================================

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SessionStorage _storage;
  final PasskeyAuthenticator _passkeyAuthenticator = PasskeyAuthenticator(
    debugMode: kDebugMode,
  );

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
  // LOGIN Y REGISTRO
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
        if (data['urlImagenUsuario'] != null) {
          userJson['imagen'] = data['urlImagenUsuario'];
        } else if (userJson['imagen'] != null &&
            !userJson['imagen'].toString().startsWith('http')) {
          userJson['imagen'] =
              'https://res.cloudinary.com/dp2nofw2b/image/upload/${userJson['imagen']}';
        }
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
  // ACTUALIZACIÓN DE PERFIL (MULTIPART)
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
      // 1. Construimos el mapa con los datos requeridos por el backend
      final Map<String, dynamic> map = {
        'nombres': nombres.trim(),
        'apellidos': apellidos.trim(),
        'correo': correo.trim(),
        'telefono': telefono.trim(),
        'direccion': direccion.trim(),
        'tipo_identificacion': tipoIdentificacion,
        'numero_identificacion': numeroIdentificacion.trim(),
      };

      // 2. Si el usuario seleccionó una nueva imagen, la adjuntamos
      if (imagen != null) {
        map['imagen'] = await MultipartFile.fromFile(
          imagen.path,
          filename: 'profile.jpg',
        );
      }

      // 3. Convertimos el mapa a FormData
      final formData = FormData.fromMap(map);

      print('=== [DEBUG] ENVIANDO AL BACKEND (PATCH /perfil) ===');
      print('Campos: ${map.keys.toList()}');

      // 4. Enviamos la petición con el content-type correcto
      final response = await _dio.patch<dynamic>(
        '/perfil',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      print(
        '=== [DEBUG] RESPUESTA DEL BACKEND (Status: ${response.statusCode}) ===',
      );
      print(response.data);

      // Refrescamos el perfil para obtener los datos actualizados
      return await fetchProfile();
    } on DioException catch (e) {
      print('=== [DEBUG] ERROR AL ACTUALIZAR PERFIL ===');
      print('Status: ${e.response?.statusCode}');
      print('Mensaje del servidor: ${e.response?.data}');
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

        // Lógica para garantizar que la URL de la imagen sea absoluta
        final String? fullUrl = data['urlImagenUsuario'];
        final String? relativePath = userJson['imagen'];

        if (fullUrl != null && fullUrl.isNotEmpty) {
          userJson['imagen'] = fullUrl;
        } else if (relativePath != null &&
            relativePath.isNotEmpty &&
            !relativePath.startsWith('http')) {
          userJson['imagen'] =
              'https://res.cloudinary.com/dp2nofw2b/image/upload/$relativePath';
        }

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
