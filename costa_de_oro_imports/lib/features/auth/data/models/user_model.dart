/// ============================================================================
/// MODELO: UserModel
/// ============================================================================
/// Representa al usuario autenticado en la aplicación. Refleja el esquema
/// `UserResponse` devuelto por el backend en FastAPI (GET /perfil).
class UserModel {
  const UserModel({
    required this.id,
    required this.correo,
    this.nombres,
    this.apellidos,
    this.telefono,
    this.imagen,
    this.isEnabled,
  });

  final int id;
  final String correo;
  final String? nombres;
  final String? apellidos;
  final String? telefono;
  final String? imagen;
  final bool? isEnabled;

  /// Construye un [UserModel] a partir del JSON del backend.
  /// Se usa `as num?` en el ID para prevenir crasheos si el backend
  /// alguna vez envía nulos en campos requeridos.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['usuario_id'] as num?)?.toInt() ?? 0,
      correo: json['correo'] as String? ?? '',
      nombres: json['nombres'] as String?,
      apellidos: json['apellidos'] as String?,
      telefono: json['telefono'] as String?,
      imagen: json['imagen'] as String?,
      isEnabled: json['is_enabled'] as bool?,
    );
  }

  /// Retorna el nombre completo del usuario.
  /// Si el usuario no tiene nombres o apellidos (ej. recién registrado),
  /// retorna el correo electrónico como "fallback" para no mostrar vacíos.
  String get fullName {
    final name = [nombres, apellidos]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');
    return name.isEmpty ? correo : name;
  }

  /// Genera las iniciales para el avatar (ej: "JP").
  /// Si no hay nombres/apellidos, usa la primera letra del correo.
  String get initials {
    String first(String? s) {
      final t = s?.trim() ?? '';
      return t.isEmpty ? '' : t[0].toUpperCase();
    }
    final result = '${first(nombres)}${first(apellidos)}';
    return result.isEmpty ? first(correo) : result;
  }

  /// Bandera de negocio para el "Perfilamiento Progresivo".
  /// Retorna `true` si el usuario aún tiene los datos "dummy" inyectados
  /// automáticamente durante el registro rápido (por ejemplo, apellido
  /// "Pendiente" o teléfono "0000000000").
  /// La UI usa esto para mostrar el banner de "Completa tu perfil".
  bool get isProfileIncomplete {
    return apellidos == 'Pendiente' || 
           telefono == '0000000000' || 
           telefono == null || 
           telefono!.isEmpty ||
           apellidos == null || 
           apellidos!.isEmpty;
  }
}