import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/welcome/presentation/welcome_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/terms_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/verify_code_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/profile/presentation/pages/user_profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';

/// ============================================================================
/// PROVIDER: appRouterProvider
/// ============================================================================
/// Construye y mantiene el GoRouter de la aplicación.
/// 
/// **Protección de Rutas:** Usa `redirect` para evaluar si el usuario puede
/// entrar a una pantalla basándose en el [AuthState] de Riverpod.
/// 
/// **Reactividad:** `refreshListenable` escucha los cambios de auth. Si el
/// usuario se loguea o desloguea, el router reevalúa el redirect automáticamente.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Notificador interno para forzar la reevaluación del redirect.
  final refreshNotifier = ValueNotifier<int>(0);
  
  // Escuchamos el estado de autenticación.
  ref.listen(authControllerProvider, (_, __) {
    refreshNotifier.value++;
  });
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/welcome',
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      // Rutas que NO requieren estar logueado.
      const publicRoutes = {
        '/welcome', '/login', '/register', '/terms',
        '/forgot-password', '/verify-code', '/reset-password',
      };
      final isPublic = publicRoutes.contains(loc);

      // 1. Mientras restaura el token (estado unknown), mantener en welcome.
      if (auth.status == AuthStatus.unknown) {
        return isPublic ? null : '/welcome';
      }

      // 2. Si no está autenticado e intenta ir a una ruta privada -> login.
      if (!auth.isAuthenticated) {
        return isPublic ? null : '/login';
      }

      // 3. Si está autenticado e intenta ir a welcome/login/register -> dashboard.
      if (loc == '/welcome' || loc == '/login' || loc == '/register') {
        return '/dashboard';
      }

      // 4. Todo en orden.
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/welcome'),
      GoRoute(path: '/welcome', pageBuilder: (context, state) => const NoTransitionPage(child: WelcomePage())),
      GoRoute(path: '/login', pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage())),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(path: '/terms', builder: (context, state) => const TermsPage()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordPage()),
      GoRoute(path: '/verify-code', builder: (context, state) => const VerifyCodePage()),
      GoRoute(path: '/reset-password', builder: (context, state) => const ResetPasswordPage()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
      GoRoute(path: '/profile', builder: (context, state) => const UserProfilePage()),
      GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfilePage()),
    ],
  );
});