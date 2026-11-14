// RAMA: feature/Products
// ============================================================================
// PROVIDER: Pedidos Recientes
// ============================================================================
// MOCK mientras el endpoint no existe. Cuando este listo, reemplazar por un
// FutureProvider/AsyncNotifier que consuma el repositorio; la tarjeta solo
// necesitara un `.when(data/loading/error)`.
//
// El backend debe entregar la lista ya ordenada por fecha descendente: la UI
// no reordena.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/recent_order_model.dart';

final recentOrdersProvider = Provider<List<RecentOrder>>((ref) {
  return [
    RecentOrder(
      id: '#FC0005',
      status: OrderStatus.processed,
      product: 'Vodka Smirnoff Red Label Clásico 700 ml',
      date: DateTime(2023, 3, 28),
      price: 18.00,
    ),
    RecentOrder(
      id: '#FC0004',
      status: OrderStatus.pending,
      product: 'Vodka Smirnoff Red Label Clásico 700 ml',
      date: DateTime(2023, 3, 24),
      price: 24.00,
    ),
    RecentOrder(
      id: '#FC0003',
      status: OrderStatus.cancelled,
      product: 'Vodka Smirnoff Red Label Clásico 700 ml',
      date: DateTime(2025, 3, 24),
      price: 27.00,
    ),
    RecentOrder(
      id: '#FC0002',
      status: OrderStatus.completed,
      product: 'Vodka Smirnoff Red Label Clásico 700 ml',
      date: DateTime(2024, 3, 24),
      price: 34.00,
    ),
  ];
});