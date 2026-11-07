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
| `lib/features/auth/data/auth_repository.dart` | `loginWithPasskey`, `registerPasskey` y llamadas a `/auth/passkey/*` |
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
| Perfil → Passkey y biometría | Activar la passkey en cualquier momento |
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

## 3. Contrato de API (nuevo, aditivo)

Ningún endpoint existente cambia.

| Endpoint | Token | Cuerpo | Respuesta |
| --- | --- | --- | --- |
| `POST /auth/passkey/register/options` | Sí | `{"device_name": "iOS"}` | `{"challenge_id": "...", "options": PublicKeyCredentialCreationOptionsJSON}` |
| `POST /auth/passkey/register/verify` | Sí | `{"challenge_id", "credential": RegistrationResponseJSON, "device_name"}` | `200` |
| `POST /auth/passkey/login/options` | No | `{}` | `{"challenge_id": "...", "options": PublicKeyCredentialRequestOptionsJSON}` |
| `POST /auth/passkey/login/verify` | No | `{"challenge_id", "credential": AuthenticationResponseJSON}` | **Igual que `/auth/login`**: `{"accessToken", "usuario"}` |

- Flutter también acepta las opciones sin envoltorio (`options_to_json()` de py_webauthn tal cual) o dentro de `publicKey`. Entonces `challenge_id` es opcional y el backend debe ligar el challenge de otra forma (por ejemplo, cookie de sesión).
- Errores: `HTTPException(status_code, detail="mensaje")`, como en el resto de la API. Un `401`/`404` en `login/verify` hace que la app deje de lanzar Face ID automáticamente.
- `login/options` no recibe correo: las passkeys son **descubribles**, así el endpoint no revela qué cuentas existen.

---

## 4. Backend FastAPI (referencia)

```bash
pip install "webauthn>=2.0"
```

```sql
CREATE TABLE passkey_credenciales (
  id              BIGSERIAL PRIMARY KEY,
  usuario_id      BIGINT NOT NULL REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
  credential_id   BYTEA  NOT NULL UNIQUE,
  public_key      BYTEA  NOT NULL,
  sign_count      BIGINT NOT NULL DEFAULT 0,
  transports      JSONB,
  aaguid          TEXT,
  backed_up       BOOLEAN NOT NULL DEFAULT FALSE,   -- passkey sincronizada (iCloud / Google)
  device_name     TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_used_at    TIMESTAMPTZ
);

CREATE TABLE passkey_challenges (
  id          UUID PRIMARY KEY,
  challenge   BYTEA NOT NULL,
  usuario_id  BIGINT,                 -- NULL en login
  tipo        TEXT  NOT NULL,         -- 'registro' | 'login'
  expires_at  TIMESTAMPTZ NOT NULL
);

-- Identificador opaco del usuario para WebAuthn (no usar el ID de la BD ni el correo).
ALTER TABLE usuarios ADD COLUMN webauthn_user_handle BYTEA UNIQUE;
```

```python
# auth_passkeys.py
import secrets, uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from webauthn import (
    generate_authentication_options, generate_registration_options,
    options_to_json, verify_authentication_response, verify_registration_response,
)
from webauthn.helpers import base64url_to_bytes
from webauthn.helpers.exceptions import InvalidAuthenticationResponse, InvalidRegistrationResponse
from webauthn.helpers.structs import (
    AuthenticatorSelectionCriteria, PublicKeyCredentialDescriptor,
    ResidentKeyRequirement, UserVerificationRequirement,
)
import json

RP_ID = "costadeoroimports.com"
RP_NAME = "Costa de Oro Imports"
EXPECTED_ORIGINS = [
    f"https://{RP_ID}",                       # iOS
    "android:apk-key-hash:XXXXXXXXXXXXXXXX",  # Android debug
    "android:apk-key-hash:YYYYYYYYYYYYYYYY",  # Android release / Play
]
CHALLENGE_TTL = timedelta(minutes=2)

router = APIRouter(prefix="/auth/passkey")

class RegisterOptionsIn(BaseModel):
    device_name: str | None = None

class VerifyIn(BaseModel):
    challenge_id: str
    credential: dict
    device_name: str | None = None


def guardar_challenge(db, challenge: bytes, tipo: str, usuario_id=None) -> str:
    cid = str(uuid.uuid4())
    db.insert_challenge(id=cid, challenge=challenge, tipo=tipo, usuario_id=usuario_id,
                        expires_at=datetime.now(timezone.utc) + CHALLENGE_TTL)
    return cid


def consumir_challenge(db, cid: str, tipo: str, usuario_id=None) -> bytes:
    """Un solo uso (DELETE ... RETURNING) + expiración = protección anti-replay."""
    row = db.delete_challenge_returning(id=cid, tipo=tipo)
    if (row is None or row.expires_at < datetime.now(timezone.utc)
            or (usuario_id is not None and row.usuario_id != usuario_id)):
        raise HTTPException(401, "La solicitud de passkey expiró. Intenta de nuevo.")
    return row.challenge


@router.post("/register/options")
def register_options(body: RegisterOptionsIn, usuario=Depends(usuario_actual), db=Depends(get_db)):
    handle = usuario.webauthn_user_handle or db.set_user_handle(usuario.usuario_id, secrets.token_bytes(32))
    opts = generate_registration_options(
        rp_id=RP_ID, rp_name=RP_NAME,
        user_id=handle, user_name=usuario.correo,
        user_display_name=f"{usuario.nombres or ''} {usuario.apellidos or ''}".strip() or usuario.correo,
        exclude_credentials=[PublicKeyCredentialDescriptor(id=c.credential_id)
                             for c in db.credenciales_de(usuario.usuario_id)],
        authenticator_selection=AuthenticatorSelectionCriteria(
            resident_key=ResidentKeyRequirement.REQUIRED,
            user_verification=UserVerificationRequirement.REQUIRED,
        ),
        timeout=120_000,
    )
    cid = guardar_challenge(db, opts.challenge, "registro", usuario.usuario_id)
    return {"challenge_id": cid, "options": json.loads(options_to_json(opts))}


@router.post("/register/verify")
def register_verify(body: VerifyIn, usuario=Depends(usuario_actual), db=Depends(get_db)):
    challenge = consumir_challenge(db, body.challenge_id, "registro", usuario.usuario_id)
    try:
        v = verify_registration_response(
            credential=body.credential, expected_challenge=challenge,
            expected_rp_id=RP_ID, expected_origin=EXPECTED_ORIGINS,
            require_user_verification=True,
        )
    except InvalidRegistrationResponse:
        raise HTTPException(400, "No se pudo verificar la passkey.")
    db.insert_credencial(
        usuario_id=usuario.usuario_id, credential_id=v.credential_id,
        public_key=v.credential_public_key, sign_count=v.sign_count,
        aaguid=v.aaguid, backed_up=v.credential_backed_up,
        transports=body.credential.get("response", {}).get("transports"),
        device_name=(body.device_name or "")[:60],
    )
    auditar("passkey_registrada", usuario.usuario_id)
    return {"ok": True}


@router.post("/login/options")
def login_options(db=Depends(get_db)):          # + rate limit por IP
    opts = generate_authentication_options(
        rp_id=RP_ID, user_verification=UserVerificationRequirement.REQUIRED, timeout=120_000,
    )
    cid = guardar_challenge(db, opts.challenge, "login")
    return {"challenge_id": cid, "options": json.loads(options_to_json(opts))}


@router.post("/login/verify")
def login_verify(body: VerifyIn, db=Depends(get_db)):   # + rate limit por IP
    challenge = consumir_challenge(db, body.challenge_id, "login")
    raw_id = base64url_to_bytes(body.credential.get("rawId", ""))
    cred = db.credencial_por_id(raw_id)
    if cred is None:
        raise HTTPException(401, "Esta passkey ya no es válida. Inicia sesión con tu contraseña.")
    usuario = db.usuario(cred.usuario_id)
    handle = body.credential.get("response", {}).get("userHandle")
    if handle and base64url_to_bytes(handle) != usuario.webauthn_user_handle:
        raise HTTPException(401, "Passkey inválida.")
    if not usuario.is_enabled:
        raise HTTPException(403, "Tu cuenta está deshabilitada.")
    try:
        v = verify_authentication_response(
            credential=body.credential, expected_challenge=challenge,
            expected_rp_id=RP_ID, expected_origin=EXPECTED_ORIGINS,
            credential_public_key=cred.public_key,
            credential_current_sign_count=cred.sign_count,   # contador: detecta clones
            require_user_verification=True,
        )
    except InvalidAuthenticationResponse:
        auditar("passkey_rechazada", cred.usuario_id)
        raise HTTPException(401, "Passkey inválida.")
    db.update_credencial(cred.id, sign_count=v.new_sign_count, last_used_at=datetime.now(timezone.utc))
    auditar("login_passkey", usuario.usuario_id)
    return emitir_sesion(usuario)   # mismo formato que /auth/login
```

### Qué cubre cada control

| Requisito | Dónde |
| --- | --- |
| Challenge firmado / clave pública | `verify_*_response` comprueba la firma con la clave pública guardada |
| Replay | Challenge aleatorio de 32 bytes, **un solo uso**, expira en 2 min, ligado al usuario en el registro; `sign_count` detecta autenticadores clonados (las passkeys sincronizadas reportan 0) |
| Validación de origen | `expected_origin` = `https://RP_ID` + `android:apk-key-hash:…` |
| Validación de dominio | Backend: `expected_rp_id` (rpIdHash). App: `PasskeyOptionsGuard` rechaza opciones de otro dominio antes de mostrar Face ID. SO: AASA / assetlinks |
| Biometría obligatoria | `UserVerificationRequirement.REQUIRED` + `require_user_verification=True`; la app también fuerza `userVerification: required` |
| Device credential validation | Atestación verificada en el registro; `aaguid` y `backed_up` guardados para auditoría/políticas |
| Secure storage | Clave privada en Secure Enclave / Keystore; token en `flutter_secure_storage`; la app no guarda nada secreto de la passkey |
| Enumeración de cuentas | `login/options` sin correo (passkeys descubribles) |

### Recomendaciones de sesión (backend)

La app conserva el manejo de token actual (un JWT en `flutter_secure_storage`; un `401` lo borra). Para endurecer la sesión sin cambiar el contrato:

- Access token corto (15 min) y refresh token rotativo de un solo uso, invalidado al detectar reutilización. La app hoy no llama a un endpoint de refresh: agregarlo es un cambio aparte.
- Incluir en el JWT `amr: ["pop", "user"]` / `auth_method: "passkey"` para auditoría y decisiones de riesgo.
- Rate limit en `/auth/passkey/login/*` y registro de auditoría de altas, bajas y logins.
- Endpoint para listar y revocar passkeys (`GET/DELETE /auth/passkey/credenciales`) — pendiente en la UI.

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
| Replay | Reenviar el mismo `login/verify` | `401`: el challenge ya se consumió |
| Login tradicional | Correo + contraseña, Google, Apple | Sin cambios |

```bash
flutter test test/passkey_test.dart
```
