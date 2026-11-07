import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/config/app_config.dart';

/// Error de un proveedor social con un mensaje apto para mostrar al usuario.
class SocialAuthException implements Exception {
  const SocialAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Credencial de Apple. Apple solo envía el nombre la primera vez que el
/// usuario autoriza la app, así que se reenvía al backend para el registro.
class AppleCredential {
  const AppleCredential({
    required this.identityToken,
    this.givenName,
    this.familyName,
  });

  final String identityToken;
  final String? givenName;
  final String? familyName;
}

/// Obtiene el token de identidad de Google o Apple.
///
/// No habla con la API: solo devuelve el token del proveedor para que
/// [AuthRepository] lo envíe al backend, que es quien lo valida.
/// Los métodos devuelven `null` cuando el usuario cancela.
class SocialAuthService {
  SocialAuthService({GoogleSignIn? googleSignIn})
    : _google = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _google;

  // initialize() solo puede llamarse una vez por proceso.
  static Future<void>? _googleInit;

  Future<void> _ensureGoogleInitialized() {
    return _googleInit ??= _google
        .initialize(
          // El client ID de iOS solo aplica en iOS; Android usa serverClientId.
          clientId: defaultTargetPlatform == TargetPlatform.iOS
              ? _nonEmpty(AppConfig.googleIosClientId)
              : null,
          serverClientId: _nonEmpty(AppConfig.googleServerClientId),
        )
        .catchError((Object error) {
          _googleInit = null;
          throw error;
        });
  }

  Future<String?> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      if (!_google.supportsAuthenticate()) {
        throw const SocialAuthException(
          'El inicio de sesión con Google no está disponible en este dispositivo.',
        );
      }
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const SocialAuthException(
          'Google no devolvió un token válido. Intenta de nuevo.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      _log('Google Sign-In', error);
      throw const SocialAuthException(
        'No fue posible iniciar sesión con Google.',
      );
    } on SocialAuthException {
      rethrow;
    } catch (error) {
      _log('Google Sign-In', error);
      throw const SocialAuthException(
        'No fue posible iniciar sesión con Google.',
      );
    }
  }

  Future<AppleCredential?> signInWithApple() async {
    if (!await SignInWithApple.isAvailable()) {
      throw const SocialAuthException(
        'Iniciar sesión con Apple no está disponible en este dispositivo.',
      );
    }
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final token = credential.identityToken;
      if (token == null || token.isEmpty) {
        throw const SocialAuthException(
          'Apple no devolvió un token válido. Intenta de nuevo.',
        );
      }
      return AppleCredential(
        identityToken: token,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      _log('Sign in with Apple', error);
      throw const SocialAuthException(
        'No fue posible iniciar sesión con Apple.',
      );
    } on SocialAuthException {
      rethrow;
    } catch (error) {
      _log('Sign in with Apple', error);
      throw const SocialAuthException(
        'No fue posible iniciar sesión con Apple.',
      );
    }
  }

  /// Cierra la sesión local de Google para que la próxima vez se pueda
  /// elegir otra cuenta. Apple no mantiene sesión en la app.
  Future<void> signOut() async {
    if (_googleInit == null) {
      return;
    }
    try {
      await _google.signOut();
    } catch (error) {
      _log('Google Sign-Out', error);
    }
  }

  static String? _nonEmpty(String value) => value.isEmpty ? null : value;

  static void _log(String provider, Object error) {
    if (kDebugMode) {
      debugPrint('[$provider] $error');
    }
  }
}
