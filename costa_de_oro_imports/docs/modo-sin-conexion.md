# Modo sin conexión

La app se puede **consultar** sin internet: muestra los últimos datos que cargó con conexión y avisa que pueden no estar al día.

## Qué funciona sin conexión

| Funciona | Necesita conexión |
| --- | --- |
| Abrir la app con la sesión iniciada (si ya se cargó el perfil antes) | Iniciar sesión, registrarse, login con Google/Apple |
| Panel: métricas, gráficas, productos más vendidos | Editar perfil y cualquier acción que guarde datos |
| Última predicción de demanda | Generar una predicción nueva |
| Perfil y datos de la cuenta ya vistos | Ver datos que nunca se cargaron con conexión |

Las acciones que guardan datos **no se simulan ni se encolan**: muestran el error "No hay conexión con el servidor". Así el usuario nunca cree que algo se guardó cuando no fue así.

## Cómo funciona

```
Pantalla ──► Dio ──► AuthInterceptor ──► OfflineCacheInterceptor ──► API
                                           │  éxito: guarda la respuesta
                                           │  sin red: responde con la copia
                                           └─► NetworkMonitor ──► OfflineBanner
```

| Archivo | Responsabilidad |
| --- | --- |
| `lib/core/network/offline_cache_interceptor.dart` | Guarda las consultas (GET) y las devuelve sin conexión |
| `lib/core/storage/response_cache.dart` | Copias en el dispositivo (`shared_preferences`), vencen a los 7 días |
| `lib/core/network/network_status.dart` | Une `connectivity_plus` con el resultado real de las peticiones |
| `lib/shared/widgets/offline_banner.dart` | Franja "Sin conexión" en todas las pantallas |

- **Qué se guarda:** solo las consultas `GET`. Un `POST` que en realidad es una consulta puede guardarse con `Options(extra: {OfflineCacheInterceptor.enable: true})`, como la predicción de demanda.
- **Qué nunca se guarda:** las rutas `/auth/*`. Los tokens siguen en `SessionStorage`, que es almacenamiento seguro.
- **Privacidad:** el caché se borra al iniciar y al cerrar sesión, así una cuenta nunca ve datos de otra en el mismo teléfono.
- **Al volver la conexión:** el panel se actualiza solo y la franja desaparece.
- **Detección de conexión:** tener Wi-Fi no garantiza llegar a la API, por eso un fallo real de conexión también activa el modo sin conexión.

## Cómo probarlo

1. Inicia sesión y abre el panel con conexión.
2. Activa el modo avión.
3. Desliza hacia abajo en el panel: aparece la franja "Sin conexión · mostrando los últimos datos guardados" y los datos siguen visibles.
4. Cierra y vuelve a abrir la app: entra directo al panel con los datos guardados.
5. Intenta editar el perfil: aparece un error claro y no se guarda nada.
6. Quita el modo avión: la franja desaparece y el panel se actualiza solo.
