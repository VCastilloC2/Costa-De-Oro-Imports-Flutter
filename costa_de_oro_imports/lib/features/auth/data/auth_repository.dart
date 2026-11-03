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
  /// Inicia sesión con correo y contraseña.
  /// Si es exitoso, guarda el token en [SessionStorage] y retorna el perfil.
  /// Lanza [ApiException] si las credenciales son inválidas.
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
      // Si el token es válido pero falla la carga del perfil, limpiamos
      // el token para no dejar la sesión en un estado corrupto.
      await _storage.clear();
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // REGISTRO
  // ---------------------------------------------------------------------------
  /// Registra un nuevo usuario.
  /// 
  /// **Nota de Arquitectura (Perfilamiento Progresivo):** 
  /// La UI de registro solo pide correo y contraseña para no abrumar al usuario.
  /// El backend (FastAPI) exige más campos. Por eso, inyectamos datos "dummy"
  /// (identificación aleatoria, apellido "Pendiente", etc.) para que la petición
  /// pase. El usuario completará estos datos después desde su perfil.
  Future<UserModel> register({
    required String correo,
    required String password,
  }) async {
    // ID basado en timestamp para evitar que el backend rechace por duplicado.
    final randomId = DateTime.now().millisecondsSinceEpoch.toString();
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
          'telefono': '0000000000',
          'direccion': 'Por definir',
          'rol': 'PERSONA_NATURAL',
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }

    // Auto-login tras registro exitoso
    return login(correo: correo, password: password);
  }

  // ---------------------------------------------------------------------------
  // ACTUALIZAR PERFIL
  // ---------------------------------------------------------------------------
  /// Actualiza los datos reales del usuario (PATCH /perfil).
  /// Este método se llama desde la pantalla `EditProfilePage`.
  /// 
  /// Si el backend usa PUT en lugar de PATCH, cambia `_dio.patch` por `_dio.put`.
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
      // Tras la actualización, pedimos el perfil de nuevo para obtener
      // los datos frescos y actualizar el estado global de Riverpod.
      return await fetchProfile();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // SESIÓN
  // ---------------------------------------------------------------------------
  /// Obtiene el perfil del usuario autenticado (GET /perfil).
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

  /// Intenta restaurar la sesión si hay un token guardado al abrir la app.
  /// Retorna `null` si no hay token o si el token ya expiró (401).
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

  /// Cierra la sesión en el backend y borra el token local.
  /// Usa "best-effort": si el backend falla, igual limpia el token local.
  Future<void> logout() async {
    try {
      await _dio.post<dynamic>('/auth/logout');
    } catch (_) {}
    await _storage.clear();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  /// Claves comunes donde el backend podría enviar el token.
  /// Una vez confirmes la clave real en Swagger, deja solo esa.
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

/// Provider de Riverpod para inyectar el repositorio en los controllers.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(sessionStorageProvider),
  );
});