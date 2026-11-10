// RAMA: chore/Core
// ============================================================================
// UTILIDADES: formatters
// ============================================================================
// Funciones puras para mostrar datos de forma consistente en toda la app
// (por ejemplo, el mismo formato de telefono en lectura y en edicion).
// ============================================================================

/// Deja solo los digitos de [value].
String onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

/// Formatea un celular colombiano como `+57 310 223 3445`.
///
/// Acepta el numero con o sin el prefijo 57 y con cualquier separador. Si no
/// tiene 10 digitos (despues de quitar el 57), devuelve el texto original sin
/// tocarlo para no mostrar un dato inventado.
String formatPhoneCo(String raw) {
  var digits = onlyDigits(raw);
  if (digits.length == 12 && digits.startsWith('57')) {
    digits = digits.substring(2);
  }
  if (digits.length != 10) return raw.trim();
  return '+57 ${digits.substring(0, 3)} ${digits.substring(3, 6)} '
      '${digits.substring(6)}';
}

/// Enmascara un documento dejando visibles solo los ultimos 4 caracteres
/// (por ejemplo, `•••• 4567`).
String maskDocument(String raw) {
  final text = raw.trim();
  if (text.length <= 4) return text;
  return '•••• ${text.substring(text.length - 4)}';
}