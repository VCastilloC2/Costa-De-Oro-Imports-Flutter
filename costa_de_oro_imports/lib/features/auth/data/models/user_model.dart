// RAMA: feature/Auth
// ============================================================================
// MODELO: UserModel
// ============================================================================
// Representa al usuario. Mapea los datos asegurando que el documento se lea
// sin importar si el backend envía snake_case o camelCase.
// ============================================================================

class UserModel {
  const UserModel({
    required this.id,
    required this.correo,
    this.nombres,
    this.apellidos,
    this.telefono,
    this.imagen,
    this.isEnabled,
    this.accountNonExpired,
    this.accountNonLocked,
    this.credentialsNonExpired,
    this.rol,
    this.direccion,
    this.tipoIdentificacion,
    this.numeroIdentificacion,
  });

  final int id;
  final String correo;
  final String? nombres;
  final String? apellidos;
  final String? telefono;
  final String? imagen;
  final bool? isEnabled;
  final bool? accountNonExpired;
  final bool? accountNonLocked;
  final bool? credentialsNonExpired;
  final String? rol;
  final String? direccion;
  final String? tipoIdentificacion;
  final String? numeroIdentificacion;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    bool? readFlag(dynamic value) {
      if (value == true || value == 1) return true;
      if (value == false || value == 0) return false;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
      return null;
    }

    return UserModel(
      id:
          (json['usuarioId'] ?? json['usuario_id'] ?? json['id'] as num?)
              ?.toInt() ??
          0,
      correo: json['correo'] as String? ?? '',
      nombres: json['nombres'] as String?,
      apellidos: json['apellidos'] as String?,
      telefono: json['telefono'] as String?,
      imagen: json['imagen'] as String?,
      isEnabled: readFlag(json['is_enabled'] ?? json['enabled']),
      accountNonExpired: readFlag(json['account_non_expired']),
      accountNonLocked: readFlag(json['account_non_locked']),
      credentialsNonExpired: readFlag(json['credentials_non_expired']),
      rol: (json['rol'] as String?)?.trim().toUpperCase(),
      direccion: json['direccion'] as String?,

      // MAGIA AQUÍ: Buscamos el tipo de documento en todas las variantes posibles.
      tipoIdentificacion:
          (json['tipoIdentificacion'] ??
                  json['tipo_identificacion'] ??
                  json['tipo_documento'])
              ?.toString(),

      // MAGIA AQUÍ: Buscamos el número en todas las variantes posibles.
      numeroIdentificacion:
          (json['numeroIdentificacion'] ??
                  json['numero_identificacion'] ??
                  json['documento'] ??
                  json['identificacion'])
              ?.toString(),
    );
  }

  bool get hasActiveAccount =>
      isEnabled == true &&
      accountNonExpired == true &&
      accountNonLocked == true &&
      credentialsNonExpired == true;

  String get fullName {
    final name = [nombres, apellidos]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');
    return name.isEmpty ? correo : name;
  }

  String get initials {
    String first(String? s) {
      final t = s?.trim() ?? '';
      return t.isEmpty ? '' : t[0].toUpperCase();
    }

    final result = '${first(nombres)}${first(apellidos)}';
    return result.isEmpty ? first(correo) : result;
  }

  bool get isProfileIncomplete {
    return apellidos == 'Pendiente' ||
        telefono == '0000000000' ||
        telefono == null ||
        telefono!.isEmpty ||
        apellidos == null ||
        apellidos!.isEmpty ||
        tipoIdentificacion == null ||
        numeroIdentificacion == null;
  }
}
