import 'dart:convert';
import 'dart:typed_data';

import 'package:costa_de_oro_imports/core/network/api_client.dart';
import 'package:costa_de_oro_imports/core/network/api_exception.dart';
import 'package:costa_de_oro_imports/core/storage/response_cache.dart';
import 'package:costa_de_oro_imports/core/storage/session_storage.dart';
import 'package:costa_de_oro_imports/features/auth/data/auth_repository.dart';
import 'package:costa_de_oro_imports/features/auth/data/passkey_service.dart';
import 'package:costa_de_oro_imports/features/auth/presentation/widgets/passkey_widgets.dart';
import 'package:costa_de_oro_imports/features/profile/presentation/pages/passkeys_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      backend.routes['/api/v1/auth/passkey/login/start'] = (
        200,
        _loginOptions(),
      );
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
      backend.routes['/api/v1/auth/passkey/login/start'] = (
        200,
        _loginOptions(),
      );
      backend.routes['/api/v1/auth/passkey/login/finish'] = (
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

        final body =
            backend.received['/api/v1/auth/passkey/login/finish'] as Map;
        expect(body['challenge_id'], 'ch-1');
        final credential = body['credential'] as Map;
        expect(credential['type'], 'public-key');
        expect((credential['response'] as Map)['signature'], 'sig');
      },
    );

    test('login/* es público y register/* lleva el token (Dio real)', () async {
      await storage.saveToken('viejo');
      final dio = createApiDio(storage)..httpClientAdapter = backend;
      backend.routes['/api/v1/auth/passkey/register/start'] = (
        200,
        _registerOptions(),
      );

      await dio.post<dynamic>('/api/v1/auth/passkey/login/start');
      await dio.post<dynamic>('/api/v1/auth/passkey/register/start');

      expect(
        backend.headers['/api/v1/auth/passkey/login/start']!.containsKey(
          'Authorization',
        ),
        isFalse,
      );
      expect(
        backend
            .headers['/api/v1/auth/passkey/register/start']!['Authorization'],
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
        backend.received.containsKey('/api/v1/auth/passkey/login/finish'),
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
      backend.routes['/api/v1/auth/passkey/login/finish'] = (
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
      backend.routes['/api/v1/auth/passkey/login/start'] = (
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
      backend.routes['/api/v1/auth/passkey/login/start'] = (
        200,
        {'challenge': _challenge, 'rpId': _rpId},
      );
      await repo.loginWithPasskey();
      final body = backend.received['/api/v1/auth/passkey/login/finish'] as Map;
      expect(body.containsKey('challenge_id'), isFalse);
    });
  });

  group('registerPasskey', () {
    setUp(() {
      backend.routes['/api/v1/auth/passkey/register/start'] = (
        200,
        _registerOptions(),
      );
      backend.routes['/api/v1/auth/passkey/register/finish'] = (
        200,
        {'ok': true},
      );
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

      final body =
          backend.received['/api/v1/auth/passkey/register/finish'] as Map;
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
        backend.received.containsKey('/api/v1/auth/passkey/register/finish'),
        isFalse,
      );
      expect(await storage.readPasskeyUser(), 'ana@test.com');
    });
  });

  group('backend FastAPI: registro duplicado, sesión y gestión', () {
    Map<String, dynamic> passkeyJson(int id, String credentialId) => {
      'passkey_id': id,
      'credential_id': credentialId,
      'device_name': id == 1 ? 'iOS' : 'Android',
      'device_type': 'multi_device',
      'backed_up': id == 1,
      'created_at': '2026-11-07T10:30:00',
      'last_used_at': null,
    };

    test('register/finish 409 significa que ya está vinculada', () async {
      backend.routes[PasskeyEndpoints.registerStart] = (
        200,
        _registerOptions(),
      );
      backend.routes[PasskeyEndpoints.registerFinish] = (
        409,
        {'detail': 'Esta passkey ya está registrada.'},
      );
      await storage.saveToken('jwt');
      await repo.registerPasskey();
      expect(await storage.readPasskeyUser(), 'ana@test.com');
      expect(await storage.readPasskeyCredentialId(), 'cred-1');
    });

    test('el login recuerda la passkey de este dispositivo', () async {
      backend.routes[PasskeyEndpoints.loginStart] = (200, _loginOptions());
      backend.routes[PasskeyEndpoints.loginFinish] = (
        200,
        {
          'accessToken': 'jwt-123',
          'auth_method': 'passkey',
          'usuario': {'usuario_id': 7, 'correo': 'ana@test.com'},
        },
      );
      await repo.loginWithPasskey();
      expect(await storage.readPasskeyCredentialId(), 'cred-1');
    });

    test('validateSession distingue válida, rechazada y desconocida', () async {
      await storage.saveToken('jwt');
      backend.routes[PasskeyEndpoints.sessionValidate] = (
        200,
        {'valid': true, 'usuario_id': 7, 'expires_in': 3000},
      );
      expect(await repo.validateSession(), isTrue);
      backend.routes[PasskeyEndpoints.sessionValidate] = (
        401,
        {'detail': 'Sesión inválida o expirada'},
      );
      expect(await repo.validateSession(), isFalse);
      backend.routes[PasskeyEndpoints.sessionValidate] = (
        503,
        {'detail': 'Valkey no disponible'},
      );
      expect(await repo.validateSession(), isNull);
    });

    test(
      'restoreSession no pide /perfil si Valkey rechaza la sesión',
      () async {
        await storage.saveToken('jwt');
        backend.routes[PasskeyEndpoints.sessionValidate] = (
          401,
          {'detail': 'Sesión inválida o expirada'},
        );
        backend.routes['/perfil'] = (
          200,
          {'usuario_id': 7, 'correo': 'a@b.co'},
        );
        expect(await repo.restoreSession(), isNull);
        expect(await storage.readToken(), isNull);
        expect(backend.received.containsKey('/perfil'), isFalse);
      },
    );

    test('restoreSession sigue con /perfil si no se puede validar', () async {
      await storage.saveToken('jwt');
      // Sin ruta de validación: el backend responde 404 (versión anterior).
      backend.routes['/perfil'] = (200, {'usuario_id': 7, 'correo': 'a@b.co'});
      final user = await repo.restoreSession();
      expect(user!.id, 7);
      expect(await storage.readToken(), 'jwt');
    });

    test(
      'lista y revoca; la de este dispositivo apaga el auto-login',
      () async {
        await storage.saveToken('jwt');
        await storage.savePasskeyUser('ana@test.com');
        await storage.savePasskeyCredentialId('cred-1');
        backend.routes[PasskeyEndpoints.credentials] = (
          200,
          [passkeyJson(1, 'cred-1'), passkeyJson(2, 'otra')],
        );
        backend.routes['${PasskeyEndpoints.credentials}/1'] = (
          200,
          {'success': true},
        );
        backend.routes['${PasskeyEndpoints.credentials}/2'] = (
          200,
          {'success': true},
        );

        final passkeys = await repo.listPasskeys();
        expect(passkeys.map((p) => p.id), [1, 2]);
        expect(passkeys.first.backedUp, isTrue);
        expect(passkeys.first.createdAt, DateTime(2026, 11, 7, 10, 30));
        expect(passkeys.first.lastUsedAt, isNull);
        expect(backend.headers[PasskeyEndpoints.credentials], isNotNull);

        await repo.revokePasskey(passkeys[1]);
        expect(await storage.readPasskeyUser(), 'ana@test.com');
        await repo.revokePasskey(passkeys[0]);
        expect(await storage.readPasskeyUser(), isNull);
        expect(await storage.readPasskeyCredentialId(), isNull);
      },
    );

    testWidgets('PasskeysPage lista, marca este dispositivo y revoca', (
      tester,
    ) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        if ('${details.exception}'.contains('GoogleFonts')) return;
        original?.call(details);
      };
      addTearDown(() => FlutterError.onError = original);

      backend.routes[PasskeyEndpoints.credentials] = (
        200,
        [passkeyJson(1, 'cred-1'), passkeyJson(2, 'otra')],
      );
      backend.routes['${PasskeyEndpoints.credentials}/2'] = (
        200,
        {'success': true},
      );
      await tester.runAsync(() => storage.savePasskeyCredentialId('cred-1'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            sessionStorageProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(home: PasskeysPage()),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byKey(const Key('passkey-tile-1')), findsOneWidget);
      expect(find.byKey(const Key('passkey-tile-2')), findsOneWidget);
      expect(find.text('Este dispositivo'), findsOneWidget);

      await tester.tap(find.byKey(const Key('passkey-revoke-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('passkey-revoke-confirm')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        backend.received.containsKey('${PasskeyEndpoints.credentials}/2'),
        isTrue,
      );
      expect(find.text('Passkey eliminada.'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
