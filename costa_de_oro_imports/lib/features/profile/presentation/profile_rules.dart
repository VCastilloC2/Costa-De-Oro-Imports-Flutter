// RAMA: feature/Profile
// ============================================================================
// REGLAS DE PERFIL
// ============================================================================

abstract final class ProfileRules {
  static const String placeholderName = 'Pendiente';
  static const String emptyAddress = 'Por definir';
  static const int totalFields = 5;

  static String? cleanName(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty || text == placeholderName) return null;
    return text;
  }

  static String? cleanPhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty || digits.replaceAll('0', '').isEmpty) return null;
    return digits;
  }

  static String? cleanAddress(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty || text == emptyAddress) return null;
    return text;
  }

  static String? cleanText(String? value) {
    final text = value?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static String? _name(String? value, String message) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return message;
    if (text.length < 2) return 'Es muy corto';
    if (RegExp(r'\d').hasMatch(text)) return 'No puede contener números';
    return null;
  }

  static String? nombres(String? value) => _name(value, 'Escribe tus nombres');
  static String? apellidos(String? value) => _name(value, 'Escribe tus apellidos');

  static String? documento(String tipo, String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Escribe tu número de documento';

    final cleanText = text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

    if (tipo == 'Pasaporte') {
      return RegExp(r'^[A-Za-z0-9]{5,15}$').hasMatch(cleanText) ? null : 'Entre 5 y 15 letras o números';
    }
    if (!RegExp(r'^\d+$').hasMatch(cleanText)) return 'Usa solo números';
    if (tipo == 'CC') {
      return (cleanText.length >= 6 && cleanText.length <= 10) ? null : 'La cédula tiene entre 6 y 10 dígitos';
    }
    return (cleanText.length >= 5 && cleanText.length <= 15) ? null : 'Entre 5 y 15 dígitos';
  }

  static String? telefono(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Escribe tu teléfono';
    if (digits.length != 10) return 'Debe tener 10 dígitos';
    return null;
  }

  static String? direccion(String? value) {
    final text = (value ?? '').trim();
    // La dirección vacía cuenta como dato faltante (para que el perfil diga 80%)
    if (text.isEmpty) return 'Escribe tu dirección de envío'; 
    if (text.length < 6) return 'Escribe la dirección completa';
    return null;
  }

  static int doneCount({
    String? nombres,
    String? apellidos,
    String? tipo,
    String? numero,
    String? telefono,
    String? direccion,
  }) {
    final results = <String?>[
      ProfileRules.nombres(cleanName(nombres)),
      ProfileRules.apellidos(cleanName(apellidos)),
      documento(cleanText(tipo) ?? 'CC', cleanText(numero)),
      ProfileRules.telefono(cleanPhone(telefono)),
      ProfileRules.direccion(cleanAddress(direccion)),
    ];
    return results.where((e) => e == null).length;
  }
}