# Autenticación social (Google y Apple)

Flutter obtiene el token de identidad del proveedor y se lo envía a la API.
**La API FastAPI es la que valida el token** y crea o inicia la sesión del usuario.
Flutter nunca maneja contraseñas de Google ni de Apple.

```
LoginPage ──► SocialAuthService ──► (Google / Apple) ──► id_token
          └─► AuthRepository ──► POST /auth/google | /auth/apple ──► accessToken
                             └─► SessionStorage (flutter_secure_storage)
```

| Archivo | Responsabilidad |
| --- | --- |
| `lib/core/config/api_config.dart` | URL de la API (`API_BASE_URL`) y tiempos de espera |
| `lib/core/config/app_config.dart` | Client IDs de Google (vía `--dart-define`) |
| `lib/core/storage/session_storage.dart` | Token en almacenamiento seguro |
| `lib/core/network/api_client.dart` | Dio, header `Authorization`, manejo de 401 |
| `lib/core/network/api_exception.dart` | Mensajes de error de la API para el usuario |
| `lib/features/auth/data/social_auth_service.dart` | Token de Google / Apple |
| `lib/features/auth/data/auth_repository.dart` | Llamadas a `/auth/*` y guardado de sesión |
| `lib/features/auth/presentation/providers/auth_controller.dart` | Estado de sesión (`loginWithGoogle`, `loginWithApple`) |

---

## 1. Configuración por entorno

Nada está escrito en las páginas. Todo se pasa al compilar:

| Variable | Uso | Valor por defecto |
| --- | --- | --- |
| `API_BASE_URL` | URL de la API | `http://192.168.1.63:8000` (backend en la LAN, ver `api_config.dart`) |
| `GOOGLE_SERVER_CLIENT_ID` | Client ID **Web** de Google (obligatorio en Android) | vacío |
| `GOOGLE_IOS_CLIENT_ID` | Client ID **iOS** de Google | vacío |

### Desarrollo local

1. Copia `config/dev.json.example` como `config/dev.json` (está en `.gitignore`) y llena los valores.
2. Ejecuta:

```bash
flutter run --dart-define-from-file=config/dev.json
```

- **Android Emulator:** `10.0.2.2` es el `localhost` de tu computadora.
- **iOS Simulator:** usa `http://localhost:8000`.
- **Celular físico:** usa la IP de tu PC en la red, por ejemplo `http://192.168.1.50:8000`, y arranca FastAPI con `uvicorn main:app --host 0.0.0.0 --port 8000`.

`http://` está permitido:
- **Android:** en todos los builds (`android:usesCleartextTraffic`), porque el backend local no usa HTTPS. Antes de publicar, pasa la API a `https://` y quita ese atributo.
- **iOS:** solo hacia la red local (`NSAllowsLocalNetworking`).

### Producción (más adelante)

Crea `config/prod.json` con la URL `https://` de producción y compila así:

```bash
flutter build apk --dart-define-from-file=config/prod.json
```

---

## 2. Google Cloud Console

Proyecto: el mismo de Firebase (`costa-de-oro-imports-93a1a`), o cualquier otro.
**No se necesita Firebase Auth**: `google_sign_in` funciona solo con OAuth de Google Cloud.

1. **APIs y servicios → Pantalla de consentimiento de OAuth:** configúrala (tipo *Externo*, nombre de la app, correo de soporte). Mientras esté en modo *Prueba*, agrega tus correos como usuarios de prueba.
2. **Credenciales → Crear ID de cliente OAuth**, tres veces:
   - **Aplicación web** → este es `GOOGLE_SERVER_CLIENT_ID`. También es el `aud` que valida el backend.
   - **Android**:
     - Paquete: `com.example.costa_de_oro_imports`.
     - SHA-1 de **debug**: ejecuta `cd android && ./gradlew signingReport`.
     - Crea **otro** cliente Android con el SHA-1 de tu keystore de **release** (y el de Play App Signing si publicas en Play Store).
   - **iOS**:
     - Bundle ID: `com.example.costaDeOroImports`.
     - Esto da `GOOGLE_IOS_CLIENT_ID` y el *iOS URL scheme*.

> Antes de publicar, cambia el `applicationId` y el Bundle ID de `com.example...` a algo propio (por ejemplo `com.costadeoro.imports`) y crea los clientes OAuth con esos valores.

## 3. Android

- No hay que agregar nada más en Gradle.
- En Android el client ID Web (`GOOGLE_SERVER_CLIENT_ID`) es **obligatorio**: sin él Google no devuelve `idToken`.
- El cliente Android en Google Cloud debe coincidir **exactamente** con el paquete y el SHA-1. Si no coinciden, aparece el error `clientConfigurationError` o *"No fue posible iniciar sesión con Google"*.
- *Sign in with Apple* no está disponible en Android (sin configuración web adicional). Al tocar el botón se muestra un mensaje y la compilación no se ve afectada.

## 4. iOS

1. Copia `ios/Flutter/GoogleSignIn.xcconfig.example` como `ios/Flutter/GoogleSignIn.xcconfig` y pon tu *iOS URL scheme* (el client ID de iOS al revés: `com.googleusercontent.apps.XXXX`). Este valor se usa en `Info.plist`.
2. Pasa `GOOGLE_IOS_CLIENT_ID` y `GOOGLE_SERVER_CLIENT_ID` con `--dart-define-from-file`.
3. Ejecuta `cd ios && pod install`. La versión mínima ya es iOS 15.

## 5. Apple Developer (Sign in with Apple)

Necesitas una cuenta de pago del Apple Developer Program.

1. **Certificates, Identifiers & Profiles → Identifiers:**
   - Abre o crea el App ID con el Bundle ID de la app.
   - Activa **Sign in with Apple**.
2. **En Xcode:** abre `ios/Runner.xcworkspace`, selecciona el target *Runner* y ve a **Signing & Capabilities**:
   - Elige tu *Team*.
   - Agrega **+ Capability → Sign in with Apple**. Esto crea `Runner.entitlements`; haz commit de ese archivo.
3. **Pruebas:** necesitas un iPhone real o un simulador con sesión de Apple ID iniciada (iOS 13+).
   - Apple solo envía el nombre y el correo **la primera vez**. Para repetir la prueba como usuario nuevo, entra en *Ajustes → Apple ID → Iniciar sesión con Apple → la app → Dejar de usar*.

---

## 6. Contrato de API

Flutter ya llamaba a estos endpoints con este formato. Se conservó el contrato existente.

### `POST /auth/login` (ya existente, sin cambios)

```json
{ "correo": "user@mail.com", "password": "..." }
```

### `POST /auth/google`

Autorización: no requerida.

```json
{ "id_token": "<ID token de Google>" }
```

### `POST /auth/apple`

Autorización: no requerida.

```json
{ "id_token": "<identity token de Apple>", "nombres": "Ana", "apellidos": "Pérez" }
```

`nombres` y `apellidos` son opcionales: Apple solo los entrega en la primera autorización.

### Respuesta esperada (igual que `/auth/login`)

```json
{
  "accessToken": "<JWT de la API>",
  "refreshToken": "<opcional>",
  "usuario": { "correo": "...", "rol": "ADMIN" }
}
```

- El token es obligatorio. Se acepta `access_token`, `accessToken`, `token`, `jwt` o `id_token`, también dentro de `data`.
- `usuario` es opcional: si no viene, Flutter pide el perfil a `GET /perfil`.
- Para los errores, usa `HTTPException(status_code=..., detail="mensaje para el usuario")`. Flutter muestra `detail` en las respuestas 4xx.
- Una respuesta **401** en una petición con token borra el token guardado.

---

## 7. Backend FastAPI (lo que hay que implementar)

Dependencias: `pip install google-auth "pyjwt[crypto]" requests`

```python
# auth_social.py
import jwt
from fastapi import APIRouter, HTTPException
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from pydantic import BaseModel

GOOGLE_CLIENT_IDS = [  # client ID Web (el que usa Android) + client ID iOS
    "WEB_CLIENT_ID.apps.googleusercontent.com",
    "IOS_CLIENT_ID.apps.googleusercontent.com",
]
APPLE_BUNDLE_ID = "com.example.costaDeOroImports"
apple_jwks = jwt.PyJWKClient("https://appleid.apple.com/auth/keys")

router = APIRouter(prefix="/auth")

class SocialLogin(BaseModel):
    id_token: str
    nombres: str | None = None
    apellidos: str | None = None

@router.post("/google")
def login_google(body: SocialLogin):
    try:
        info = google_id_token.verify_oauth2_token(
            body.id_token, google_requests.Request(), audience=None
        )
    except ValueError:
        raise HTTPException(401, "El token de Google no es válido.")
    if info.get("aud") not in GOOGLE_CLIENT_IDS or not info.get("email_verified"):
        raise HTTPException(401, "El token de Google no es válido.")
    usuario = buscar_o_crear_usuario(  # tu lógica actual de usuarios
        correo=info["email"], proveedor="google", proveedor_id=info["sub"],
        nombres=info.get("given_name"), apellidos=info.get("family_name"),
    )
    return emitir_sesion(usuario)  # mismo formato que /auth/login

@router.post("/apple")
def login_apple(body: SocialLogin):
    try:
        key = apple_jwks.get_signing_key_from_jwt(body.id_token).key
        info = jwt.decode(
            body.id_token, key, algorithms=["RS256"],
            audience=APPLE_BUNDLE_ID, issuer="https://appleid.apple.com",
        )
    except jwt.PyJWTError:
        raise HTTPException(401, "El token de Apple no es válido.")
    usuario = buscar_o_crear_usuario(
        correo=info.get("email"), proveedor="apple", proveedor_id=info["sub"],
        nombres=body.nombres, apellidos=body.apellidos,
    )
    return emitir_sesion(usuario)
```

Notas:

- **Identifica al usuario por `sub` (ID del proveedor), no solo por correo.** Apple puede entregar un correo de relay (`@privaterelay.appleid.com`) y solo en el primer login.
- Un usuario creado así no tiene contraseña. Guarda `proveedor` + `proveedor_id` y deja `password` en `NULL`.
- Asigna el rol por defecto que corresponda (por ejemplo `CLIENTE`). El panel solo deja entrar a `ADMIN`.
- Si un correo ya existe con contraseña, decide si vinculas la cuenta. Recomendado: vincular solo si `email_verified` es verdadero.

---

## 8. Cómo probar

| Caso | Pasos | Resultado esperado |
| --- | --- | --- |
| Login tradicional | Correo + contraseña válidos | Va a `/home` |
| Google | Tocar *Google*, elegir cuenta | `POST /auth/google` → `/home` |
| Apple | En iPhone, tocar *Apple* | `POST /auth/apple` → `/home` |
| Usuario nuevo | Cuenta de Google/Apple que no exista en la BD | El backend la crea y responde `accessToken` |
| Usuario existente | Repetir con la misma cuenta | Inicia sesión, no la duplica (mismo `sub`) |
| Cancelación | Cerrar el selector de Google / la hoja de Apple | Mensaje "Inicio de sesión cancelado.", sin error |
| Token inválido | Hacer que la API responda 401 (por ejemplo, client ID distinto) | Se muestra el `detail` de la API; no navega |
| API apagada | Detener uvicorn y tocar un botón | "No fue posible conectar con el servidor…" |
| Sesión vencida | Cambiar el token guardado o hacer que expire | La siguiente petición da 401 y se vuelve al login |
| Cerrar sesión | Menú → Cerrar sesión | Se borran los tokens y la cuenta de Google; en el siguiente login Google vuelve a pedir la cuenta |
