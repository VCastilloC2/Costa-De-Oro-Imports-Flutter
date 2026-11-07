// RAMA: chore/Core
// ============================================================================
// CONFIGURACIÓN DE LA API
// ============================================================================
// Centraliza la URL base y los tiempos de espera para las peticiones HTTP.
// Modificar este archivo afecta a toda la aplicación.
// ============================================================================

class ApiConfig {
  ApiConfig._();

  // NOTA: Se usa 127.0.0.1 porque el túnel 'adb reverse' redirige 
  // el tráfico local del teléfono al puerto 8000 de la PC a través del cable USB.
  // Esto evita los bloqueos de red (Client Isolation) de la red Wi-Fi.
  static const String baseUrl = 'http://192.168.1.63:8000';
  /* static const String baseUrl = 'http://127.0.0.1:8000'; */

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}