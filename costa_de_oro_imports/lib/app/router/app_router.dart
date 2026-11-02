import 'package:flutter/material.dart';
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

final appRouter = GoRouter(
  initialLocation: '/welcome', // Arranca en el welcome
  debugLogDiagnostics: true,
  routes: [
    // 1. Ruta raíz (Redirige al welcome)
    GoRoute(
      path: '/',
      redirect: (context, state) => '/welcome',
    ),

    // 2. Welcome
    GoRoute(
      path: '/welcome',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: WelcomePage(),
      ),
    ),

    // 3. Login
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: LoginPage(),
      ),
    ),

    // 4. Registro
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    // 5. Términos y Condiciones
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsPage(),
    ),

    // 6. Forgot Password
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),

    // 7. Verify Code
    GoRoute(
      path: '/verify-code',
      builder: (context, state) => const VerifyCodePage(),
    ),

    // 8. Reset Password
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordPage(),
    ),

    // 9. DASHBOARD
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),

    // 10. User Profile
    GoRoute(
      path: '/profile',
      builder: (context, state) => const UserProfilePage(),
    ),
  ],
);