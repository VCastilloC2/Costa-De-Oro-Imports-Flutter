import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_controller.dart';
import 'router/app_router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// Widget raíz de la aplicación.
///
/// Responsabilidades:
///  - Restaurar la sesión del usuario al arrancar (si hay token guardado,
///    entra directo al Dashboard sin pedir credenciales).
///  - Proveer el `GoRouter` reactivo que se actualiza cuando cambia el
///    estado de autenticación (login, logout, token vencido, etc.).
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();

    // Restaurar sesión UNA sola vez al abrir la app.
    // El router reaccionará automáticamente al cambio de estado
    // (redirige a /login si no hay token, o a /dashboard si lo hay).
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    // `watch` (no `read`) para que si el router se reconstruye,
    // MaterialApp.router reciba la nueva instancia.
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Costa de Oro Imports',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) => _PhoneFrame(child: child),
    );
  }
}

/// La app está diseñada para teléfono. En tablet, web o escritorio se centra
/// con un ancho de teléfono en lugar de estirar formularios y tarjetas, y
/// las pantallas reciben ese ancho en `MediaQuery` para calcular su layout.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget? child;

  static const _maxWidth = 600.0;

  @override
  Widget build(BuildContext context) {
    final child = this.child ?? const SizedBox.shrink();
    final media = MediaQuery.of(context);
    if (media.size.width <= _maxWidth) {
      return child;
    }
    return ColoredBox(
      color: AppColors.creamDark,
      child: Center(
        child: SizedBox(
          width: _maxWidth,
          child: MediaQuery(
            data: media.copyWith(size: Size(_maxWidth, media.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}
