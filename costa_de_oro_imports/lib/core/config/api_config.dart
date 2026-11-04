// RAMA: chore/Core
// ============================================================================
// CONFIGURACIÓN DE LA API
// ============================================================================
// Centraliza la URL base y los tiempos de espera para las peticiones HTTP.
// Modificar este archivo afecta a toda la aplicación.
// ============================================================================

class ApiConfig {
  ApiConfig._();

  // NOTA: Se usa la IP de red local de la PC (192.168.1.63) para conectar 
  // un dispositivo físico al backend local en el puerto 8000.
  static const String baseUrl = 'http://192.168.1.63:8000';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}