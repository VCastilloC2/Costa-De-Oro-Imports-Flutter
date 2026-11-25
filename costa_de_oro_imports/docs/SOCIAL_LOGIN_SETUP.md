# Configuración de inicio con Google y Apple

Al iniciar, Flutter carga automáticamente el archivo `.env` ubicado junto a
`pubspec.yaml`. La app obtiene un token de identidad del proveedor y lo envía a
FastAPI por `POST /auth/google` o `POST /auth/apple`. FastAPI valida el token y
entrega la sesión propia de la app. No se guardan contraseñas de Google o Apple.

Para configurar este equipo, copia `.env.example` a `.env` y completa los IDs
OAuth. Los IDs de cliente no son secretos; cualquier valor compilado en Flutter
se puede extraer de la aplicación. Guarda claves privadas y contraseñas solo en
las variables de entorno de FastAPI.

## Google

1. Crea clientes OAuth para Android, iOS y Web en Google Cloud. Para Android,
   registra el `applicationId` y las huellas SHA del certificado debug y release.
   Si usas Firebase Authentication, habilita también Google en Firebase Console
   → Authentication → Sign-in method.
2. En FastAPI, incluye el ID web, Android e iOS en
   `GOOGLE_ALLOWED_CLIENT_IDS` (separados por coma). Al menos el ID web tiene
   que coincidir exactamente con `GOOGLE_SERVER_CLIENT_ID` en Flutter.
3. En `.env`, configura el ID del cliente web como audiencia del servidor.
   Descarga el archivo de configuración iOS con:

   ```powershell
   firebase apps:sdkconfig IOS ID_APP_FIREBASE_IOS -o ios/Runner/GoogleService-Info.plist
   ```

   El plist actual está en `ios/Runner/GoogleService-Info.plist`; su campo
   `CLIENT_ID` se guarda como `GOOGLE_IOS_CLIENT_ID` en `.env`. El proyecto usa
   `REVERSED_CLIENT_ID` como esquema URL para regresar a iOS.

   En iOS, registra también el `REVERSED_CLIENT_ID` como URL Scheme de Runner
   Después puedes ejecutar `flutter run` normalmente; no requiere `--dart-define`.

## Apple

1. Habilita **Sign in with Apple** para el App ID de iOS
   `com.example.costaDeOroImports` y usa el entitlement incluido en Runner.
2. Para Android, crea un Service ID en Apple Developer y configura como Return
   URL la ruta pública HTTPS de FastAPI: `https://TU_API/auth/apple/callback`.
3. Añade los audiences permitidos a `APPLE_ALLOWED_CLIENT_IDS`: el bundle ID de
   iOS y el Service ID de Android. Configura también
   `APPLE_ANDROID_PACKAGE_NAME` en FastAPI con el `applicationId` Android.
4. Configura Android con los valores públicos del Service ID y la Return URL
   en `.env`:

   ```dotenv
   APPLE_SERVICE_ID=TU_SERVICE_ID
   APPLE_REDIRECT_URI=https://TU_API/auth/apple/callback
   ```

   Luego inicia la app con `flutter run`.

El callback de Android devuelve el formulario firmado de Apple a la app por el
esquema `signinwithapple`; después la app envía el `identityToken` a FastAPI para
validarlo antes de crear la sesión.
