// RAMA: chore/Core
// ============================================================================
// CONFIGURACIÓN DE LA API
// ============================================================================

class ApiConfig {
  ApiConfig._();

  // Sobrescribe estos valores por entorno. El certificado HTTPS debe ser confiable
  // en el dispositivo y cubrir el hostname/IP usado aquí.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://192.168.1.9:8000',
  );
  static const String passkeyRpId = String.fromEnvironment(
    'PASSKEY_RP_ID',
    defaultValue: '192.168.1.9',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
