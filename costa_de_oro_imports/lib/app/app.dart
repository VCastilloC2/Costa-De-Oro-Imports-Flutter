// RAMA: chore/Core
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_controller.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Widget raiz de la aplicacion.
///
/// Responsabilidades:
///  - Restaurar la sesion del usuario al arrancar (si hay token guardado,
///    entra directo al Dashboard sin pedir credenciales).
///  - Proveer el `GoRouter` reactivo que se actualiza cuando cambia el
///    estado de autenticacion (login, logout, token vencido, etc.).
///  - Limitar el tamano de texto del sistema para que el diseno no se rompa
///    en telefonos con la fuente ampliada.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();

    // Restaurar sesion UNA sola vez al abrir la app.
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Costa de Oro Imports',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      // Respeta la accesibilidad pero con tope: evita desbordes por fuente enorme.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.15,
        child: child!,
      ),
    );
  }
}