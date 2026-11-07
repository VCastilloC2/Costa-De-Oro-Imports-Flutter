import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/auth_response.dart';
import 'social_auth_service.dart';

class AuthRepository {
  AuthRepository(this.api, {SocialAuthService? socialAuth})
    : _socialAuth = socialAuth ?? SocialAuthService();

  final ApiClient api;
  final SocialAuthService _socialAuth;

  Future<AuthResponse> login(String email, String password) async {
    return _saveSession(
      await api.post(
        '/auth/login',
        data: {'correo': email.trim(), 'password': password},
      ),
    );
  }

  /// Envía el ID token de Google al backend, que lo valida y crea o inicia
  /// la sesión del usuario. Contrato: `POST /auth/google {"id_token": ...}`.
  Future<AuthResponse> loginWithGoogle(String idToken) async =>
      _saveSession(await api.post('/auth/google', data: {'id_token': idToken}));

  /// Envía el identity token de Apple al backend.
  /// Contrato: `POST /auth/apple {"id_token": ..., "nombres"?, "apellidos"?}`.
  /// Apple solo comparte el nombre en la primera autorización, por eso se
  /// reenvía cuando viene para que el backend pueda registrar al usuario.
  Future<AuthResponse> loginWithApple(
    String identityToken, {
    String? givenName,
    String? familyName,
  }) async => _saveSession(
    await api.post(
      '/auth/apple',
      data: {
        'id_token': identityToken,
        if (givenName != null && givenName.isNotEmpty) 'nombres': givenName,
        if (familyName != null && familyName.isNotEmpty)
          'apellidos': familyName,
      },
    ),
  );

  Future<AuthResponse> _saveSession(dynamic response) async {
    final result = AuthResponse.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
    final session = api.session;
    await session.saveToken(result.accessToken);
    final refreshToken = result.refreshToken;
    if (refreshToken != null) {
      await session.saveRefreshToken(refreshToken);
    }
    final user = result.user;
    if (user != null) {
      await session.saveUser(user);
    }
    return result;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async =>
      Map<String, dynamic>.from(
        await api.post('/auth/registro', data: payload) as Map,
      );

  Future<Map<String, dynamic>> profile() async =>
      Map<String, dynamic>.from(await api.get('/perfil') as Map);

  /// Cierra la sesión en la API y siempre borra la sesión local, aunque la
  /// API no responda, para que el usuario nunca quede atrapado.
  Future<void> logout() async {
    try {
      await api.post('/auth/logout');
    } on DioException {
      // La sesión local se borra igual.
    } finally {
      await api.session.clearSession();
      await _socialAuth.signOut();
    }
  }
}
