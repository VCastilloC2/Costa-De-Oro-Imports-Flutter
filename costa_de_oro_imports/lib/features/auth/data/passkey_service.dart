// RAMA: feature/Passkeys
// ============================================================================
// SERVICIO: PasskeyService
// ============================================================================
// Ejecuta las ceremonias WebAuthn / FIDO2 en el dispositivo:
//  - iOS: AuthenticationServices (Face ID / Touch ID, iCloud Keychain).
//  - Android: Credential Manager (huella / bloqueo de pantalla, Google
//    Password Manager y cualquier proveedor de passkeys instalado).
//
// No habla con la API: recibe las opciones que genera el backend, las
// endurece (ver [PasskeyOptionsGuard]), muestra la hoja del sistema y
// devuelve la respuesta firmada para que [AuthRepository] la envíe al
// backend, que es quien verifica la firma con la clave pública guardada.
// ============================================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

import '../../../core/config/passkey_config.dart';

/// Motivo por el que una ceremonia de passkey no terminó.
enum PasskeyFailure {
  /// El usuario cerró la hoja del sistema. No es un error.
  cancelled,

  /// No hay passkeys de esta app en el dispositivo / cuenta.
  noCredentials,

  /// Ya existe una passkey de este usuario en este dispositivo.
  alreadyRegistered,

  /// El dispositivo o el SO no soporta passkeys (iOS < 16, Android < 9,
  /// sin Google Play Services, sin bloqueo de pantalla…).
  unsupported,

  /// `PASSKEY_RP_ID` no está configurado: la función está apagada.
  notConfigured,

  /// El dominio no está asociado a la app (AASA / assetlinks.json).
  domainNotAssociated,

  /// El backend envió opciones inválidas o de otro dominio.
  invalidServerOptions,

  /// Se agotó el tiempo de la hoja del sistema.
  timeout,

  /// Cualquier otro error del autenticador.
  failed,
}

/// Error de passkey con un mensaje apto para mostrar al usuario.
class PasskeyException implements Exception {
  const PasskeyException(this.failure, this.message, {this.cause});

  final PasskeyFailure failure;
  final String message;

  /// Error original (solo para logs; nunca se muestra).
  final Object? cause;

  bool get isCancelled => failure == PasskeyFailure.cancelled;

  /// Errores que no merecen un mensaje cuando el intento fue automático.
  bool get isSilentOnAutoPrompt =>
      failure == PasskeyFailure.cancelled ||
      failure == PasskeyFailure.noCredentials ||
      failure == PasskeyFailure.unsupported ||
      failure == PasskeyFailure.timeout;

  @override
  String toString() => 'PasskeyException(${failure.name}): $message';
}

// ============================================================================
// PUERTO HACIA LA PLATAFORMA
// ============================================================================

/// Operaciones nativas. Se abstraen para poder probar el flujo sin
/// dispositivo (ver `test/passkey_test.dart`).
abstract interface class PasskeyCeremonies {
  /// `true` si el dispositivo puede crear y usar passkeys.
  Future<bool> isSupported();

  /// `navigator.credentials.create()`: crea la passkey (pide biometría).
  Future<RegisterResponseType> create(RegisterRequestType request);

  /// `navigator.credentials.get()`: firma el challenge (pide biometría).
  Future<AuthenticateResponseType> get(AuthenticateRequestType request);
}

/// Implementación real sobre el paquete `passkeys`.
class PlatformPasskeyCeremonies implements PasskeyCeremonies {
  PlatformPasskeyCeremonies([this._injected]);

  final PasskeyAuthenticator? _injected;

  /// Perezoso: no toca el canal nativo hasta que se usa (y nunca si
  /// `PASSKEY_RP_ID` está vacío).
  late final PasskeyAuthenticator _authenticator =
      _injected ?? PasskeyAuthenticator();

  @override
  Future<bool> isSupported() async {
    if (kIsWeb) return false;
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          final a = await _authenticator.getAvailability().iOS();
          return a.hasPasskeySupport;
        case TargetPlatform.android:
          final a = await _authenticator.getAvailability().android();
          // Sin un autenticador que verifique al usuario (huella, PIN,
          // patrón) no se puede cumplir `userVerification: required`.
          return a.hasPasskeySupport &&
              a.isUserVerifyingPlatformAuthenticatorAvailable != false;
        default:
          return false;
      }
    } catch (error) {
      PasskeyService.log('availability', error);
      return false;
    }
  }

  @override
  Future<RegisterResponseType> create(RegisterRequestType request) =>
      _guard(() => _authenticator.register(request));

  @override
  Future<AuthenticateResponseType> get(AuthenticateRequestType request) =>
      _guard(() => _authenticator.authenticate(request));

  /// Traduce las excepciones del paquete a [PasskeyException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PasskeyException {
      rethrow;
    } on AuthenticatorException catch (error) {
      throw _map(error);
    } catch (error) {
      PasskeyService.log('platform', error);
      throw PasskeyException(
        PasskeyFailure.failed,
        'No fue posible usar la passkey. Intenta de nuevo.',
        cause: error,
      );
    }
  }

  static PasskeyException _map(AuthenticatorException error) {
    PasskeyService.log('authenticator', error);
    return switch (error) {
      PasskeyAuthCancelledException() => PasskeyException(
        PasskeyFailure.cancelled,
        'Operación cancelada.',
        cause: error,
      ),
      NoCredentialsAvailableException() ||
      CredentialNotAuthenticatedException() => PasskeyException(
        PasskeyFailure.noCredentials,
        'No encontramos una passkey para esta app en tu dispositivo.',
        cause: error,
      ),
      ExcludeCredentialsCanNotBeRegisteredException() => PasskeyException(
        PasskeyFailure.alreadyRegistered,
        'Este dispositivo ya tiene una passkey para tu cuenta.',
        cause: error,
      ),
      DomainNotAssociatedException() => PasskeyException(
        PasskeyFailure.domainNotAssociated,
        'Las passkeys no están configuradas para este dominio.',
        cause: error,
      ),
      DeviceNotSupportedException() ||
      PasskeyUnsupportedException() ||
      NoCreateOptionException() ||
      MissingGoogleSignInException() ||
      SyncAccountNotAvailableException() => PasskeyException(
        PasskeyFailure.unsupported,
        'Tu dispositivo no admite passkeys. Verifica que tengas un bloqueo '
        'de pantalla y una cuenta de Google/iCloud activa.',
        cause: error,
      ),
      TimeoutException() => PasskeyException(
        PasskeyFailure.timeout,
        'Se agotó el tiempo. Intenta de nuevo.',
        cause: error,
      ),
      MalformedBase64Url() => PasskeyException(
        PasskeyFailure.invalidServerOptions,
        'El servidor envió una solicitud de passkey inválida.',
        cause: error,
      ),
      _ => PasskeyException(
        PasskeyFailure.failed,
        'No fue posible usar la passkey. Intenta de nuevo.',
        cause: error,
      ),
    };
  }
}

// ============================================================================
// VALIDACIÓN Y ENDURECIMIENTO DE OPCIONES
// ============================================================================

/// Valida las opciones WebAuthn que manda el backend antes de mostrarlas
/// al usuario, y fuerza los requisitos de seguridad mínimos.
///
/// Es defensa en profundidad: la verificación real (firma, origen, rpIdHash,
/// flags UV, contador) la hace el backend. Aquí se evita que un backend mal
/// configurado o una respuesta manipulada:
///  - pida una passkey para **otro dominio** (validación de dominio),
///  - use un challenge débil o vacío (protección de replay),
///  - permita autenticar sin biometría/PIN (`userVerification`),
///  - cree credenciales no descubribles (sin ellas no hay login sin correo).
class PasskeyOptionsGuard {
  const PasskeyOptionsGuard(this.rpId);

  final String rpId;

  /// Algoritmos COSE aceptados: ES256 (todas las plataformas) y RS256
  /// (Windows Hello / llaves antiguas).
  static const defaultAlgorithms = [
    {'type': 'public-key', 'alg': -7},
    {'type': 'public-key', 'alg': -257},
  ];

  /// Opciones de `navigator.credentials.create()` endurecidas.
  Map<String, dynamic> hardenCreation(Map<String, dynamic> options) {
    final rp = _map(options['rp'], 'rp');
    _checkRpId(rp['id']);
    _checkChallenge(options['challenge']);

    final user = _map(options['user'], 'user');
    final userId = user['id'];
    final userName = user['name'];
    if (userId is! String || userId.isEmpty) {
      throw _invalid('user.id vacío');
    }
    if (userName is! String || userName.isEmpty) {
      throw _invalid('user.name vacío');
    }

    final selection = options['authenticatorSelection'];
    final params = options['pubKeyCredParams'];

    return {
      ...options,
      'rp': {...rp, 'name': (rp['name'] as String?) ?? rpId},
      'user': {
        ...user,
        'displayName': (user['displayName'] as String?)?.isNotEmpty == true
            ? user['displayName']
            : userName,
      },
      'pubKeyCredParams': params is List && params.isNotEmpty
          ? params
          : defaultAlgorithms,
      'authenticatorSelection': {
        if (selection is Map) ...selection.cast<String, dynamic>(),
        // Passkey descubrible: permite el login sin escribir el correo.
        'residentKey': 'required',
        'requireResidentKey': true,
        // Biometría o PIN del dispositivo obligatorios.
        'userVerification': 'required',
      },
      'timeout': _timeout(options['timeout']),
    };
  }

  /// Opciones de `navigator.credentials.get()` endurecidas.
  Map<String, dynamic> hardenRequest(Map<String, dynamic> options) {
    _checkRpId(options['rpId']);
    _checkChallenge(options['challenge']);
    return {
      ...options,
      'userVerification': 'required',
      'timeout': _timeout(options['timeout']),
    };
  }

  void _checkRpId(Object? value) {
    if (value is! String || value.isEmpty) {
      throw _invalid('rpId ausente');
    }
    if (value.toLowerCase() != rpId.toLowerCase()) {
      // Posible phishing o backend apuntando a otro dominio.
      throw _invalid('rpId "$value" no coincide con "$rpId"');
    }
  }

  void _checkChallenge(Object? value) {
    if (value is! String || value.isEmpty) {
      throw _invalid('challenge ausente');
    }
    final List<int> bytes;
    try {
      bytes = base64Url.decode(base64Url.normalize(value));
    } on FormatException {
      throw _invalid('challenge no es base64url');
    }
    if (bytes.length < PasskeyConfig.minChallengeBytes) {
      throw _invalid('challenge demasiado corto (${bytes.length} bytes)');
    }
  }

  static int _timeout(Object? value) {
    final max = PasskeyConfig.ceremonyTimeout.inMilliseconds;
    if (value is num && value > 0 && value <= max) return value.toInt();
    return max;
  }

  static Map<String, dynamic> _map(Object? value, String field) {
    if (value is Map) return value.cast<String, dynamic>();
    throw _invalid('$field ausente');
  }

  static PasskeyException _invalid(String reason) {
    PasskeyService.log('options', reason);
    return PasskeyException(
      PasskeyFailure.invalidServerOptions,
      'El servidor envió una solicitud de passkey inválida.',
      cause: reason,
    );
  }
}

// ============================================================================
// SERVICIO
// ============================================================================

/// Punto de entrada de la app para las ceremonias de passkey.
class PasskeyService {
  PasskeyService({PasskeyCeremonies? ceremonies, String? rpId})
    : _ceremonies = ceremonies ?? PlatformPasskeyCeremonies(),
      rpId = rpId ?? PasskeyConfig.rpId;

  final PasskeyCeremonies _ceremonies;

  /// Dominio esperado en las opciones del backend.
  final String rpId;

  bool get isConfigured => rpId.isNotEmpty;

  PasskeyOptionsGuard get _guard => PasskeyOptionsGuard(rpId);

  /// `true` si la función está configurada y el dispositivo la soporta.
  Future<bool> isAvailable() async {
    if (!isConfigured) return false;
    return _ceremonies.isSupported();
  }

  /// Crea una passkey con las opciones del backend y devuelve el
  /// `PublicKeyCredential` (JSON WebAuthn) para `/register/verify`.
  Future<Map<String, dynamic>> createCredential(
    Map<String, dynamic> options,
  ) async {
    _ensureConfigured();
    final hardened = _guard.hardenCreation(options);
    final request = _parse(() => RegisterRequestType.fromJson(hardened));
    log('create', 'mostrando hoja de registro');
    final response = await _ceremonies.create(request);
    return {
      ...response.toJson(),
      // Las passkeys de este flujo siempre son del autenticador del SO.
      'authenticatorAttachment': 'platform',
    };
  }

  /// Firma el challenge del backend con una passkey y devuelve la
  /// aserción (JSON WebAuthn) para `/login/verify`.
  ///
  /// Con [preferImmediatelyAvailable] no se muestra nada si no hay una
  /// passkey local (útil para el intento automático al abrir el login);
  /// sin él, el SO también ofrece passkeys de otro dispositivo (QR).
  Future<Map<String, dynamic>> getAssertion(
    Map<String, dynamic> options, {
    bool preferImmediatelyAvailable = false,
  }) async {
    _ensureConfigured();
    final hardened = _guard.hardenRequest(options);
    final request = _parse(
      () => AuthenticateRequestType.fromJson(
        hardened,
        preferImmediatelyAvailableCredentials: preferImmediatelyAvailable,
      ),
    );
    log('get', 'mostrando hoja de autenticación');
    final response = await _ceremonies.get(request);
    return {...response.toJson(), 'authenticatorAttachment': 'platform'};
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw const PasskeyException(
        PasskeyFailure.notConfigured,
        'El inicio de sesión con passkey no está disponible.',
      );
    }
  }

  static T _parse<T>(T Function() build) {
    try {
      return build();
    } catch (error) {
      log('options', error);
      throw PasskeyException(
        PasskeyFailure.invalidServerOptions,
        'El servidor envió una solicitud de passkey inválida.',
        cause: error,
      );
    }
  }

  /// Log solo en debug. Nunca se registran challenges, credenciales ni firmas.
  static void log(String stage, Object message) {
    if (kDebugMode) {
      debugPrint('[Passkeys][$stage] $message');
    }
  }
}

final passkeyServiceProvider = Provider<PasskeyService>(
  (ref) => PasskeyService(),
);
