/// Identificadores de Google Sign-In por entorno.
///
/// Se leen de `--dart-define` en tiempo de compilación para no dejarlos
/// escritos en el código. La URL de la API está en [ApiConfig].
///
/// ```bash
/// flutter run --dart-define-from-file=config/dev.json
/// ```
class AppConfig {
  AppConfig._();

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
