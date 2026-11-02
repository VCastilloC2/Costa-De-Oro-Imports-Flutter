/// Configuración de la API.
/// Si el servidor cambia de dirección, se cambia SOLO aquí.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl =
      'https://costa-de-oro-imports-python-vatg.vercel.app';

  /// El servidor está en Vercel: la primera petición puede tardar unos
  /// segundos en "despertar", por eso los tiempos son generosos.
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}