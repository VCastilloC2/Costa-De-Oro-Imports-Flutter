/// Sesión devuelta por los endpoints de autenticación de la API.
///
/// La API actual responde con `accessToken` (camelCase). También se aceptan
/// `access_token` / `refresh_token` por si el backend usa snake_case en los
/// endpoints sociales.
class AuthResponse {
  const AuthResponse({required this.accessToken, this.refreshToken, this.user});

  final String accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'] ?? json['access_token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('La API no devolvió un token de acceso.');
    }
    final refresh = json['refreshToken'] ?? json['refresh_token'];
    final user = json['usuario'] ?? json['user'];
    return AuthResponse(
      accessToken: token,
      refreshToken: refresh is String && refresh.isNotEmpty ? refresh : null,
      user: user is Map ? Map<String, dynamic>.from(user) : null,
    );
  }
}
