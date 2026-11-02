/// Usuario devuelto por la API (esquema UserResponse de GET /perfil).
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['usuario_id'] as num).toInt(),
      correo: json['correo'] as String,
      nombres: json['nombres'] as String?,
      apellidos: json['apellidos'] as String?,
      telefono: json['telefono'] as String?,
      imagen: json['imagen'] as String?,
      isEnabled: json['is_enabled'] as bool?,
    );
  }

  /// "Keyner Reyes", o el correo si no hay nombre.
  String get fullName {
    final name = [nombres, apellidos]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');
    return name.isEmpty ? correo : name;
  }

  /// Iniciales para el avatar: "KR". Si no hay nombre, la 1.ª letra del correo.
  String get initials {
    String first(String? s) {
      final t = s?.trim() ?? '';
      return t.isEmpty ? '' : t[0].toUpperCase();
    }

    final result = '${first(nombres)}${first(apellidos)}';
    return result.isEmpty ? first(correo) : result;
  }
}