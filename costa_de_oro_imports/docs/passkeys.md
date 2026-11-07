# Passkeys (WebAuthn / FIDO2)

Inicio de sesión sin contraseña con **Face ID / Touch ID** (iCloud Keychain) en iPhone y **huella / bloqueo de pantalla** (Credential Manager, Google Password Manager) en Android.

El login con correo y contraseña, Google y Apple **sigue igual**. Las passkeys son una opción más.

```
Registro                                        Inicio de sesión
────────                                        ────────────────
App ──POST /auth/passkey/register/options──►    App ──POST /auth/passkey/login/options──►
    ◄── {challenge_id, options} ────────────        ◄── {challenge_id, options} ─────────
PasskeyService: valida rpId y challenge,        PasskeyService: valida rpId y challenge,
  fuerza UV=required y residentKey=required       fuerza UV=required
SO: Face ID / huella → crea par de claves       SO: Face ID / huella → firma el challenge
App ──POST /auth/passkey/register/verify──►     App ──POST /auth/passkey/login/verify──►
Backend: verifica atestación y guarda           Backend: verifica firma, origen, rpIdHash,
  credential_id + clave pública + contador        UV, contador → emite JWT (igual que /auth/login)
```

La clave privada nunca sale del Secure Enclave (iOS) ni del Keystore / proveedor de passkeys (Android). El backend solo guarda la **clave pública**.

| Archivo | Responsabilidad |
| --- | --- |
| `lib/core/config/passkey_config.dart` | `PASSKEY_RP_ID` (dominio). Vacío = función apagada |
| `lib/features/auth/data/passkey_service.dart` | Ceremonias nativas, validación de opciones (`PasskeyOptionsGuard`), errores (`PasskeyException`) |
| `lib/features/auth/data/auth_repository.dart` | `PasskeyEndpoints`, `loginWithPasskey`, `registerPasskey`, `listPasskeys`, `revokePasskey`, `validateSession` |
| `lib/features/auth/data/models/passkey_credential.dart` | Modelo de una passkey de la cuenta |
| `lib/features/profile/presentation/pages/passkeys_page.dart` | Pantalla "Passkeys y biometría": listar, agregar y revocar |
| `lib/features/auth/presentation/providers/auth_controller.dart` | `loginWithPasskey`, `registerPasskey`, `passkeyAvailableProvider` |
| `lib/features/auth/presentation/widgets/passkey_widgets.dart` | Botón del login y hoja "Activar Face ID / huella" |
| `lib/core/storage/session_storage.dart` | Marca "este dispositivo tiene passkey" (almacenamiento seguro) |
| `test/passkey_test.dart` | Pruebas del flujo completo con backend y autenticador falsos |

---

## 1. Comportamiento en la app

| Momento | Qué pasa |
| --- | --- |
| Crear cuenta | Tras el registro se ofrece "Entra más rápido con Face ID / huella". Es opcional |
| Login con contraseña / Google / Apple | Si el dispositivo no tiene passkey, se ofrece activarla **una vez**. "Ahora no" no vuelve a preguntar |
| Abrir el login | Si este dispositivo ya usó una passkey, se lanza Face ID / huella automáticamente. Si se cancela o falla, no se muestra error: queda el login normal |
| Botón "Ingresar con Face ID / Touch ID" (iOS) o "con tu huella" (Android) | Login manual. También permite passkeys de otro dispositivo (código QR) |
| Perfil → Passkeys y biometría | Ver, agregar y revocar passkeys en cualquier momento |
| Cerrar sesión | Borra el token. La marca de passkey se conserva para el siguiente login |

Si `PASSKEY_RP_ID` está vacío o el dispositivo no es compatible (iOS < 16, Android < 9, sin bloqueo de pantalla, sin Google Play Services), **no se muestra nada nuevo**.

---

## 2. Configuración

### 2.1 Dominio (Relying Party)

Las passkeys necesitan un dominio propio con **HTTPS**. No funcionan con `http://192.168.x.x`.

```json
// config/dev.json
{ "PASSKEY_RP_ID": "costadeoroimports.com" }
```

```bash
flutter run --dart-define-from-file=config/dev.json
```

El valor debe ser el mismo en:
- `rp.id` / `rpId` de las opciones que genera el backend.
- `webcredentials:` en Associated Domains (iOS).
- El dominio que publica `/.well-known/assetlinks.json` (Android).

### 2.2 iOS (Face ID / Touch ID / iCloud Keychain)

Requiere iOS 16+ en el dispositivo y una cuenta de pago del Apple Developer Program. El proyecto ya compila con iOS 15: en iOS 15 la opción simplemente no aparece.

1. Abre `ios/Runner.xcworkspace` → target **Runner** → **Signing & Capabilities** → **+ Capability → Associated Domains**.
2. Agrega `webcredentials:costadeoroimports.com`.
   - Para probar sin CDN de Apple, usa `webcredentials:costadeoroimports.com?mode=developer` y activa *Ajustes → Desarrollador → Associated Domains Development* en el iPhone.
3. Haz commit de `ios/Runner/Runner.entitlements`.
4. Publica en el servidor `https://costadeoroimports.com/.well-known/apple-app-site-association` (sin extensión, `Content-Type: application/json`, sin redirecciones):

```json
{
  "webcredentials": {
    "apps": ["TEAMID.com.example.costaDeOroImports"]
  }
}
```

> No se agregó el entitlement al `project.pbxproj` automáticamente: los equipos *Personal Team* (gratuitos) no admiten Associated Domains y la compilación fallaría para todos.

### 2.3 Android (huella / Credential Manager / Google Password Manager)

Requiere Android 9+ (API 28) con Google Play Services. `minSdk` no cambia.

1. Obtén el SHA-256 de cada certificado de firma (debug, release y Play App Signing):

```bash
cd android && ./gradlew signingReport
```

2. Publica `https://costadeoroimports.com/.well-known/assetlinks.json`:

```json
[
  {
    "relation": [
      "delegate_permission/common.handle_all_urls",
      "delegate_permission/common.get_login_creds"
    ],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.costa_de_oro_imports",
      "sha256_cert_fingerprints": ["AA:BB:CC:...:FF"]
    }
  }
]
```

3. En Android el `origin` del `clientDataJSON` **no** es `https://…`, sino `android:apk-key-hash:<sha256 del certificado en base64url sin relleno>`. El backend debe aceptarlo (ver `EXPECTED_ORIGINS` abajo). Para calcularlo:

```bash
python -c "import base64,sys;print('android:apk-key-hash:'+base64.urlsafe_b64encode(bytes.fromhex(sys.argv[1].replace(':',''))).decode().rstrip('='))" AA:BB:CC:...:FF
```

> Antes de publicar, cambia `applicationId` / Bundle ID de `com.example…` y actualiza estos dos archivos.

---

## 3. Contrato de API (backend FastAPI)

Implementado en el backend `Costa-De-Oro-Imports-Python` (`app/api/v1/endpoints/passkey.py`; contrato
completo con ejemplos en su `docs/PASSKEYS.md`). La app usa las rutas de [PasskeyEndpoints] en
`auth_repository.dart`. El backend también acepta las rutas antiguas `/auth/passkey/*/options|verify`
como alias.

| Endpoint | Token | Cuerpo | Respuesta |
| --- | --- | --- | --- |
| `POST /api/v1/auth/passkey/register/start` | Sí | `{"device_name": "iOS"}` | `{"challenge_id", "options": PublicKeyCredentialCreationOptionsJSON, "expires_in"}` |
| `POST /api/v1/auth/passkey/register/finish` | Sí | `{"challenge_id", "credential": RegistrationResponseJSON, "device_name"}` | `200 {"success", "message", "passkey"}` · `409` ya registrada (la app lo trata como éxito) |
| `POST /api/v1/auth/passkey/login/start` | No | `{}` | `{"challenge_id", "options": PublicKeyCredentialRequestOptionsJSON, "expires_in"}` |
| `POST /api/v1/auth/passkey/login/finish` | No | `{"challenge_id", "credential": AuthenticationResponseJSON}` | **Igual que `/auth/login`**: `{"accessToken", "token_type", "expires_in", "auth_method": "passkey", "usuario"}` |
| `GET /api/v1/auth/passkey/credentials` | Sí | — | `[{"passkey_id", "credential_id", "device_name", "device_type", "backed_up", "created_at", "last_used_at"}]` |
| `DELETE /api/v1/auth/passkey/credentials/{passkey_id}` | Sí | — | `200 {"success", "message", "passkey_id"}` · `404` |
| `GET /api/v1/auth/session/validate` | Sí | — | `200 {"valid", "usuario_id", "rol", "auth_method", "expires_in"}` · `401` · `503` |

- Errores: `{"detail": "mensaje"}`, como en el resto de la API. Un `401`/`404` en `login/finish` hace que la app deje de lanzar Face ID automáticamente.
- `login/start` no recibe correo: las passkeys son **descubribles**, así el endpoint no revela qué cuentas existen.
- Los challenges duran 5 minutos y son de un solo uso (Valkey, con MySQL como respaldo).
- `restoreSession` llama primero a `session/validate`: con `401` borra el token sin pedir `/perfil`; con `503`, sin conexión o con un backend sin el endpoint sigue con `/perfil` como antes.

### Gestión en la app (Perfil → Passkeys y biometría)

`PasskeysPage` (`/passkeys`) lista las passkeys de la cuenta, marca la de **este dispositivo**
(su ID se guarda al registrar o iniciar sesión, en `SessionStorage`), permite agregar una nueva y
revocar cualquiera con confirmación. Si se revoca la de este dispositivo, la app deja de lanzar
Face ID / huella automáticamente.

---

## 4. Backend FastAPI

El backend ya está implementado. Para activarlo (ver `docs/PASSKEYS.md` del backend):

```bash
pip install -r requirements.txt
mysql -u <usuario> -p db_beer < app/sql/passkeys.sql
```

```env
PASSKEY_RP_ID=costadeoroimports.com          # igual que PASSKEY_RP_ID de esta app
PASSKEY_EXPECTED_ORIGINS=https://costadeoroimports.com,android:apk-key-hash:XXXXXXXX
VALKEY_URL=rediss://...
```

Si `PASSKEY_RP_ID` está vacío en el backend, los endpoints responden `503` y la app muestra el mensaje de error.

---

## 5. Cómo probar

| Caso | Pasos | Resultado esperado |
| --- | --- | --- |
| Función apagada | Compilar sin `PASSKEY_RP_ID` | Login, registro y perfil idénticos a antes |
| Dispositivo no compatible | iOS 15 / Android 8 / sin bloqueo de pantalla | No aparece el botón ni la oferta |
| Registro + passkey | Crear cuenta → "Activar" → Face ID / huella | `register/options` + `register/verify`; va al panel |
| Rechazar la oferta | "Ahora no" tras login con contraseña | Va al panel; no vuelve a ofrecerse tras logins |
| Login automático | Cerrar sesión → abrir login | Face ID / huella aparece solo; al aceptar entra al panel |
| Cancelar Face ID automático | Cerrar la hoja del sistema | Sin mensaje; login con contraseña disponible |
| Botón manual | Tocar "Ingresar con…" y cancelar | "Inicio de sesión cancelado." |
| Passkey de otro dispositivo | Botón manual → "Usar otro dispositivo" / QR | Entra con la passkey del otro teléfono |
| Passkey borrada en el servidor | Borrar la fila y entrar con passkey | Muestra el `detail` del 401; deja de lanzarse sola |
| Passkey borrada del teléfono | Borrarla en Ajustes → Contraseñas / Google Password Manager | El auto-login no muestra nada y deja de intentarlo |
| Dominio mal configurado | AASA / assetlinks ausente | Mensaje "Las passkeys no están configuradas para este dominio." |
| Replay | Reenviar el mismo `login/finish` | `401`: el challenge ya se consumió |
| Ver passkeys | Perfil → Passkeys y biometría | Lista con "Este dispositivo" marcado |
| Revocar la de este dispositivo | Eliminar → confirmar | Desaparece; el login ya no lanza Face ID solo |
| Sesión cerrada en el servidor | Borrar la sesión en Valkey y reabrir la app | Vuelve al login sin pedir `/perfil` |
| Login tradicional | Correo + contraseña, Google, Apple | Sin cambios |

```bash
flutter test test/passkey_test.dart
```
