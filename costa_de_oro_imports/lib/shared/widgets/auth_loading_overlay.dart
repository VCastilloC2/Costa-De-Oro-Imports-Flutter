import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';
import 'animated_brand_lockup.dart';
import 'liquor_pour_loader.dart';

/// ============================================================================
/// ESTADO DE LA CARGA
/// ============================================================================
/// Clase que gestiona el estado (progreso y finalización) de la pantalla de
/// carga. Usa [ChangeNotifier] para que la interfaz se actualice en tiempo real
/// sin necesidad de usar `setState` manual.
class _LoadingState extends ChangeNotifier {
  double progress = 0.0;
  bool done = false;

  /// Actualiza el progreso (de 0.0 a 1.0) y notifica a los escuchas.
  void setProgress(double value) {
    progress = value;
    notifyListeners();
  }

  /// Marca la carga como completada y fuerza el progreso al 100%.
  void complete() {
    progress = 1;
    done = true;
    notifyListeners();
  }
}

/// ============================================================================
/// FUNCIÓN PRINCIPAL: MOSTRAR OVERLAY
/// ============================================================================
/// Muestra una pantalla de carga superpuesta (Overlay) mientras se ejecuta una
/// tarea asíncrona, como una petición HTTP de login.
///
/// **Flujo de trabajo:**
/// 1. Muestra el diálogo modal con la animación.
/// 2. Inicia un temporizador que simula el progreso visual (se detiene en 88%).
/// 3. Ejecuta la [task] (ej. petición al backend).
/// 4. Si la tarea es exitosa, llena la animación al 100% y cierra el diálogo.
/// 5. Si falla, cierra el diálogo y lanza el error para que sea capturado.
Future<T?> showAuthLoading<T>(
  BuildContext context, {
  required Future<T> Function() task,
  String loadingText = 'Iniciando sesión',
  String loadingHint = 'Preparando tu selección de licores',
  String successText = '¡Bienvenido!',
  String successHint = 'Todo listo',
  Duration minDuration = const Duration(milliseconds: 1800),
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final state = _LoadingState();

  // 1. Mostramos el diálogo con efecto Fade (aparición suave)
  unawaited(
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false, // El usuario no puede cerrarlo tocando fuera
      barrierColor:
          Colors.transparent, // Fondo transparente (usamos nuestro propio blur)
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => PopScope(
        canPop: false, // Bloquea el botón "Atrás" de Android para evitar cancelaciones
        child: _AuthLoadingView(
          state: state,
          loadingText: loadingText,
          loadingHint: loadingHint,
          successText: successText,
          successHint: successHint,
        ),
      ),
      transitionBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );

  // 2. Simulamos un progreso de carga visual que llega hasta el 88%.
  // Esto da feedback al usuario mientras el servidor responde.
  final timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
    state.setProgress(state.progress + (0.88 - state.progress) * 0.05);
  });

  // 3. Definimos un tiempo mínimo de visualización para que la animación se aprecie
  final minTime = Future<void>.delayed(minDuration);

  // 4. Ejecutamos la tarea real (ej. login en Spring Boot) y manejamos errores
  T? result;
  Object? error;
  StackTrace? stack;
  try {
    result = await task();
  } catch (e, st) {
    error = e;
    stack = st;
  }

  // 5. Gestión del cierre del diálogo
  if (error == null) await minTime; // Espera a que se cumpla el tiempo mínimo
  timer.cancel(); // Detiene el progreso simulado

  if (error != null) {
    navigator.pop(); // Cierra el diálogo si hubo error
    Error.throwWithStackTrace(error, stack!); // Propaga el error hacia arriba
  }

  // 6. Todo salió bien: Completamos el llenado, vibramos y esperamos un momento
  state.complete();
  HapticFeedback.mediumImpact(); // Feedback táctil de éxito
  await Future<void>.delayed(const Duration(milliseconds: 1100));

  navigator.pop(); // Cierra el diálogo
  return result;
}

/// ============================================================================
/// VISTA GRÁFICA DEL OVERLAY
/// ============================================================================
/// Widget sin estado (StatelessWidget) que dibuja la interfaz de carga.
/// Está dividido en capas: Fondo desenfocado, Resplandor, Logo, Animación y Textos.
class _AuthLoadingView extends StatelessWidget {
  const _AuthLoadingView({
    required this.state,
    required this.loadingText,
    required this.loadingHint,
    required this.successText,
    required this.successHint,
  });

  final _LoadingState state;
  final String loadingText;
  final String loadingHint;
  final String successText;
  final String successHint;

  @override
  Widget build(BuildContext context) {
    // Factor de escala para diseño responsivo (Basado en el ancho de Figma 390px)
    final s = MediaQuery.sizeOf(context).width / 390;

    return Material(
      type: MaterialType.transparency, // Permite ver el fondo desenfocado
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final done = state.done; // Bandera para saber si ya terminó

          return Stack(
            fit: StackFit.expand,
            children: [
              // -----------------------------------------------------------------
              // CAPA 1: Fondo desenfocado (Glassmorphism)
              // -----------------------------------------------------------------
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    // Oscurecemos un poco el login del fondo para dar contraste
                    color: const Color(0xFF14100C).withValues(alpha: 0.6),
                  ),
                ),
              ),

              // -----------------------------------------------------------------
              // CAPA 2: Resplandor dorado radial de fondo
              // -----------------------------------------------------------------
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(
                      0,
                      -0.4,
                    ), // Centrado ligeramente arriba
                    radius: 0.9,
                    colors: [
                      // Brilla más cuando ya se completó el inicio de sesión
                      AppColors.gold.withValues(alpha: done ? 0.35 : 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // -----------------------------------------------------------------
              // CAPA 3: Contenido (Logo, Animación, Textos)
              // -----------------------------------------------------------------
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 20 * s),

                    // 3.1 LOGO DE LA MARCA
                    // Usamos nuestro widget animado pero con la animación estática
                    AnimatedBrandLockup(
                      logoWidth:
                          160 * s, // Tamaño imponente en la parte superior
                      startFormed: true, // No repetir la animación de entrada
                      play: false,
                      showText: true, // Mostramos "Costa de Oro IMPORTS"
                      textScale: 0.9, // Ajuste fino del texto interno
                    ),

                    const Spacer(), // Empuja la animación hacia el centro
                    // 3.2 ANIMACIÓN DE LA BOTELLA Y EL VASO
                    LiquorPourLoader(progress: state.progress, width: 280 * s),

                    SizedBox(height: 24 * s),

                    // 3.3 TEXTOS DE ESTADO (Iniciando sesión / ¡Bienvenido!)
                    Semantics(
                      liveRegion: true, // Accesibilidad: Anuncia cambios a lectores de pantalla
                      child: AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: 350,
                        ), // Transición suave
                        child: Column(
                          key: ValueKey(
                            done,
                          ), // Fuerza el cambio de widget al cambiar de estado
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icono de check que aparece solo al terminar
                                if (done) ...[
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.goldLight,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  done ? successText : loadingText,
                                  style: AppFonts.style(
                                    size: 30 * s,
                                    weight: FontWeight.w700,
                                    color: AppColors.creamText,
                                    letterSpacing: -0.5, // Tipografía Geist apretada para lucir premium
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12 * s),
                            Text(
                              done ? successHint : loadingHint,
                              style: AppFonts.style(
                                size: 16 * s,
                                weight: FontWeight.w500,
                                color: AppColors.creamText.withValues(
                                  alpha: 0.8,
                                ),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(
                      flex: 2,
                    ), // Deja un espacio extra abajo para balancear
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
