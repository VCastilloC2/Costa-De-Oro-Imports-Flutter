// RAMA: chore/Core
// ============================================================================
// CONFIGURACIÓN DE LA API
// ============================================================================

class ApiConfig {
  ApiConfig._();

  // NOTA: IP actualizada a la red local (casa) para conectar por Wi-Fi.
  static const String baseUrl = 'http://192.168.1.54:8000';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}