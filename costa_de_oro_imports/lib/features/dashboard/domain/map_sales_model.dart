// RAMA: feature/Products
// ============================================================================
// MODELO: Ventas por Ciudad
// ============================================================================
// Parsea la respuesta del endpoint /api/graficas/mapa-ventas.
// ============================================================================

class CitySale {
  final String ciudad;
  final int ventas;
  final double latitud;
  final double longitud;
  final int empresasCompradoras;

  const CitySale({
    required this.ciudad,
    required this.ventas,
    required this.latitud,
    required this.longitud,
    required this.empresasCompradoras,
  });

  factory CitySale.fromJson(Map<String, dynamic> json) => CitySale(
    ciudad: json['ciudad'] ?? 'Desconocida',
    ventas: (json['ventas'] as num?)?.toInt() ?? 0,
    latitud: (json['latitud'] as num?)?.toDouble() ?? 0.0,
    longitud: (json['longitud'] as num?)?.toDouble() ?? 0.0,
    empresasCompradoras: (json['empresasCompradoras'] as num?)?.toInt() ?? 0,
  );
}