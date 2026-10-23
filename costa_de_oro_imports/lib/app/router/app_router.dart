import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/welcome/presentation/welcome_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
    // Temporales, hasta que hagamos las pantallas reales
    GoRoute(
      path: '/login',
      builder: (context, state) => const _Placeholder('Iniciar sesión'),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const _Placeholder('Registro'),
    ),
  ],
);

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title (próximamente)')),
    );
  }
}