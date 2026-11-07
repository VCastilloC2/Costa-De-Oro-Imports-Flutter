// RAMA: feature/Passkeys
// ============================================================================
// MODELO: PasskeyCredential
// ============================================================================
// Passkey vinculada a la cuenta, tal como la devuelve
// `GET /api/v1/auth/passkey/credentials`. No incluye la clave pública: la app
// solo la muestra y permite revocarla.
// ============================================================================

class PasskeyCredential {
  const PasskeyCredential({
    required this.id,
    required this.credentialId,
    this.deviceName,
    this.deviceType,
    this.backedUp = false,
    this.createdAt,
    this.lastUsedAt,
  });

  factory PasskeyCredential.fromJson(Map<String, dynamic> json) {
    return PasskeyCredential(
      id: (json['passkey_id'] as num?)?.toInt() ?? 0,
      credentialId: json['credential_id'] as String? ?? '',
      deviceName: json['device_name'] as String?,
      deviceType: json['device_type'] as String?,
      backedUp: json['backed_up'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      lastUsedAt: DateTime.tryParse(json['last_used_at'] as String? ?? ''),
    );
  }

  /// `passkey_id` en el backend (se usa para revocarla).
  final int id;

  /// ID WebAuthn de la credencial (base64url).
  final String credentialId;

  /// Nombre que envió la app al registrarla (`iOS`, `Android`…).
  final String? deviceName;

  /// `single_device` o `multi_device`.
  final String? deviceType;

  /// `true` si está sincronizada (iCloud Keychain / Google Password Manager).
  final bool backedUp;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;

  String get displayName =>
      (deviceName?.trim().isNotEmpty ?? false) ? deviceName!.trim() : 'Passkey';
}
