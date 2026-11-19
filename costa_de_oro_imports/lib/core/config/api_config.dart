// RAMA: chore/Core
// ============================================================================
// CONFIGURACIÓN DE LA API
// ============================================================================

class ApiConfig {
  ApiConfig._();

  // Un endpoint fijo evita que Debug/Release o un --dart-define apunten
  // accidentalmente a localhost o a una IP privada.
  static const String baseUrl =
      'https://costa-de-oro-imports-python.onrender.com';
  static const String passkeyRpId = String.fromEnvironment(
    'PASSKEY_RP_ID',
    defaultValue: 'costa-de-oro-imports-python.onrender.com',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  // Render puede tardar en despertar una instancia gratuita tras inactividad.
  static const Duration receiveTimeout = Duration(seconds: 90);
}
