/// Validaciones de formularios compartidas, para que todas las pantallas
/// acepten lo mismo y muestren los mismos mensajes.
class Validators {
  Validators._();

  /// Longitud mínima de contraseña que acepta el backend.
  static const minPasswordLength = 5;

  // Acepta "+", subdominios y dominios de más de 4 letras (ej. .travel).
  static final _email = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$",
  );

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'El correo es obligatorio';
    }
    if (!_email.hasMatch(email)) {
      return 'Correo inválido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < minPasswordLength) {
      return 'Debe tener al menos $minPasswordLength caracteres';
    }
    return null;
  }

  /// Devuelve un validador que compara con la contraseña actual.
  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Debes confirmar la contraseña';
      }
      if (value != original()) {
        return 'Las contraseñas no coinciden';
      }
      return null;
    };
  }
}
