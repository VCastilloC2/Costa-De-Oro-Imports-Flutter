// RAMA: feature/Auth
// ============================================================================
// REPOSITORIO: AuthRepository
// ============================================================================
// Capa de datos encargada de comunicarse con los endpoints de autenticación.
// Maneja el almacenamiento del token JWT, la subida de imágenes y la 
// conversión de excepciones HTTP a excepciones del dominio de la app.
// ============================================================================

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:costa_de_oro_imports/core/network/api_client.dart';
import 'package:costa_de_oro_imports/core/network/api_exception.dart';
import 'package:costa_de_oro_imports/core/storage/session_storage.dart';
import 'package:costa_de_oro_imports/features/auth/data/models/user_model.dart';

class AuthRepository {
  /// Constructor que recibe inyección de dependencias.
  /// _dio se encarga de la red, _storage del guardado local del token.
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SessionStorage _storage;

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------
  /// ==========================================================================
  /// MÉTODO: login
  /// ==========================================================================
  /// Envía las credenciales al backend. Si la respuesta es exitosa, extrae el
  /// token y los datos del usuario, guardando el token localmente.
  Future<UserModel> login({
    required String correo,
    required String password,
  }) async {
    final String token;
    try {
      // 1. Hacemos la petición POST al endpoint de login.
      final res = await _dio.post<dynamic>(
        '/auth/login',
        data: {
          'correo': correo.trim(),
          'password': password,
        },
      );
      
      final data = res.data;
      // 2. Extraemos el token usando nuestro helper.
      token = _extractToken(data);

      // 3. El backend devuelve el objeto 'usuario' dentro del login.
      if (data is Map && data['usuario'] is Map<String, dynamic>) {
        await _storage.saveToken(token); // Guardamos el token.
        
        // También capturamos la URL completa de la imagen si viene en el login.
        final userJson = Map<String, dynamic>.from(data['usuario']);
        if (data['urlImagenUsuario'] != null) {
          userJson['imagen'] = data['urlImagenUsuario'];
        }
        return UserModel.fromJson(userJson);
      }
      
    } on DioException catch (e) {
      // Si hay error de red (400, 401, 500), lo convertimos a nuestra excepción.
      throw ApiException.fromDio(e);
    }

    // 4. Respaldo: Si el backend no anida el usuario en el login, 
    // guardamos el token y solicitamos los datos con una petición aparte.
    await _storage.saveToken(token);
    return await fetchProfile();
  }

  // ---------------------------------------------------------------------------
  // REGISTRO
  // ---------------------------------------------------------------------------
  /// ==========================================================================
  /// MÉTODO: register
  /// ==========================================================================
  /// Crea un nuevo usuario. El backend requiere múltiples campos, por lo que
  /// se inyectan datos genéricos que el usuario completará en feature/Profile.
  Future<UserModel> register({
    required String correo,
    required String password,
  }) async {
    // 1. Generamos datos temporales únicos para llenar los campos requeridos.
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    final randomId = now.substring(now.length - 10); 
    final nombreProvisional = correo.split('@').first;

    try {
      // 2. Enviamos la petición POST con los datos genéricos de registro rápido.
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

    // 3. Pausa para asegurar que la base de datos guarde el usuario.
    await Future.delayed(const Duration(seconds: 1));
    
    // 4. Hacemos login automático para devolver el usuario recién creado.
    return login(correo: correo, password: password);
  }

  // ---------------------------------------------------------------------------
  // ACTUALIZAR PERFIL
  // ---------------------------------------------------------------------------
  /// ==========================================================================
  /// MÉTODO: updateProfile
  /// ==========================================================================
  /// Utilizado por feature/Profile para actualizar los datos del usuario, 
  /// incluyendo el tipo y número de identificación.
  Future<UserModel> updateProfile({
    required String nombres,
    required String apellidos,
    required String telefono,
    required String direccion,
    required String tipoIdentificacion,
    required String numeroIdentificacion,
  }) async {
    try {
      // 1. Hacemos la petición PATCH. El backend solo actualiza lo que enviamos.
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
      
      // 2. Una vez actualizado, consultamos el perfil fresco.
      return await fetchProfile();
    } on DioException catch (e) {
      print('ERROR DEL BACKEND AL ACTUALIZAR: ${e.response?.data}');
      throw ApiException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // SUBIR FOTO DE PERFIL
  // ---------------------------------------------------------------------------
  /// ==========================================================================
  /// MÉTODO: uploadProfileImage
  /// ==========================================================================
  /// Recibe un archivo de imagen del dispositivo, lo empaqueta como
  /// multipart/form-data y lo envía al backend. Al terminar, retorna el
  /// usuario actualizado para refrescar el estado global.
  Future<UserModel> uploadProfileImage(File imageFile) async {
    try {
      // 1. Preparamos el archivo para enviarlo.
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path, 
          filename: 'profile.jpg', // Nombre genérico para el archivo.
        ),
      });

      // 2. Hacemos la petición PATCH (o POST, según la ruta que defina el backend).
      // Ajusta '/perfil/imagen' si tu compañero usó otra ruta en FastAPI.
      final response = await _dio.patch<dynamic>(
        '/perfil/imagen',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      print('RESPUESTA DEL BACKEND AL SUBIR IMAGEN: ${response.data}');

      // 3. Retornamos el perfil actualizado haciendo un nuevo fetch
      // para asegurar que obtenemos la URL definitiva de la imagen.
      return await fetchProfile();
      
    } on DioException catch (e) {
      print('ERROR DEL BACKEND AL SUBIR IMAGEN: ${e.response?.data}');
      throw ApiException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // SESIÓN Y PERFIL
  // ---------------------------------------------------------------------------
  /// ==========================================================================
  /// MÉTODO: fetchProfile
  /// ==========================================================================
  /// Consulta los datos del usuario.
  /// Usa el endpoint '/api/graficas/dashboard' porque el endpoint '/perfil' 
  /// está incompleto en el backend y no envía el documento. Además, captura
  /// la URL completa de la imagen (urlImagenUsuario) para mostrarla en la UI.
  Future<UserModel> fetchProfile() async {
    try {
      // 1. Consultamos el endpoint del dashboard que sí tiene los datos completos.
      final res = await _dio.get<dynamic>('/api/graficas/dashboard');
      final data = res.data;
      
      print('JSON REAL DE fetchProfile: $data'); 
      
      // 2. Validamos que el JSON devuelto sea un Mapa.
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Respuesta de perfil inesperada.');
      }

      // 3. El backend anida los datos del usuario dentro de la llave "usuario".
      if (data['usuario'] is Map<String, dynamic>) {
        final userJson = Map<String, dynamic>.from(data['usuario']);
        
        // 4. Si el backend envía la URL completa de la imagen, la usamos 
        // en lugar de la ruta relativa.
        if (data['urlImagenUsuario'] != null) {
          userJson['imagen'] = data['urlImagenUsuario'];
        }

        return UserModel.fromJson(userJson);
      }

      // 5. Fallback: Si los datos vienen en la raíz, los leemos directamente.
      return UserModel.fromJson(data);
      
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// ==========================================================================
  /// MÉTODO: restoreSession
  /// ==========================================================================
  /// Intenta recuperar la sesión del usuario al abrir la app.
  /// Si el token existe pero es inválido (401), lo borra.
  Future<UserModel?> restoreSession() async {
    // 1. Verificamos si hay un token guardado localmente.
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      // 2. Si hay token, intentamos pedir el perfil.
      return await fetchProfile();
    } on ApiException catch (e) {
      // 3. Si el token expiró, limpiamos el almacenamiento y retornamos null.
      if (e.isUnauthorized) {
        await _storage.clear();
        return null;
      }
      rethrow; // Si es otro error, lo relanzamos.
    }
  }

  /// ==========================================================================
  /// MÉTODO: logout
  /// ==========================================================================
  /// Cierra la sesión en el backend y elimina el token local.
  Future<void> logout() async {
    try {
      await _dio.post<dynamic>('/auth/logout');
    } catch (_) {
      // Ignoramos si el logout en el servidor falla (ej. sin internet).
      // Lo importante es limpiar el token local.
    }
    await _storage.clear();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  /// Posibles nombres de la clave del token en el JSON de respuesta.
  static const _tokenKeys = ['access_token', 'accessToken', 'token', 'jwt', 'id_token'];

  /// ==========================================================================
  /// MÉTODO: _extractToken
  /// ==========================================================================
  /// Extrae el token JWT de la respuesta del servidor, adaptándose a diferentes
  /// formatos que pueda devolver el backend.
  String _extractToken(dynamic data) {
    // Caso 1: El backend devuelve un String plano (token directo).
    if (data is String && data.isNotEmpty) {
      return data.replaceAll('"', '');
    }

    // Caso 2: El backend devuelve un objeto JSON.
    if (data is Map) {
      // Función interna para buscar el token dentro de un mapa.
      String? find(Map map) {
        for (final key in _tokenKeys) {
          final value = map[key];
          if (value is String && value.isNotEmpty) return value;
        }
        return null;
      }

      // Buscamos el token en el nivel superior del JSON.
      final direct = find(data);
      if (direct != null) return direct;

      // Buscamos el token en un nivel anidado (ej. data['data']['token']).
      final inner = data['data'];
      if (inner is Map) {
        final nested = find(inner);
        if (nested != null) return nested;
      }
    }
    
    // Si llegamos aquí, no se encontró el token.
    throw const ApiException('Token no encontrado en la respuesta del servidor.');
  }
}

/// ============================================================================
/// PROVIDER: authRepositoryProvider
/// ============================================================================
/// Provider de Riverpod para inyección de dependencias. 
/// Permite que el AuthController acceda al repositorio sin instanciarlo manualmente.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider), // Provee la configuración HTTP (Dio).
    ref.watch(sessionStorageProvider), // Provee el guardado seguro (Storage).
  );
});