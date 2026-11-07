import '../../../core/network/api_client.dart';

class AuthRepository {
  AuthRepository(this.api);
  final ApiClient api;

  Future<Map<String, dynamic>> login(String email, String password) async {
    return _saveSession(await api.post(
      '/auth/login',
      data: {'correo': email.trim(), 'password': password},
    ));
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async =>
      _saveSession(await api.post('/auth/google', data: {'id_token': idToken}));

  Future<Map<String, dynamic>> loginWithApple(String idToken) async =>
      _saveSession(await api.post('/auth/apple', data: {'id_token': idToken}));

  Future<Map<String, dynamic>> _saveSession(dynamic response) async {
    final result = Map<String, dynamic>.from(response as Map);
    final token = result['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('La API no devolvió un token de acceso.');
    }
    await api.saveToken(token);
    return result;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async =>
      Map<String, dynamic>.from(await api.post('/auth/registro', data: payload) as Map);

  Future<Map<String, dynamic>> profile() async =>
      Map<String, dynamic>.from(await api.get('/perfil') as Map);

  Future<void> logout() async {
    try {
      await api.post('/auth/logout');
    } finally {
      await api.clearToken();
    }
  }
}