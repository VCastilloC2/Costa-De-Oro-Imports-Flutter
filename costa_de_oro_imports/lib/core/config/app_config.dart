import 'package:flutter/foundation.dart';

/// Valores de configuración que cambian entre entornos (local / producción).
///
/// Todos se leen de `--dart-define` en tiempo de compilación, así no hay
/// URLs ni identificadores escritos en las páginas. Ejemplo:
///
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000
/// flutter run --dart-define-from-file=config/dev.json
/// ```
class AppConfig {
  AppConfig._();

  static const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// URL base de la API FastAPI.
  ///
  /// Si no se define `API_BASE_URL`, apunta al backend local:
  /// - Android Emulator: `10.0.2.2` es el `localhost` de la computadora.
  /// - iOS Simulator, web y escritorio: `localhost`.
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  /// Client ID de tipo "Web application" de Google Cloud.
  ///
  /// En Android es obligatorio para que Google devuelva un `idToken`, y es el
  /// `aud` que el backend debe validar. No es un secreto, pero se mantiene
  /// fuera del código para poder cambiarlo por entorno.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// Client ID de tipo "iOS" de Google Cloud (solo se usa en iOS).
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
}
