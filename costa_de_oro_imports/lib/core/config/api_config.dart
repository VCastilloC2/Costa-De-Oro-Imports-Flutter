// RAMA: chore/Core
// ============================================================================
// CONFIGURACIÓN DE LA API
// ============================================================================

class ApiConfig {
  ApiConfig._();

  // Dirección del backend en la red local. Cambia la IP si el computador
  // recibe otra dirección en el router o sobrescribe API_BASE_URL al ejecutar.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://costa-de-oro-imports-python.onrender.com',
  );
  static const String passkeyRpId = String.fromEnvironment(
    'PASSKEY_RP_ID',
    defaultValue: 'costa-de-oro-imports-python.onrender.com',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
