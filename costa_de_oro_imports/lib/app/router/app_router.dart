// RAMA: feature/Auth (o chore/Core)
// ============================================================================
// ROUTER: appRouterProvider
// ============================================================================
// Configuración del enrutador principal.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/welcome/presentation/welcome_page.dart';
import '../../shared/widgets/error_state_widget.dart';
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
import '../../features/profile/presentation/pages/account_details_page.dart';
import '../../features/profile/presentation/pages/passkeys_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) {
    refreshNotifier.value++;
  });
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/welcome',
    debugLogDiagnostics: kDebugMode,
    // Ruta inexistente (por ejemplo, un enlace viejo): pantalla amable con
    // salida, en lugar de la pantalla roja de error de GoRouter.
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: ErrorStateWidget(
          icon: Icons.explore_off_outlined,
          message: 'No encontramos esta pantalla.',
          actionLabel: 'Volver al inicio',
          actionIcon: Icons.home_outlined,
          onAction: () => context.go('/welcome'),
        ),
      ),
    ),
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

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

      if (auth.status == AuthStatus.unknown) {
        return isPublic ? null : '/welcome';
      }

      // Si NO está autenticado, lo mandamos al login si intenta entrar a una ruta privada
      if (!auth.isAuthenticated) {
        return isPublic ? null : '/login';
      }

      // ELIMINAMOS la redirección automática de login -> dashboard
      // para evitar el choque con la animación de carga.

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/welcome'),
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: WelcomePage()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(path: '/terms', builder: (context, state) => const TermsPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/verify-code',
        builder: (context, state) => const VerifyCodePage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const UserProfilePage(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/account-details',
        builder: (context, state) => const AccountDetailsPage(),
      ),
      GoRoute(
        path: '/passkeys',
        builder: (context, state) => const PasskeysPage(),
      ),
    ],
  );
});
