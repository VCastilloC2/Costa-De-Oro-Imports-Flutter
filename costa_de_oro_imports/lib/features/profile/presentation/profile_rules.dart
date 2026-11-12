// RAMA: feature/Profile
// ============================================================================
// REGLAS DE PERFIL
// ============================================================================
// Una sola fuente de verdad para saber qué datos del perfil son reales, si
// son válidos y cuántos faltan.
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
    var digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    // Eliminamos el prefijo 57 si viene con 12 dígitos.
    if (digits.length == 12 && digits.startsWith('57')) {
      digits = digits.substring(2);
    }
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
    
    // Limpiamos cualquier máscara o caracter especial.
    final cleanText = text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    
    if (tipo == 'Pasaporte') {
      return RegExp(r'^[A-Za-z0-9]{4,15}$').hasMatch(cleanText) ? null : 'Entre 4 y 15 letras o números';
    }
    if (!RegExp(r'^\d+$').hasMatch(cleanText)) return 'Usa solo números';
    
    // ACTUALIZADO: Acepta desde 4 dígitos (para tus pruebas) hasta 13 dígitos.
    return (cleanText.length >= 4 && cleanText.length <= 13) 
        ? null 
        : 'Debe tener entre 4 y 13 dígitos';
  }

  static String? telefono(String? value) {
    var digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('57')) {
      digits = digits.substring(2);
    }
    if (digits.isEmpty) return 'Escribe tu teléfono';
    if (digits.length != 10) return 'Debe tener 10 dígitos';
    return null;
  }

  static String? direccion(String? value) {
    final text = (value ?? '').trim();
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
    
    // Retorna cuántos campos son válidos (null significa que no hay error).
    return results.where((e) => e == null).length;
  }
}