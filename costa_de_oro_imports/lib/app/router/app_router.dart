import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// --- IMPORTS DE PANTALLAS ---
import '../../features/welcome/presentation/welcome_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/terms_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/verify_code_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/profile/presentation/pages/user_profile_page.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';

/// Router global con protección de rutas.
///
/// Se expone como `Provider<GoRouter>` para poder leer el estado de
/// autenticación desde el `redirect` (que es síncrono y no puede hacer await).
/// Cuando `authControllerProvider` cambia, `refreshListenable` fuerza
/// al router a reevaluar el `redirect`.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Notifier que dispara la reevaluación del redirect.
  final refreshNotifier = ValueNotifier<int>(0);
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

      // Rutas que NO requieren sesión.
      const publicRoutes = {
        '/welcome',
        '/login',
        '/register',
        '/terms',
        '/forgot-password',
        '/verify-code',
        '/reset-password',
      };
      final isPublic = publicRoutes.contains(loc);

      // 1. Restaurando sesión: solo permitir rutas públicas.
      if (auth.status == AuthStatus.unknown) {
        return isPublic ? null : '/welcome';
      }

      // 2. Sin sesión: si intenta una ruta protegida, al login.
      if (!auth.isAuthenticated) {
        return isPublic ? null : '/login';
      }

      // 3. Con sesión: si intenta welcome/login/register, al dashboard.
      if (loc == '/welcome' || loc == '/login' || loc == '/register') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // 1. Ruta raíz (redirige al welcome).
      GoRoute(
        path: '/',
        redirect: (context, state) => '/welcome',
      ),

      // 2. Welcome.
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: WelcomePage(),
        ),
      ),

      // 3. Login.
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginPage(),
        ),
      ),

      // 4. Registro.
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),

      // 5. Términos y Condiciones.
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsPage(),
      ),

      // 6. Forgot Password.
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // 7. Verify Code.
      GoRoute(
        path: '/verify-code',
        builder: (context, state) => const VerifyCodePage(),
      ),

      // 8. Reset Password.
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),

      // 9. DASHBOARD (protegida).
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),

      // 10. User Profile (protegida).
      GoRoute(
        path: '/profile',
        builder: (context, state) => const UserProfilePage(),
      ),
    ],
  );
});