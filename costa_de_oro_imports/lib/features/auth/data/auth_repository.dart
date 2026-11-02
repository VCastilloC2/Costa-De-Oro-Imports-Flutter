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
      token = _extractToken(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }

    await _storage.saveToken(token);

    try {
      return await fetchProfile();
    } catch (_) {
      await _storage.clear();
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // REGISTRO SIMPLIFICADO (Auto-rellena campos que exige FastAPI)
  // ---------------------------------------------------------------------------
  Future<UserModel> register({
    required String correo,
    required String password,
  }) async {
    // Generamos un ID aleatorio para que el backend no de error de "ID duplicado"
    final randomId = DateTime.now().millisecondsSinceEpoch.toString();
    // Usamos la primera parte del correo como nombre provisional
    final nombreProvisional = correo.split('@').first;

    try {
      await _dio.post<dynamic>(
        '/auth/registro',
        data: {
          'correo': correo.trim(),
          'password': password,
          
          // --- DATOS AUTO-RELLENADOS PARA SATISFACER AL BACKEND ---
          'tipoIdentificacion': 'CC',
          'numeroIdentificacion': randomId, 
          'nombres': nombreProvisional,
          'apellidos': 'Pendiente',
          'telefono': '0000000000',
          'direccion': 'Por definir',
          'rol': 'PERSONA_NATURAL',
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }

    // Login automático tras registro exitoso
    return login(correo: correo, password: password);
  }

  // ---------------------------------------------------------------------------
  // PERFIL Y SESIÓN
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
    } catch (_) {}
    await _storage.clear();
  }

  static const _tokenKeys = ['access_token', 'accessToken', 'token', 'jwt', 'id_token'];

  String _extractToken(dynamic data) {
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

      throw ApiException('Token no encontrado. Claves: ${data.keys.join(', ')}');
    }
    throw const ApiException('Respuesta de inicio de sesión inesperada.');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(sessionStorageProvider),
  );
});