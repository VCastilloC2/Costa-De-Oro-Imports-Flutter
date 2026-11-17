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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:costa_de_oro_imports/core/network/api_client.dart';
import 'package:costa_de_oro_imports/core/network/api_exception.dart';
import 'package:costa_de_oro_imports/core/storage/session_storage.dart';
import 'package:costa_de_oro_imports/features/auth/data/models/user_model.dart';

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SessionStorage _storage;

  // ==========================================================================
  // LOGIN Y REGISTRO
  // ==========================================================================
  Future<UserModel> login({required String correo, required String password}) async {
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
        } else if (userJson['imagen'] != null && !userJson['imagen'].toString().startsWith('http')) {
          userJson['imagen'] = 'https://res.cloudinary.com/dp2nofw2b/image/upload/${userJson['imagen']}';
        }
        return UserModel.fromJson(userJson);
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
    await _storage.saveToken(token);
    return await fetchProfile();
  }

  Future<UserModel> register({required String correo, required String password}) async {
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
      
      print('=== [DEBUG] RESPUESTA DEL BACKEND (Status: ${response.statusCode}) ===');
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
        } else if (relativePath != null && relativePath.isNotEmpty && !relativePath.startsWith('http')) {
          userJson['imagen'] = 'https://res.cloudinary.com/dp2nofw2b/image/upload/$relativePath';
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
  static const _tokenKeys = ['access_token', 'accessToken', 'token', 'jwt', 'id_token'];

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
    throw const ApiException('Token no encontrado en la respuesta del servidor.');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(sessionStorageProvider));
});