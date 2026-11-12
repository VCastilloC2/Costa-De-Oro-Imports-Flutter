// RAMA: feature/Auth
// ============================================================================
// REPOSITORIO: AuthRepository
// ============================================================================
// Capa de datos encargada de comunicarse con los endpoints de autenticación.
// Se ha actualizado fetchProfile para garantizar que la URL de la imagen de
// perfil siempre sea absoluta (comenzando con http), construyendo la ruta de
// Cloudinary si el backend solo envía la ruta relativa.
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

  // ... (Métodos login y register se mantienen igual) ...

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

  Future<UserModel> updateProfile({
    required String nombres,
    required String apellidos,
    required String telefono,
    required String direccion,
    required String tipoIdentificacion,
    required String numeroIdentificacion,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
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
      print('RESPUESTA DEL BACKEND AL ACTUALIZAR: ${response.data}');
      return await fetchProfile();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel> uploadProfileImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path, filename: 'profile.jpg'),
      });
      final response = await _dio.patch<dynamic>(
        '/perfil/imagen',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      print('RESPUESTA DEL BACKEND AL SUBIR IMAGEN: ${response.data}');
      return await fetchProfile();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// ==========================================================================
  /// MÉTODO: fetchProfile
  /// ==========================================================================
  Future<UserModel> fetchProfile() async {
    try {
      final res = await _dio.get<dynamic>('/api/graficas/dashboard');
      final data = res.data;
      
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Respuesta de perfil inesperada.');
      }

      if (data['usuario'] is Map<String, dynamic>) {
        final userJson = Map<String, dynamic>.from(data['usuario']);
        
        // LOGICA MEJORADA DE LA IMAGEN
        final String? fullUrl = data['urlImagenUsuario'];
        final String? relativePath = userJson['imagen'];

        if (fullUrl != null && fullUrl.isNotEmpty) {
          userJson['imagen'] = fullUrl;
        } else if (relativePath != null && relativePath.isNotEmpty && !relativePath.startsWith('http')) {
          // Si el backend no envía la URL completa, la construimos.
          userJson['imagen'] = 'https://res.cloudinary.com/dp2nofw2b/image/upload/$relativePath';
        }

        return UserModel.fromJson(userJson);
      }

      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ... (restoreSession, logout, _extractToken se mantienen igual) ...
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