/// Configuración de Passkeys (WebAuthn / FIDO2).
///
/// Se lee de `--dart-define` igual que [AppConfig] y [ApiConfig]:
///
/// ```bash
/// flutter run --dart-define-from-file=config/dev.json
/// ```
///
/// Mientras `PASSKEY_RP_ID` esté vacío, las passkeys quedan **desactivadas**:
/// no se muestra el botón, no se ofrece el registro y no se llama a ningún
/// endpoint nuevo. Así la app sigue funcionando exactamente igual que antes
/// en los entornos que todavía no tienen dominio configurado.
class PasskeyConfig {
  PasskeyConfig._();

  /// Relying Party ID: el dominio (sin esquema ni puerto) dueño de las
  /// passkeys, por ejemplo `costadeoroimports.com`.
  ///
  /// Debe coincidir con:
  /// - `rp.id` / `rpId` que envía el backend en las opciones de WebAuthn.
  /// - El dominio de `webcredentials:` en Associated Domains (iOS).
  /// - El dominio que publica `/.well-known/assetlinks.json` (Android).
  static const rpId = String.fromEnvironment('PASSKEY_RP_ID');

  /// `true` cuando hay un dominio configurado.
  static bool get isEnabled => rpId.isNotEmpty;

  /// Tiempo máximo que se le da al usuario en la hoja del sistema.
  static const ceremonyTimeout = Duration(minutes: 2);

  /// Longitud mínima del challenge (bytes). WebAuthn recomienda ≥ 16 bytes
  /// aleatorios; un challenge más corto indica un backend mal configurado.
  static const minChallengeBytes = 16;
}
