// RAMA: feature/Products
// ============================================================================
// MODELO: Producto mas vendido
// ============================================================================
// Parsea un elemento de "ventasProducto" de /api/reportes/ventas-producto.
//   - precio: promedio vendido CON IVA (total / cantidad), no el precio de lista.
//   - categoria: se deduce del prefijo del codigo del producto (TEQ-0002).
//   - participacion: fraccion (0 a 1) del total general de ventas; la calcula
//     el provider porque necesita el total del reporte.
//   - imagenUrl: opcional. Cuando el backend la envie (se aceptan los nombres
//     imagenUrl, imagen y urlImagen), la tarjeta muestra la foto; si no, usa el
//     icono de categoria.
// ============================================================================

class TopProduct {
  final String codigo;
  final String nombre;
  final double precio;
  final int ventas;

  /// Total vendido de este producto (con IVA).
  final double total;

  /// Fraccion (0 a 1) del total general de ventas.
  final double participacion;

  /// URL de la foto del producto, si el backend la envia.
  final String? imagenUrl;

  const TopProduct({
    required this.codigo,
    required this.nombre,
    required this.precio,
    required this.ventas,
    this.total = 0,
    this.participacion = 0,
    this.imagenUrl,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    final total = (json['total'] as num?)?.toDouble() ?? 0.0;
    final cantidad = (json['cantidadVendida'] as num?)?.toInt() ?? 1;

    final rawImage = json['imagenUrl'] ?? json['imagen'] ?? json['urlImagen'];
    final image = rawImage?.toString().trim();

    return TopProduct(
      imagenUrl: (image == null || image.isEmpty) ? null : image,
      codigo: json['codigoProducto']?.toString() ?? '',
      nombre: json['nombreProducto'] ?? 'Producto desconocido',
      precio: cantidad > 0 ? (total / cantidad) : 0.0,
      ventas: cantidad,
      total: total,
    );
  }

  /// Copia con la participacion calculada.
  TopProduct withShare(double share) => TopProduct(
        codigo: codigo,
        nombre: nombre,
        precio: precio,
        ventas: ventas,
        total: total,
        participacion: share,
        imagenUrl: imagenUrl,
      );

  /// Categoria legible segun el prefijo del codigo.
  String get categoria {
    final prefix = codigo.split('-').first.toUpperCase();
    switch (prefix) {
      case 'TEQ':
        return 'Tequila';
      case 'WHI':
        return 'Whisky';
      case 'RON':
        return 'Ron';
      case 'VOD':
        return 'Vodka';
      case 'GIN':
        return 'Ginebra';
      case 'VIN':
        return 'Vino';
      case 'AGU':
        return 'Aguardiente';
      case 'CER':
        return 'Cerveza';
      default:
        return 'Licor';
    }
  }
}