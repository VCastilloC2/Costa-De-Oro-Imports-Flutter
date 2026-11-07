// RAMA: chore/Core
// ============================================================================
// CONFIGURACIÓN DE LA API
// ============================================================================
// Centraliza la URL base y los tiempos de espera para las peticiones HTTP.
// Modificar este archivo afecta a toda la aplicación.
// ============================================================================

class ApiConfig {
  ApiConfig._();

  /// URL por defecto: backend en la red local (LAN).
  ///
  /// Alternativas según cómo pruebes:
  /// - Teléfono por cable con `adb reverse tcp:8000 tcp:8000`:
  ///   `http://127.0.0.1:8000`. Evita los bloqueos (Client Isolation) del Wi-Fi.
  /// - Android Emulator: `http://10.0.2.2:8000`.
  /// - iOS Simulator: `http://localhost:8000`.
  static const String _defaultBaseUrl = 'http://192.168.1.9:8000';

  /// Se puede cambiar sin tocar código:
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
  /// o con `--dart-define-from-file=config/dev.json`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
