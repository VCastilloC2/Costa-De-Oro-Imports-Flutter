import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/router/app_router.dart';
import 'core/network/api_client.dart';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Si la API responde 401 a una petición autenticada, la sesión ya se borró:
  // se vuelve al login.
  ApiClient.onUnauthorized = () => appRouter.go('/login');
  runApp(const ProviderScope(child: App()));
}
