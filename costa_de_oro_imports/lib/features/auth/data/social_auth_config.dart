/// Identificadores públicos de OAuth cargados desde `.env` al iniciar Flutter.
import 'package:costa_de_oro_imports/core/config/app_environment.dart';

class SocialAuthConfig {
  SocialAuthConfig._();

  /// ID de cliente web de Google, usado como serverClientId para recibir idToken.
  static String get googleServerClientId =>
      AppEnvironment.get('GOOGLE_SERVER_CLIENT_ID');

  /// ID de cliente iOS de Google. También se puede configurar en GoogleService-Info.plist.
  static String get googleIosClientId =>
      AppEnvironment.get('GOOGLE_IOS_CLIENT_ID');

  /// Service ID de Apple, requerido para el flujo web de Android.
  static String get appleServiceId => AppEnvironment.get('APPLE_SERVICE_ID');

  /// URL pública HTTPS configurada como Return URL del Service ID de Apple.
  static String get appleRedirectUri =>
      AppEnvironment.get('APPLE_REDIRECT_URI');
}
