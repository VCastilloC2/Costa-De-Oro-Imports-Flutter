// lib/core/config/api_config.dart
import 'app_environment.dart';

class ApiConfig {
  ApiConfig._();

  static final String baseUrl = AppEnvironment.get(
    'API_BASE_URL',
    fallback: 'https://costa-de-oro-imports-python.onrender.com',
  );

  // AUMENTAMOS LOS TIMEOUTS PARA DARLE TIEMPO A RENDER DE DESPERTAR
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  static const String passkeyRpId = 'costa-de-oro-imports-python.onrender.com';
}
