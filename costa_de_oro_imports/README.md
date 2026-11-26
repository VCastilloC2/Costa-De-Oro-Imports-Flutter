# Costa de Oro Imports — Flutter

Aplicación móvil de Costa de Oro Imports. Usa Flutter, Riverpod y GoRouter; se conecta a la API FastAPI del repositorio `Costa-De-Oro-Imports-Python`.

## Requisitos

- Flutter compatible con Dart `^3.13.4`.
- Un dispositivo Android/iOS o un emulador.
- La API FastAPI disponible en la URL configurada en `.env`.

## Configuración local

Desde la carpeta que contiene este README:

```powershell
Copy-Item .env.example .env
```

Edita `.env` antes de iniciar la app:

| Variable | Uso |
| --- | --- |
| `API_BASE_URL` | URL base de FastAPI, por ejemplo `http://192.168.1.9:8000`. |
| `GOOGLE_SERVER_CLIENT_ID` | ID OAuth de tipo **Web**. Flutter lo usa para pedir el ID token que valida FastAPI. |
| `GOOGLE_IOS_CLIENT_ID` | ID OAuth de tipo **iOS**; también puede venir de `GoogleService-Info.plist`. |
| `APPLE_SERVICE_ID` | ID de Apple para el flujo web de Android. |
| `APPLE_REDIRECT_URI` | Callback HTTPS de Apple configurado en FastAPI. |

Flutter lee `.env` automáticamente al arrancar, antes de crear la app. Después de cambiarlo, detén y vuelve a ejecutar `flutter run` para que los nuevos valores se carguen. El archivo está excluido de Git; `.env.example` sirve como plantilla.

Los valores de `.env` se empaquetan dentro de la aplicación y se pueden extraer del APK/IPA. Úsalo para configuración del cliente, como URL e IDs OAuth. No guardes contraseñas, claves privadas ni secretos de FastAPI allí.

## Firebase

`lib/firebase_options.dart` fue generado por FlutterFire CLI para el proyecto `avid-atrium-515601-v4`. Al iniciar, `lib/main.dart` llama a `Firebase.initializeApp` con la opción correspondiente a Android, iOS, web, macOS o Windows.

Para regenerar la configuración al agregar otra plataforma o producto:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure --project=avid-atrium-515601-v4
flutter pub get
flutter run
```

Los archivos de configuración de Firebase ya están colocados en `android/app/google-services.json` e `ios/Runner/GoogleService-Info.plist`. Gradle procesa el JSON y Xcode incorpora el plist al bundle de iOS.

El ID OAuth de iOS está en `CLIENT_ID` dentro de `GoogleService-Info.plist` y se carga desde `GOOGLE_IOS_CLIENT_ID` en `.env`. `Info.plist` usa el `REVERSED_CLIENT_ID` como URL scheme. Para volver a descargar el archivo iOS:

```powershell
firebase apps:sdkconfig IOS 1:689178422854:ios:696e4fc608ed7b5c53e447 -o ios/Runner/GoogleService-Info.plist
```

El Firebase App ID no reemplaza al OAuth Client ID. Para Android, Firebase debe tener la huella SHA-1 debug/release registrada para `com.example.costa_de_oro_imports`; vuelve a descargar `google-services.json` después de cambiar esa configuración.

### URL de la API

- Emulador Android: usa la dirección del host accesible desde el emulador, normalmente `http://10.0.2.2:8000` para un FastAPI que corre en la misma computadora.
- Teléfono físico: usa la IP local de la computadora que ejecuta FastAPI; ambos equipos deben estar en la misma red.
- Producción: usa la URL HTTPS pública de FastAPI.

## Iniciar FastAPI

En otra terminal, desde `Costa-De-Oro-Imports-Python`:

```powershell
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Configura en el `.env` de FastAPI, como mínimo, la base de datos y `JWT_SECRET_ECOMMERCE`. Para validar Google, `GOOGLE_ALLOWED_CLIENT_IDS` debe incluir los IDs OAuth web, Android e iOS, separados por comas. El ID web debe ser igual a `GOOGLE_SERVER_CLIENT_ID` en Flutter.

## Ejecutar Flutter

```powershell
flutter pub get
flutter run
```

El botón **Google** obtiene un ID token de Google y lo envía a `POST /auth/google`. FastAPI verifica firma, emisor, audiencia y correo verificado; después devuelve el JWT de la app. Para Android, crea también un cliente OAuth Android en Google Cloud con el `applicationId` y la huella SHA-1 correctos para las firmas debug y release.

Más detalles de proveedores sociales: [docs/SOCIAL_LOGIN_SETUP.md](docs/SOCIAL_LOGIN_SETUP.md).

## Recuperación de contraseña

Flutter y FastAPI comparten estas rutas:

1. `POST /auth/password/forgot` con `{"correo":"..."}` envía el código de cinco dígitos.
2. `POST /auth/password/verify` con `{"correo":"...","codigo":"12345"}` valida el código.
3. `POST /auth/password/reset` con `{"correo":"...","codigo":"12345","nueva_contrasena":"..."}` cambia la contraseña.

El servicio de recuperación de FastAPI requiere Valkey y el envío de correo configurados.

## Recursos

- FastAPI: `http://localhost:8000/docs`
- Estado de la API: `http://localhost:8000/health`
- [Documentación oficial de Flutter](https://docs.flutter.dev/)
