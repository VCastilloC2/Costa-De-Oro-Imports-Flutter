// RAMA: feature/Products
// ============================================================================
// WIDGET: RecentOrdersCard
// ============================================================================
// Lista de pedidos recientes pensada para ESCANEAR, no para leer:
//
//   [ icono de estado ]  Producto (hasta 2 lineas)           $ 24.00
//   [   tono suave    ]  #FC0004  ·  24 mar 2023             [Pendiente]
//
//   - Borde izquierdo = estado (icono + tono): se escanea sin leer.
//   - Borde derecho   = monto + estado en texto, alineados verticalmente
//                       (cifras tabulares) para comparar de un vistazo.
//   - Cancelados "retroceden": monto tachado y atenuado.
//   - Si el pedido trae imageUrl, la miniatura reemplaza al icono y el
//     estado pasa a una insignia en su esquina.
//   - Toque: escala + tinte dorado (+ haptico). Mantener presionado copia el
//     numero de pedido ("Copiado").
//   - Entrada escalonada; respeta "reducir animaciones".
// ============================================================================

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../domain/recent_order_model.dart';
import '../../providers/recent_orders_provider.dart';

class RecentOrdersCard extends ConsumerWidget {
  const RecentOrdersCard({super.key, this.onOrderTap});

  /// Si es null las tarjetas son informativas (sin feedback de toque).
  final void Function(RecentOrder order)? onOrderTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final orders = ref.watch(recentOrdersProvider);
    final pending = orders.where((o) => o.status == OrderStatus.pending).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(s: s, total: orders.length, pending: pending),
        SizedBox(height: 14 * s),
        if (orders.isEmpty)
          _EmptyState(s: s)
        else
          for (var i = 0; i < orders.length; i++)
            _Reveal(
              index: i,
              child: Padding(
                padding: EdgeInsets.only(bottom: 10 * s),
                child: _OrderTile(
                  s: s,
                  order: orders[i],
                  onTap: onOrderTap == null ? null : () => onOrderTap!(orders[i]),
                ),
              ),
            ),
      ],
    );
  }
}

// ============================================================================
// ESTILO POR ESTADO (presentacion). Paleta calida y apagada, coherente con
// crema / cafe / dorado. Cada estado ademas lleva icono y texto: el color
// nunca es la unica señal.
// ============================================================================
extension OrderStatusStyle on OrderStatus {
  String get label => switch (this) {
        OrderStatus.pending => 'Pendiente',
        OrderStatus.processed => 'Procesado',
        OrderStatus.completed => 'Completado',
        OrderStatus.cancelled => 'Cancelado',
        OrderStatus.unknown => 'Sin estado',
      };

  /// Color de texto / icono.
  Color get fg => switch (this) {
        OrderStatus.pending => const Color(0xFF9A6A12), // ambar tostado
        OrderStatus.processed => const Color(0xFF4F6578), // azul pizarra
        OrderStatus.completed => const Color(0xFF4F7A5A), // verde salvia
        OrderStatus.cancelled => const Color(0xFFA8503F), // terracota
        OrderStatus.unknown => const Color(0xFF8A7F74), // piedra
      };

  /// Fondo suave de la insignia / tile.
  Color get bg => switch (this) {
        OrderStatus.pending => const Color(0xFFF6E8C8),
        OrderStatus.processed => const Color(0xFFE6ECF0),
        OrderStatus.completed => const Color(0xFFE2EBE0),
        OrderStatus.cancelled => const Color(0xFFF4E0DA),
        OrderStatus.unknown => const Color(0xFFEDE8E1),
      };

  List<List<dynamic>> get icon => switch (this) {
        OrderStatus.pending => HugeIcons.strokeRoundedTimer01,
        OrderStatus.processed => HugeIcons.strokeRoundedDeliveryTruck01,
        OrderStatus.completed => HugeIcons.strokeRoundedCheckmarkCircle02,
        OrderStatus.cancelled => HugeIcons.strokeRoundedAlertCircle,
        OrderStatus.unknown => HugeIcons.strokeRoundedTimer01,
      };
}

// ============================================================================
// ENCABEZADO
// ============================================================================
class _Header extends StatelessWidget {
  const _Header({required this.s, required this.total, required this.pending});
  final double s;
  final int total;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final muted = AppFonts.style(
      size: 12.5 * s,
      weight: FontWeight.w500,
      color: AppColors.muted,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pedidos recientes',
          style: AppFonts.style(
            size: 18 * s,
            weight: FontWeight.w800,
            color: AppColors.brownDark,
          ),
        ),
        SizedBox(height: 2 * s),
        Text.rich(
          TextSpan(
            style: muted,
            children: [
              TextSpan(text: total == 1 ? '1 pedido' : '$total pedidos'),
              if (pending > 0) ...[
                const TextSpan(text: '  ·  '),
                TextSpan(
                  text: pending == 1 ? '1 pendiente' : '$pending pendientes',
                  style: AppFonts.style(
                    size: 12.5 * s,
                    weight: FontWeight.w700,
                    color: OrderStatus.pending.fg,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TARJETA DE PEDIDO
// ============================================================================
class _OrderTile extends StatefulWidget {
  const _OrderTile({required this.s, required this.order, required this.onTap});
  final double s;
  final RecentOrder order;
  final VoidCallback? onTap;

  @override
  State<_OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends State<_OrderTile> {
  bool _pressed = false;
  bool _copied = false;
  Timer? _timer;

  bool get _tappable => widget.onTap != null;

  void _setPressed(bool v) {
    if (!_tappable || _pressed == v) return;
    setState(() => _pressed = v);
  }

  Future<void> _copyId() async {
    HapticFeedback.mediumImpact();
    await Clipboard.setData(ClipboardData(text: widget.order.id));
    if (!mounted) return;
    _timer?.cancel();
    setState(() => _copied = true);
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final order = widget.order;
    final status = order.status;
    final cancelled = status == OrderStatus.cancelled;
    final price = _formatPrice(order.price);
    final date = _formatDate(order.date);

    final tabular = const [FontFeature.tabularFigures()];

    return Semantics(
      button: _tappable,
      label: 'Pedido ${order.id}, ${order.product}, ${status.label}, $price, $date',
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: _tappable
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onTap!();
                  }
                : null,
            onLongPress: _copyId,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: EdgeInsets.all(14 * s),
              decoration: BoxDecoration(
                color: _pressed
                    ? Color.lerp(Colors.white, AppColors.gold, 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20 * s),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brownDark.withValues(alpha: _pressed ? 0.03 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Leading(s: s, order: order),
                  SizedBox(width: 12 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.product,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.style(
                            size: 14.5 * s,
                            weight: FontWeight.w700,
                            color: cancelled ? AppColors.muted : AppColors.brownDark,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: 5 * s),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _copied
                              ? Text(
                                  'Pedido copiado',
                                  key: const ValueKey('copied'),
                                  style: AppFonts.style(
                                    size: 12.5 * s,
                                    weight: FontWeight.w700,
                                    color: AppColors.goldDark,
                                  ),
                                )
                              : Text.rich(
                                  key: const ValueKey('info'),
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: order.id,
                                        style: AppFonts.style(
                                          size: 12.5 * s,
                                          weight: FontWeight.w700,
                                          color: AppColors.brown.withValues(alpha: 0.85),
                                        ).copyWith(fontFeatures: tabular),
                                      ),
                                      TextSpan(
                                        text: '  ·  $date',
                                        style: AppFonts.style(
                                          size: 12.5 * s,
                                          weight: FontWeight.w500,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10 * s),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        price,
                        style: AppFonts.style(
                          size: 16 * s,
                          weight: FontWeight.w800,
                          color: cancelled ? AppColors.muted : AppColors.brownDark,
                        ).copyWith(
                          fontFeatures: tabular,
                          decoration: cancelled ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.muted,
                        ),
                      ),
                      SizedBox(height: 6 * s),
                      _StatusPill(s: s, status: status),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.s, required this.status});
  final double s;
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(20 * s),
      ),
      child: Text(
        status.label,
        style: AppFonts.style(
          size: 11.5 * s,
          weight: FontWeight.w700,
          color: status.fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Icono de estado (sin imagen) o miniatura del producto con insignia de estado.
class _Leading extends StatelessWidget {
  const _Leading({required this.s, required this.order});
  final double s;
  final RecentOrder order;

  @override
  Widget build(BuildContext context) {
    final size = 48 * s;
    final radius = BorderRadius.circular(15 * s);
    final status = order.status;
    final url = order.imageUrl;

    final iconTile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: status.bg, borderRadius: radius),
      child: Center(
        child: HugeIcon(
          icon: status.icon,
          size: 22 * s,
          color: status.fg,
          strokeWidth: 2.0,
        ),
      ),
    );

    if (url == null || !url.startsWith('http')) return iconTile;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (context, _) => Container(color: status.bg),
              errorWidget: (context, _, __) => iconTile,
            ),
          ),
          Positioned(
            right: -4 * s,
            bottom: -4 * s,
            child: Container(
              width: 20 * s,
              height: 20 * s,
              decoration: BoxDecoration(
                color: status.fg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: HugeIcon(
                  icon: status.icon,
                  size: 11 * s,
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.s});
  final double s;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28 * s, horizontal: 16 * s),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedDeliveryTruck01,
            size: 28 * s,
            color: AppColors.goldDark,
            strokeWidth: 2.0,
          ),
          SizedBox(height: 10 * s),
          Text(
            'Aún no hay pedidos',
            style: AppFonts.style(
              size: 14.5 * s,
              weight: FontWeight.w700,
              color: AppColors.brownDark,
            ),
          ),
          SizedBox(height: 2 * s),
          Text(
            'Cuando lleguen aparecerán aquí.',
            style: AppFonts.style(
              size: 12.5 * s,
              weight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ENTRADA ESCALONADA
// ============================================================================
class _Reveal extends StatelessWidget {
  const _Reveal({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final extra = (index > 8 ? 8 : index) * 70;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: reduce ? Duration.zero : Duration(milliseconds: 380 + extra),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

// ============================================================================
// FORMATO
// ============================================================================
/// Mantiene el formato actual ($18.00). Cuando se defina la moneda real
/// (COP, enteros, separador de miles) se cambia solo aqui.
String _formatPrice(double v) => '\$${v.toStringAsFixed(2)}';

const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// "Hoy", "Ayer", "24 mar" (mismo año) o "24 mar 2023".
String _formatDate(DateTime? d) {
  if (d == null) return '—';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  final base = '${d.day} ${_months[d.month - 1]}';
  return d.year == now.year ? base : '$base ${d.year}';
}