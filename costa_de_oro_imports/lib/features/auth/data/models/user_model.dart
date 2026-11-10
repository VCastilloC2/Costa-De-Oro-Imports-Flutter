// RAMA: feature/Auth
// ============================================================================
// MODELO: UserModel
// ============================================================================
// Representa al usuario autenticado en la aplicación. Refleja el esquema
// devuelto por el backend en los endpoints de login y perfil.
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
  final String? rol;
  final String? direccion;
  final String? tipoIdentificacion;
  final String? numeroIdentificacion;

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
      // NOTA: Si en Swagger las claves son en snake_case (ej. tipo_identificacion),
      // cámbialas aquí.
      direccion: json['direccion'] as String?,
      tipoIdentificacion: json['tipoIdentificacion'] as String? ?? json['tipo_identificacion'] as String?,
      numeroIdentificacion: json['numeroIdentificacion'] as String? ?? json['numero_identificacion'] as String?,
    );
  }

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
           apellidos!.isEmpty;
  }
}