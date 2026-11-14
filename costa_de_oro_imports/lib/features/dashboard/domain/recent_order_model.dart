// RAMA: feature/Products
// ============================================================================
// MODELO: Pedido Reciente
// ============================================================================
// Mapea exactamente la respuesta del endpoint /api/reportes/pedidos-recientes
// ============================================================================

enum OrderStatus {
  pending,
  processed,
  completed,
  cancelled,
  rejected, // <-- Agregado para mapear el estado "RECHAZADO" de la API
  unknown;

  static OrderStatus parse(Object? raw) {
    switch (raw?.toString().trim().toUpperCase()) {
      case 'PENDIENTE':
      case 'PENDING':
        return OrderStatus.pending;
      case 'PROCESADO':
      case 'PROCESSING':
      case 'PROCESSED':
        return OrderStatus.processed;
      case 'PAGADO':
      case 'COMPLETADO':
      case 'COMPLETED':
        return OrderStatus.completed;
      case 'CANCELADO':
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'RECHAZADO':
      case 'REJECTED':
        return OrderStatus.rejected;
      default:
        return OrderStatus.unknown;
    }
  }
}

class RecentOrder {
  const RecentOrder({
    required this.id,
    required this.status,
    required this.product,
    required this.date,
    required this.price,
    this.imageUrl,
  });

  final String id;
  final OrderStatus status;
  final String product;
  final DateTime? date;
  final double price;
  final String? imageUrl;

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      // El API manda "numeroPedido": "FC17949". Le ponemos el '#' visual.
      id: json['numeroPedido'] != null ? '#${json['numeroPedido']}' : '#---',
      
      // Mapea el campo "estado"
      status: OrderStatus.parse(json['estado']),
      
      // Mapea el campo "producto"
      product: json['producto']?.toString() ?? 'Producto desconocido',
      
      // Mapea el campo "fecha"
      date: DateTime.tryParse(json['fecha']?.toString() ?? ''),
      
      // Mapea el campo "total" (viene como entero)
      price: (json['total'] as num?)?.toDouble() ?? 0.0,
      
      // Tu API actual no manda imagen, pero dejamos el campo listo
      imageUrl: json['imagenUrl']?.toString(),
    );
  }
}