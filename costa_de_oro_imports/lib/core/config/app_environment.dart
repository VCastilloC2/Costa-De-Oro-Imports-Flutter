import 'package:flutter/services.dart';

/// Runtime configuration loaded from the root `.env` asset before the app starts.
/// Values bundled with a Flutter app are configuration, not server-side secrets.
class AppEnvironment {
  AppEnvironment._();

  static Map<String, String> _values = const {};

  static Future<void> load() async {
    final contents = await rootBundle.loadString('.env');
    final values = <String, String>{};
    for (final rawLine in contents.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final separator = line.indexOf('=');
      if (separator <= 0) continue;

      final key = line.substring(0, separator).trim();
      var value = line.substring(separator + 1).trim();
      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      }
      values[key] = value;
    }
    _values = values;
  }

  static String get(String key, {String fallback = ''}) {
    final value = _values[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }
}