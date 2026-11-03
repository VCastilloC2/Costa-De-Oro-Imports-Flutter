import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:costa_de_oro_imports/core/network/api_client.dart';
import 'package:costa_de_oro_imports/core/network/api_exception.dart';
import 'package:costa_de_oro_imports/core/storage/session_storage.dart';
import 'package:costa_de_oro_imports/features/auth/data/models/user_model.dart';

/// ============================================================================
/// REPOSITORIO: AuthRepository
/// ============================================================================
/// Es la única capa que conoce las URLs del backend, el manejo de tokens
/// y el formato de las peticiones HTTP. Las pantallas nunca deben usar Dio
/// directamente, solo llamar a estos métodos.
class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SessionStorage _storage;

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------
  Future<UserModel> login({
    required String correo,
    required String password,
  }) async {
    final String token;
    try {
      final res = await _dio.post<dynamic>(
        '/auth/login',
        data: {
          'correo': correo.trim(),
          'password': password,
        },
      );
      token = _extractToken(res.data);
    } on DioException catch (e) {
      // Imprime el error exacto en la consola para depuración
      print('Error crudo del backend en login: ${e.response?.data}');
      throw ApiException.fromDio(e);
    }

    await _storage.saveToken(token);

    try {
      return await fetchProfile();
    } catch (e) {
      // MANEJO DE ERRORES:
      // Si el backend entrega el token pero falla la petición de /perfil,
      // se retorna un usuario genérico para permitir el acceso al Dashboard
      // sin expulsar al usuario de vuelta al Login.
      print("Error cargando perfil, usando fallback: $e");
      return UserModel(
        id: 0,
        correo: correo,
        nombres: correo.split('@').first,
        apellidos: 'Admin',
        telefono: '123',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // REGISTRO
  // ---------------------------------------------------------------------------
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
          'rol': 'ADMIN', // NOTA: Rol ADMIN para pruebas del Dashboard
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }

    // Espera de 1 segundo para que la base de datos asiente el registro
    await Future.delayed(const Duration(seconds: 1));
    
    // Auto-login tras registro exitoso
    return login(correo: correo, password: password);
  }

  // ---------------------------------------------------------------------------
  // ACTUALIZAR PERFIL
  // ---------------------------------------------------------------------------
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
    } catch (_) {}
    await _storage.clear();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  static const _tokenKeys = ['access_token', 'accessToken', 'token', 'jwt', 'id_token'];

  /// Extrae el token de la respuesta del backend.
  /// Según la documentación de Swagger, el endpoint de login devuelve
  /// un String plano, no un objeto JSON.
  String _extractToken(dynamic data) {
    // CASO 1: El backend devuelve el token como un texto plano.
    if (data is String && data.isNotEmpty) {
      // Limpia las comillas en caso de que el backend las incluya en el String.
      return data.replaceAll('"', '');
    }

    // CASO 2: Si el backend cambia en el futuro y devuelve un JSON.
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

/// Provider de Riverpod para inyectar el repositorio en los controladores.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(sessionStorageProvider),
  );
});