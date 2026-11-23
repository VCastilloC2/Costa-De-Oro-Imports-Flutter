// RAMA: feature/Auth
// ============================================================================
// SERVICIO: BiometricPrefs
// ============================================================================
// Guarda de forma persistente (en el almacenamiento del teléfono) las
// decisiones del usuario sobre el inicio de sesión con huella:
//   - Si ya la activó en este dispositivo.
//   - Con qué correo quedó vinculada (para no pedirlo en el login).
//   - Si dijo "Ahora no" (se vuelve a preguntar pasados unos días).
//   - Si dijo "No volver a preguntar".
//   - Si la huella falló con 401 (se deja de lanzar sola al abrir el login).
// El secreto del dispositivo NO se guarda aquí: vive en SessionStorage.
// ============================================================================

import 'package:shared_preferences/shared_preferences.dart';

/// Días que se espera tras "Ahora no" antes de volver a invitar.
/// En 0 (periodo de pruebas) la invitación sale en cada inicio de sesión.
/// Antes de entregar, cambiar a 7 (o los días que se prefieran).
const int kBiometricSnoozeDays = 0;

class BiometricPrefs {
  BiometricPrefs._();

  static final BiometricPrefs instance = BiometricPrefs._();

  bool _enabled = false;
  bool _neverAsk = false;
  bool _autoSuppressed = false;
  DateTime? _snoozedUntil;
  String? _email; // correo vinculado a la huella de este teléfono
  String? _lastLoginEmail; // último correo con el que se inició sesión

  /// El usuario ya activó la huella en este dispositivo.
  bool get hasPasskey => _enabled;

  /// Correo vinculado a la huella (null si aún no se conoce).
  String? get email => _email;

  /// Se debe mostrar la invitación para activar la huella.
  bool get shouldOffer {
    if (_enabled || _neverAsk) return false;
    final until = _snoozedUntil;
    return until == null || DateTime.now().isAfter(until);
  }

  /// Se debe lanzar el lector de huella solo al abrir el login.
  bool get shouldAutoPrompt => _enabled && !_autoSuppressed;

  /// Carga los datos desde la memoria del teléfono. Se debe llamar al iniciar la app.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('bio_enabled') ?? false;
    _neverAsk = prefs.getBool('bio_never_ask') ?? false;
    _autoSuppressed = prefs.getBool('bio_auto_suppressed') ?? false;
    _email = prefs.getString('bio_email');
    _lastLoginEmail = prefs.getString('bio_last_login_email');

    // Sin espera configurada se ignora cualquier pausa guardada antes.
    final snoozeTime = prefs.getInt('bio_snoozed_until');
    if (snoozeTime != null && kBiometricSnoozeDays > 0) {
      _snoozedUntil = DateTime.fromMillisecondsSinceEpoch(snoozeTime);
    } else {
      _snoozedUntil = null;
    }
  }

  /// Último correo usado en un login con contraseña.
  Future<void> saveLastLoginEmail(String email) async {
    _lastLoginEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bio_last_login_email', email);
  }

  /// Fija el correo vinculado a la huella.
  Future<void> saveEmail(String email) async {
    _email = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bio_email', email);
  }

  /// Activa la huella. Si no se indica correo, usa el del último login.
  Future<void> markEnabled({String? email}) async {
    _enabled = true;
    _autoSuppressed = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bio_enabled', true);
    await prefs.setBool('bio_auto_suppressed', false);

    final bound = email ?? _email ?? _lastLoginEmail;
    if (bound != null && bound.isNotEmpty) {
      _email = bound;
      await prefs.setString('bio_email', bound);
    }
  }

  /// "Ahora no": no volver a preguntar durante [days] días.
  Future<void> snooze({int days = kBiometricSnoozeDays}) async {
    final prefs = await SharedPreferences.getInstance();
    if (days <= 0) {
      _snoozedUntil = null;
      await prefs.remove('bio_snoozed_until');
      return;
    }
    _snoozedUntil = DateTime.now().add(Duration(days: days));
    await prefs.setInt('bio_snoozed_until', _snoozedUntil!.millisecondsSinceEpoch);
  }

  /// La huella se quitó (desactivada en Seguridad o borrada del teléfono):
  /// se oculta el botón y se vuelve a poder invitar al usuario.
  Future<void> markDisabled() async {
    _enabled = false;
    _autoSuppressed = false;
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bio_enabled', false);
    await prefs.setBool('bio_auto_suppressed', false);
    await prefs.remove('bio_email');
  }

  Future<void> neverAsk() async {
    _neverAsk = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bio_never_ask', true);
  }

  /// Tras un 401 la huella ya no se lanza sola; el botón sigue disponible.
  Future<void> suppressAutoPrompt() async {
    _autoSuppressed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bio_auto_suppressed', true);
  }
}