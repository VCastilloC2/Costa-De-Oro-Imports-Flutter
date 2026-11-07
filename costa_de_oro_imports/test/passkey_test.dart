import 'dart:convert';
import 'dart:typed_data';

import 'package:costa_de_oro_imports/core/network/api_client.dart';
import 'package:costa_de_oro_imports/core/network/api_exception.dart';
import 'package:costa_de_oro_imports/core/storage/response_cache.dart';
import 'package:costa_de_oro_imports/core/storage/session_storage.dart';
import 'package:costa_de_oro_imports/features/auth/data/auth_repository.dart';
import 'package:costa_de_oro_imports/features/auth/data/passkey_service.dart';
import 'package:costa_de_oro_imports/features/auth/presentation/widgets/passkey_widgets.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:passkeys/types.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _rpId = 'costadeoro.test';
final _challenge = base64Url
    .encode(List<int>.generate(32, (i) => i))
    .replaceAll('=', '');

/// Backend falso: responde según la ruta y guarda los cuerpos recibidos.
class _FakeBackend implements HttpClientAdapter {
  final Map<String, (int, Object?)> routes = {};
  final Map<String, Object?> received = {};
  final Map<String, Map<String, dynamic>> headers = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    received[options.path] = options.data;
    headers[options.path] = options.headers;
    final route = routes[options.path];
    if (route == null) {
      return ResponseBody.fromString(
        '{"detail":"no existe"}',
        404,
        headers: _json,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(route.$2),
      route.$1,
      headers: _json,
    );
  }

  static const _json = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  void close({bool force = false}) {}
}

/// Autenticador falso: reemplaza Face ID / huella.
class _FakeCeremonies implements PasskeyCeremonies {
  bool supported = true;
  PasskeyException? error;
  RegisterRequestType? lastCreate;
  AuthenticateRequestType? lastGet;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<RegisterResponseType> create(RegisterRequestType request) async {
    lastCreate = request;
    if (error != null) throw error!;
    return RegisterResponseType(
      id: 'cred-1',
      rawId: 'cred-1',
      clientDataJSON: 'cdj',
      attestationObject: 'att',
      transports: const ['internal', 'hybrid'],
    );
  }

  @override
  Future<AuthenticateResponseType> get(AuthenticateRequestType request) async {
    lastGet = request;
    if (error != null) throw error!;
    return const AuthenticateResponseType(
      id: 'cred-1',
      rawId: 'cred-1',
      clientDataJSON: 'cdj',
      authenticatorData: 'ad',
      signature: 'sig',
      userHandle: 'uh',
    );
  }
}

Map<String, dynamic> _loginOptions({String rpId = _rpId}) => {
  'challenge_id': 'ch-1',
  'options': {
    'challenge': _challenge,
    'rpId': rpId,
    'userVerification': 'preferred',
  },
};

Map<String, dynamic> _registerOptions() => {
  'challenge_id': 'ch-2',
  'options': {
    'challenge': _challenge,
    'rp': {'id': _rpId, 'name': 'Costa de Oro'},
    'user': {'id': 'dXNlcg', 'name': 'ana@test.com', 'displayName': 'Ana'},
    'authenticatorSelection': {
      'residentKey': 'preferred',
      'userVerification': 'preferred',
    },
    'excludeCredentials': [],
  },
};

void main() {
  late _FakeBackend backend;
  late _FakeCeremonies ceremonies;
  late SessionStorage storage;
  late AuthRepository repo;

  AuthRepository buildRepo({String rpId = _rpId}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = backend;
    return AuthRepository(
      dio,
      storage,
      cache: ResponseCache(),
      passkeys: PasskeyService(ceremonies: ceremonies, rpId: rpId),
    );
  }

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    FlutterSecureStorage.setMockInitialValues({});
    storage = SessionStorage();
    backend = _FakeBackend();
    ceremonies = _FakeCeremonies();
    repo = buildRepo();
  });

  group('PasskeyOptionsGuard', () {
    const guard = PasskeyOptionsGuard(_rpId);

    test('rechaza opciones de otro dominio (validación de dominio)', () {
      expect(
        () =>
            guard.hardenRequest({'challenge': _challenge, 'rpId': 'evil.com'}),
        throwsA(
          isA<PasskeyException>().having(
            (e) => e.failure,
            'failure',
            PasskeyFailure.invalidServerOptions,
          ),
        ),
      );
    });

    test('rechaza challenges cortos o vacíos', () {
      expect(
        () => guard.hardenRequest({'challenge': 'AAAA', 'rpId': _rpId}),
        throwsA(isA<PasskeyException>()),
      );
      expect(
        () => guard.hardenRequest({'challenge': '', 'rpId': _rpId}),
        throwsA(isA<PasskeyException>()),
      );
    });

    test('fuerza verificación de usuario y passkey descubrible', () {
      final opts = guard.hardenCreation(
        (_registerOptions()['options'] as Map).cast<String, dynamic>(),
      );
      final sel = opts['authenticatorSelection'] as Map;
      expect(sel['userVerification'], 'required');
      expect(sel['residentKey'], 'required');
      expect(opts['pubKeyCredParams'], PasskeyOptionsGuard.defaultAlgorithms);
      expect(opts['timeout'], 120000);
    });

    test('acepta el rpId sin distinguir mayúsculas', () {
      final opts = guard.hardenRequest({
        'challenge': _challenge,
        'rpId': 'CostaDeOro.TEST',
        'timeout': 30000,
      });
      expect(opts['userVerification'], 'required');
      expect(opts['timeout'], 30000);
    });
  });

  group('disponibilidad', () {
    test('sin PASSKEY_RP_ID la función está apagada', () async {
      final repo = buildRepo(rpId: '');
      expect(await repo.isPasskeyAvailable(), isFalse);
      expect(await repo.shouldOfferPasskeyEnrollment(), isFalse);
      expect(await repo.shouldAutoPromptPasskey(), isFalse);
      backend.routes['/auth/passkey/login/options'] = (200, _loginOptions());
      await expectLater(
        repo.loginWithPasskey(),
        throwsA(
          isA<PasskeyException>().having(
            (e) => e.failure,
            'failure',
            PasskeyFailure.notConfigured,
          ),
        ),
      );
      expect(ceremonies.lastGet, isNull);
    });

    test('ofrece el registro una sola vez si el usuario lo rechaza', () async {
      expect(await repo.shouldOfferPasskeyEnrollment(), isTrue);
      await repo.dismissPasskeyOffer();
      expect(await repo.shouldOfferPasskeyEnrollment(), isFalse);
      expect(
        await repo.shouldOfferPasskeyEnrollment(ignoreDismissed: true),
        isTrue,
      );
    });
  });

  group('loginWithPasskey', () {
    setUp(() {
      backend.routes['/auth/passkey/login/options'] = (200, _loginOptions());
      backend.routes['/auth/passkey/login/verify'] = (
        200,
        {
          'accessToken': 'jwt-123',
          'usuario': {'usuario_id': 7, 'correo': 'ana@test.com'},
        },
      );
    });

    test(
      'firma el challenge, guarda el token y recuerda el dispositivo',
      () async {
        final user = await repo.loginWithPasskey();

        expect(user.id, 7);
        expect(await storage.readToken(), 'jwt-123');
        expect(await storage.readPasskeyUser(), 'ana@test.com');
        expect(await repo.shouldAutoPromptPasskey(), isTrue);

        expect(ceremonies.lastGet!.userVerification, 'required');
        expect(ceremonies.lastGet!.relyingPartyId, _rpId);

        final body = backend.received['/auth/passkey/login/verify'] as Map;
        expect(body['challenge_id'], 'ch-1');
        final credential = body['credential'] as Map;
        expect(credential['type'], 'public-key');
        expect((credential['response'] as Map)['signature'], 'sig');
      },
    );

    test('login/* es público y register/* lleva el token (Dio real)', () async {
      await storage.saveToken('viejo');
      final dio = createApiDio(storage)..httpClientAdapter = backend;
      backend.routes['/auth/passkey/register/options'] = (
        200,
        _registerOptions(),
      );

      await dio.post<dynamic>('/auth/passkey/login/options');
      await dio.post<dynamic>('/auth/passkey/register/options');

      expect(
        backend.headers['/auth/passkey/login/options']!.containsKey(
          'Authorization',
        ),
        isFalse,
      );
      expect(
        backend.headers['/auth/passkey/register/options']!['Authorization'],
        'Bearer viejo',
      );
    });

    test('cancelar no inicia sesión ni llama a /verify', () async {
      ceremonies.error = const PasskeyException(
        PasskeyFailure.cancelled,
        'cancelado',
      );
      await expectLater(
        repo.loginWithPasskey(),
        throwsA(
          isA<PasskeyException>().having((e) => e.isCancelled, 'cancel', true),
        ),
      );
      expect(await storage.readToken(), isNull);
      expect(
        backend.received.containsKey('/auth/passkey/login/verify'),
        isFalse,
      );
    });

    test(
      'sin passkeys en el dispositivo deja de ofrecer el auto-login',
      () async {
        await storage.savePasskeyUser('ana@test.com');
        ceremonies.error = const PasskeyException(
          PasskeyFailure.noCredentials,
          'sin passkeys',
        );
        await expectLater(
          repo.loginWithPasskey(autoPrompt: true),
          throwsA(isA<PasskeyException>()),
        );
        expect(
          ceremonies.lastGet!.preferImmediatelyAvailableCredentials,
          isTrue,
        );
        expect(await storage.readPasskeyUser(), isNull);
      },
    );

    test('credencial revocada en el servidor (401) limpia la marca', () async {
      await storage.savePasskeyUser('ana@test.com');
      backend.routes['/auth/passkey/login/verify'] = (
        401,
        {'detail': 'Passkey inválida'},
      );
      await expectLater(
        repo.loginWithPasskey(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'msg',
            'Passkey inválida',
          ),
        ),
      );
      expect(await storage.readPasskeyUser(), isNull);
      expect(await storage.readToken(), isNull);
    });

    test('opciones de otro dominio nunca llegan al autenticador', () async {
      backend.routes['/auth/passkey/login/options'] = (
        200,
        _loginOptions(rpId: 'evil.com'),
      );
      await expectLater(
        repo.loginWithPasskey(),
        throwsA(isA<PasskeyException>()),
      );
      expect(ceremonies.lastGet, isNull);
    });

    test('acepta las opciones sin envoltorio (py_webauthn)', () async {
      backend.routes['/auth/passkey/login/options'] = (
        200,
        {'challenge': _challenge, 'rpId': _rpId},
      );
      await repo.loginWithPasskey();
      final body = backend.received['/auth/passkey/login/verify'] as Map;
      expect(body.containsKey('challenge_id'), isFalse);
    });
  });

  group('registerPasskey', () {
    setUp(() {
      backend.routes['/auth/passkey/register/options'] = (
        200,
        _registerOptions(),
      );
      backend.routes['/auth/passkey/register/verify'] = (200, {'ok': true});
    });

    test('exige sesión activa', () async {
      await expectLater(
        repo.registerPasskey(),
        throwsA(
          isA<ApiException>().having((e) => e.isUnauthorized, '401', true),
        ),
      );
      expect(backend.received, isEmpty);
    });

    test('crea la passkey y envía la clave pública al backend', () async {
      await storage.saveToken('jwt');
      await repo.registerPasskey();

      final req = ceremonies.lastCreate!;
      expect(req.relyingParty.id, _rpId);
      expect(req.authSelectionType!.userVerification, 'required');
      expect(req.authSelectionType!.residentKey, 'required');

      final body = backend.received['/auth/passkey/register/verify'] as Map;
      expect(body['challenge_id'], 'ch-2');
      final credential = body['credential'] as Map;
      expect((credential['response'] as Map)['attestationObject'], 'att');
      expect(credential['authenticatorAttachment'], 'platform');
      expect(await storage.readPasskeyUser(), 'ana@test.com');
    });

    test('si ya existe en el dispositivo no es un error', () async {
      await storage.saveToken('jwt');
      ceremonies.error = const PasskeyException(
        PasskeyFailure.alreadyRegistered,
        'ya existe',
      );
      await repo.registerPasskey();
      expect(
        backend.received.containsKey('/auth/passkey/register/verify'),
        isFalse,
      );
      expect(await storage.readPasskeyUser(), 'ana@test.com');
    });
  });

  test('logout conserva la marca de passkey para el próximo login', () async {
    await storage.saveToken('jwt');
    await storage.savePasskeyUser('ana@test.com');
    await storage.clear();
    expect(await storage.readToken(), isNull);
    expect(await storage.readPasskeyUser(), 'ana@test.com');
  });

  testWidgets(
    'botón de passkey sin desbordes con texto x1.3',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if ('${details.exception}'.contains('GoogleFonts')) return;
        original?.call(details);
      };
      addTearDown(() => FlutterError.onError = original);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery.withClampedTextScaling(
            minScaleFactor: 1.3,
            maxScaleFactor: 1.3,
            child: Scaffold(
              body: Center(
                // Ancho útil del teléfono más pequeño: 320 - 2 x 16.
                child: SizedBox(
                  width: 288,
                  child: PasskeyLoginButton(onPressed: () {}),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('passkey-login-button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );
}
