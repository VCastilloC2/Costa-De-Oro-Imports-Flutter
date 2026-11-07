// RAMA: feature/Auth
// ============================================================================
// MODELO: UserModel
// ============================================================================
// Representa al usuario autenticado en la aplicación. Refleja el esquema
// devuelto por el backend en el endpoint de login y perfil.
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
    this.rol,
  });

  final int id;
  final String correo;
  final String? nombres;
  final String? apellidos;
  final String? telefono;
  final String? imagen;
  final bool? isEnabled;
  final String? rol;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['usuario_id'] as num?)?.toInt() ?? 0,
      correo: json['correo'] as String? ?? '',
      nombres: json['nombres'] as String?,
      apellidos: json['apellidos'] as String?,
      telefono: json['telefono'] as String?,
      imagen: json['imagen'] as String?,
      isEnabled: json['is_enabled'] as bool?,
      rol: json['rol'] as String?,
    );
  }

  /// Retorna el nombre completo del usuario.
  /// Si no hay nombres o apellidos, retorna el correo como respaldo.
  String get fullName {
    final name = [nombres, apellidos]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');
    return name.isEmpty ? correo : name;
  }

  /// Genera las iniciales para el avatar a partir del nombre o correo.
  String get initials {
    String first(String? s) {
      final t = s?.trim() ?? '';
      return t.isEmpty ? '' : t[0].toUpperCase();
    }

    final result = '${first(nombres)}${first(apellidos)}';
    return result.isEmpty ? first(correo) : result;
  }

  /// Bandera de negocio para el "Perfilamiento Progresivo".
  /// Retorna true si el usuario tiene los datos genéricos del registro rápido.
  /// La UI de perfil (feature/Profile) consume este getter.
  bool get isProfileIncomplete {
    return apellidos == 'Pendiente' ||
        telefono == '0000000000' ||
        telefono == null ||
        telefono!.isEmpty ||
        apellidos == null ||
        apellidos!.isEmpty;
  }
}
