# Passkeys en Flutter

La app usa el backend FastAPI como relying party y el paquete Flutter `passkeys` para invocar el
administrador nativo de credenciales (Android Credential Manager / iOS AuthenticationServices).
Las opciones y respuestas WebAuthn se intercambian sin modificarlas con el backend.

## Flujo implementado

- Login: `POST /auth/passkey/login/options` → solicitud a la plataforma →
  `POST /auth/passkey/login/verify` → guarda `accessToken` y autentica al usuario.
- Registro con sesión: `POST /auth/passkey/register/options` → plataforma →
  `POST /auth/passkey/register/verify`.
- Administración: `GET /api/v1/auth/passkey/credentials` y
  `DELETE /api/v1/auth/passkey/credentials/{passkey_id}`.
- Validación opcional de sesión: `GET /api/v1/auth/session/validate`.

El login usa una credencial descubrible (no solicita correo) y la autenticación requiere verificación
del usuario, tal como establece FastAPI.

## Configurar endpoint y RP ID

El valor por defecto de desarrollo apunta a `https://192.168.1.9` y RP ID `192.168.1.9`.
Para cambiarlo al ejecutar:

```powershell
flutter run `
  --dart-define=API_BASE_URL=https://192.168.1.9 `
  --dart-define=PASSKEY_RP_ID=192.168.1.9
```

En FastAPI usa el mismo RP ID:

```env
PASSKEY_RP_ID=192.168.1.9
PASSKEY_EXPECTED_ORIGINS=https://192.168.1.9,android:apk-key-hash:HASH_ANDROID
```

FastAPI debe escuchar en HTTPS por el puerto 443 para que Android pueda recuperar
`https://192.168.1.9/.well-known/assetlinks.json` sin redirecciones. El certificado TLS debe incluir
`192.168.1.9` como IP SAN y ser confiable en el teléfono. La app no omite la validación del
certificado. Ambos dispositivos deben estar en la misma red y el firewall del computador debe
permitir TCP/443.

## Asociación de Android

El `applicationId` Android actual es `com.example.costa_de_oro_imports`. Para Passkeys de Android,
el servidor HTTPS del RP debe servir `/.well-known/assetlinks.json` con `delegate_permission/common.get_login_creds`, ese package name y el SHA-256 del certificado que firmó el APK instalado. Para admitir debug y release, agrega las huellas de cada certificado. Calcula el origen `android:apk-key-hash:` a partir de la huella de firma usando la conversión descrita en la documentación del backend.

En Android se necesita API 28 o posterior, un proveedor de credenciales compatible (por ejemplo
Google Password Manager), cuenta de Google y bloqueo de pantalla configurado.

## iOS

iOS requiere Associated Domains (`webcredentials:<RP_ID>`) y que el RP sirva el archivo Apple App
Site Association con el App ID correcto. También se debe configurar el entitlement de Associated
Domains en Xcode. La app reporta el origen HTTPS del RP.

Los archivos de asociación y las huellas de firma dependen de la identidad real de la aplicación;
no pueden completarse con valores inventados. Para depurar en build debug, el plugin activa sus
diagnósticos de RP ID y asociación de plataforma.
