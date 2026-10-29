import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Rutas relativas (suben 4 niveles desde app/router hasta features)
import '../../features/welcome/presentation/welcome_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/terms_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/verify_code_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';

final appRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsPage(),
    ),
    GoRoute(path: '/forgot-password',
    builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(path:  '/verify-code',
    builder: (context, state) => const VerifyCodePage(),
    ),
    GoRoute(path: '/reset-password',
    builder: (context, state) => const ResetPasswordPage(),
    ),
  ],
  debugLogDiagnostics: true,
);