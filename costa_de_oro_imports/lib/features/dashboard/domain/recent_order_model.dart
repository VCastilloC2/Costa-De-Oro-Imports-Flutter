// RAMA: feature/Products
// ============================================================================
// MODELO: Pedido Reciente
// ============================================================================
// Dominio puro (sin Flutter): el estado es un enum y la fecha un DateTime.
// Los colores, iconos y textos de cada estado viven en la capa de
// presentacion (ver recent_orders_card.dart), no aqui.
//
// Contrato sugerido para el endpoint (hablar con quien lo esta creando):
//   - id        : string        ("FC0005" o "#FC0005")
//   - status    : codigo estable "pending|processed|completed|cancelled"
//                 (no la etiqueta en español: la etiqueta es presentacion)
//   - date      : ISO-8601      ("2025-03-24T10:30:00-05:00")
//   - price     : idealmente entero en centavos + currency ("COP")
//   - image_url : opcional (miniatura del producto)
// ============================================================================

enum OrderStatus {
  pending,
  processed,
  completed,
  cancelled,
  unknown;

  /// Acepta codigos en ingles y etiquetas en español. Un valor no reconocido
  /// NO se disfraza de "pendiente": queda como [unknown].
  static OrderStatus parse(Object? raw) {
    switch (raw?.toString().trim().toLowerCase()) {
      case 'pending':
      case 'pendiente':
        return OrderStatus.pending;
      case 'processed':
      case 'processing':
      case 'procesado':
        return OrderStatus.processed;
      case 'completed':
      case 'complete':
      case 'completado':
        return OrderStatus.completed;
      case 'cancelled':
      case 'canceled':
      case 'cancelado':
        return OrderStatus.cancelled;
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

  /// Nula si el backend no la envia o no se pudo interpretar.
  final DateTime? date;
  final double price;
  final String? imageUrl;

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      id: json['id']?.toString() ?? '',
      status: OrderStatus.parse(json['status']),
      product: json['product']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url']?.toString(),
    );
  }
}