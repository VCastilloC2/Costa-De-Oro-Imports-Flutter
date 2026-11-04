// RAMA: chore/Core
// ============================================================================
// CONFIGURACIÓN DE LA API
// ============================================================================
// Centraliza la URL base y los tiempos de espera para las peticiones HTTP.
// Modificar este archivo afecta a toda la aplicación.
// ============================================================================

class ApiConfig {
  ApiConfig._();

  // NOTA: Si se usa el Emulador de Android, 10.0.2.2 apunta a localhost de la PC.
  // Si se usa un dispositivo físico, se debe usar la IP de la red local (ej. 192.168.1.X).
  // Para producción, restaurar la URL de Vercel.
  static const String baseUrl = 'http://10.0.2.2:8000';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}