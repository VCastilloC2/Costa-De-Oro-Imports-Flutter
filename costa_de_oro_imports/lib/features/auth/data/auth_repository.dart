// RAMA: feature/Auth
// ============================================================================
// REPOSITORIO: AuthRepository
// ============================================================================
// Capa de datos encargada de comunicarse con los endpoints de autenticación.
// Maneja el almacenamiento del token JWT y la conversión de excepciones HTTP.
// ============================================================================

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

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------
  /// Envía las credenciales al backend. Si la respuesta es exitosa, extrae el
  /// token y los datos del usuario, guardando el token localmente.
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
      
      final data = res.data;
      token = _extractToken(data);

      // El backend devuelve el objeto 'usuario' dentro del login.
      // Se extrae directamente para evitar peticiones adicionales a /perfil.
      if (data is Map && data['usuario'] is Map<String, dynamic>) {
        await _storage.saveToken(token);
        return UserModel.fromJson(data['usuario']);
      }
      
    } on DioException catch (e) {
      print('Error crudo del backend en login: ${e.response?.data}');
      throw ApiException.fromDio(e);
    }

    // Respaldo: Si el backend no anida el usuario, se solicita a /perfil.
    await _storage.saveToken(token);
    return await fetchProfile();
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
          'rol': 'ADMIN', 
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
    } catch (_) {}
    await _storage.clear();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  static const _tokenKeys = ['access_token', 'accessToken', 'token', 'jwt', 'id_token'];

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
    
    throw const ApiException('Token no encontrado en la respuesta del servidor.');
  }
}

/// Provider de Riverpod para inyección de dependencias.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(sessionStorageProvider),
  );
});