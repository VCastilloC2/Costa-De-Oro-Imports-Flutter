import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- IMPORTS DE TUS PANTALLAS ---
import '../../features/splash/presentation/splash_page.dart';
import '../../features/welcome/presentation/welcome_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart'; // <-- NUEVO
import '../../features/auth/presentation/pages/terms_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    
    // Ya no es un Placeholder, ahora es tu pantalla real
    GoRoute(path: '/register', builder: (context, state) => const RegisterPage()), 
    
    // NUEVA RUTA para los términos y condiciones
    GoRoute(path: '/terms', builder: (context, state) => const TermsPage()),
  ],
  
  // Opcional: para que te avise en consola si intentas ir a una ruta que no existe
  debugLogDiagnostics: true,
);

// Ya no necesitas la clase _Placeholder, así que puedes borrarla