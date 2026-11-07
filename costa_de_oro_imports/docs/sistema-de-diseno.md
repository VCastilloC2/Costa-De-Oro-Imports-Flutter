# Sistema de diseño

Reglas para que todas las pantallas se vean y se comporten igual.

## Tokens (`lib/app/theme/`)

| Archivo | Qué contiene | Ejemplo |
| --- | --- | --- |
| `app_colors.dart` | Paleta con nombres por uso | `AppColors.error`, `AppColors.surfaceAlt`, `AppColors.chartPalette` |
| `app_spacing.dart` | Espaciado, radios, sombras, duraciones | `AppSpacing.md`, `AppRadius.card`, `AppShadows.card` |
| `app_fonts.dart` | Fuente única (Geist) y escala tipográfica | `AppTextStyles.title`, `AppTextStyles.bodySmall` |
| `app_theme.dart` | `ThemeData` armado con los tokens | Inputs, botones, snackbars |

Reglas:

- **No escribir `Color(0x...)` en widgets.** Si falta un color, se agrega a `AppColors` con un nombre que diga para qué sirve.
- **Espaciado en múltiplos de 4** con `AppSpacing`.
- **Una sola fuente.** Para cambiarla, se edita solo `AppFonts`.

## Layout adaptable

- **Tamaños en píxeles lógicos fijos.** Ya no se usa `MediaQuery.width / 390`: ese escalado agrandaba todo en pantallas grandes e ignoraba el tamaño de texto que el usuario elige en el sistema.
- **Tablet, web y escritorio:** la app se muestra centrada con ancho de teléfono (`_PhoneFrame` en `app.dart`). Las secciones largas pueden usar `ResponsiveCenter`.
- **Cifras largas:** usan `FittedBox(fit: BoxFit.scaleDown)` para reducirse en lugar de desbordar.
- **Prueba automática:** `test/layout_overflow_test.dart` revisa las pantallas en 320 px y con texto al 130 %. Si una pantalla se desborda, la prueba falla.

## Componentes compartidos (`lib/shared/widgets/`)

| Widget | Uso |
| --- | --- |
| `AppCard` | Tarjeta blanca estándar, con título opcional |
| `IconBadge` | Círculo de color con ícono |
| `EmptySection` | Sección sin datos |
| `ErrorStateWidget` | Error con acción (reintentar u otra) |
| `AppSkeletonizer` | Skeleton de carga |
| `ResponsiveCenter` | Limita el ancho del contenido |

## Estados de una pantalla con datos

Toda pantalla que carga datos debe cubrir:

1. **Cargando:** skeleton con datos de ejemplo (por ejemplo, `DashboardData.skeleton`), para que la pantalla no salte cuando llegan los datos reales.
2. **Error:** `ErrorStateWidget` con "Reintentar". Si reintentar no sirve (por ejemplo, falta de permisos), se ofrece otra salida.
3. **Vacío:** `EmptySection` con un mensaje claro.
4. **Actualizar:** deslizar hacia abajo (`RefreshIndicator`).

## Utilidades (`lib/core/utils/`)

- `Formatters`: dinero en pesos colombianos (`money`, `compactMoney`), números, meses e iniciales.
- `Validators`: correo y contraseña, con los mismos mensajes en todos los formularios.

## Accesibilidad

- **Gráficas:** tienen una descripción `Semantics` con los valores, para lectores de pantalla.
- **Botones solo con ícono:** llevan `Tooltip` o `Semantics(label:)`.
- **Animaciones:** se desactivan si el sistema pide reducir el movimiento (`MediaQuery.disableAnimationsOf`).
