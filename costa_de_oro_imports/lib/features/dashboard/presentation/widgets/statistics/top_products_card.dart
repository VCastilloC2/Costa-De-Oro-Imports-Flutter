// RAMA: feature/Products
// ============================================================================
// WIDGET: TopProductsCard
// ============================================================================
// Cuadricula 2x2 con los 4 productos mas vendidos (por unidades).
//
// Cada tarjeta:
//   - Vitrina: fondo champan con foco de luz teñido segun la categoria, anillos
//     dorados concentricos y una sombra de apoyo. El producto "flota" con un
//     vaiven suave y la sombra reacciona. Si el backend envia [imagenUrl] se
//     muestra la foto (ajustada y centrada, con aparicion suave); si no, un
//     icono de categoria en un circulo de vidrio.
//   - Insignia de posicion (#1 a #4) y chip de categoria con su color.
//   - El #1 lleva marco dorado con brillo y una corona en su insignia.
//   - Nombre, precio promedio (con IVA) y unidades, con conteo animado.
//   - Barra de participacion sobre las ventas totales del anio (relativa al
//     producto con mayor participacion del top).
//   - Entrada escalonada de las tarjetas.
// La respuesta tactil (hundirse y vibrar) se activa al pasar [onProductTap].
// Con "animaciones reducidas" del sistema, el vaiven y el brillo se desactivan.
// ============================================================================

import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../domain/top_product_model.dart';
import '../../providers/top_products_provider.dart';

class TopProductsCard extends ConsumerWidget {
  /// Accion al tocar un producto (por ejemplo, abrir su detalle). Opcional.
  final void Function(TopProduct product)? onProductTap;

  const TopProductsCard({super.key, this.onProductTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final productsAsync = ref.watch(topProductsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productos más vendidos',
          style: AppFonts.style(
            size: 18 * s,
            weight: FontWeight.w700,
            color: AppColors.brownDark,
          ),
        ),
        SizedBox(height: 2 * s),
        Text(
          'Por unidades vendidas este año',
          style: AppFonts.style(size: 11.5 * s, color: AppColors.muted),
        ),
        SizedBox(height: 14 * s),
        productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'Error al cargar productos',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
          data: (products) {
            if (products.isEmpty) return const SizedBox.shrink();
            final maxShare = products.fold<double>(
              0,
              (m, p) => p.participacion > m ? p.participacion : m,
            );
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12 * s,
                mainAxisSpacing: 12 * s,
                childAspectRatio: 0.64,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) => _Entrance(
                index: index,
                child: _ProductTile(
                  product: products[index],
                  rank: index + 1,
                  maxShare: maxShare,
                  s: s,
                  onTap: onProductTap == null ? null : () => onProductTap!(products[index]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Entrada escalonada: la tarjeta aparece subiendo, una tras otra.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const base = 520;
    final total = base + index * 130;
    final start = index * 130 / total;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      builder: (context, t, _) {
        final p = Curves.easeOutCubic.transform(
          ((t - start) / (1 - start)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: p,
          child: Transform.translate(offset: Offset(0, (1 - p) * 18), child: child),
        );
      },
    );
  }
}

class _ProductTile extends StatefulWidget {
  const _ProductTile({
    required this.product,
    required this.rank,
    required this.maxShare,
    required this.s,
    this.onTap,
  });

  final TopProduct product;
  final int rank;
  final double maxShare;
  final double s;
  final VoidCallback? onTap;

  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile> with TickerProviderStateMixin {
  bool _down = false;

  /// Vaiven del producto (sube y baja suavemente).
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 3000 + widget.rank * 350),
  );

  /// Brillo unico que cruza la tarjeta del #1.
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.rank == 1) {
      Future<void>.delayed(const Duration(milliseconds: 1100), () {
        if (mounted && !MediaQuery.disableAnimationsOf(context)) _sheen.forward();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _sheen.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // CATEGORIA
  // --------------------------------------------------------------------------

  IconData get _icon {
    switch (widget.product.categoria) {
      case 'Vino':
        return Icons.wine_bar_outlined;
      case 'Cerveza':
        return Icons.sports_bar_outlined;
      default:
        return Icons.liquor_outlined;
    }
  }

  /// Color propio de cada categoria (matiz del foco de luz y del chip).
  Color get _accent {
    switch (widget.product.categoria) {
      case 'Tequila':
        return const Color(0xFFE0A526);
      case 'Whisky':
        return const Color(0xFFB8741A);
      case 'Ron':
        return const Color(0xFF9C5A33);
      case 'Vodka':
        return const Color(0xFF8FB0C4);
      case 'Ginebra':
        return const Color(0xFF6FAE9B);
      case 'Vino':
        return const Color(0xFFA6405F);
      case 'Aguardiente':
        return const Color(0xFFD6A03C);
      case 'Cerveza':
        return const Color(0xFFE6B02E);
      default:
        return AppColors.gold;
    }
  }

  String _money(double v) {
    final digits = v.round().toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '\$$grouped';
  }

  String _percent(double share) {
    final pct = share * 100;
    if (pct > 0 && pct < 0.1) return '<0,1';
    return pct.toStringAsFixed(1).replaceAll('.', ',');
  }

  // --------------------------------------------------------------------------
  // PIEZAS
  // --------------------------------------------------------------------------

  /// Icono de categoria en circulo de vidrio (respaldo cuando no hay foto).
  Widget _iconBadge(double s) {
    return Container(
      width: 62 * s,
      height: 62 * s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.6),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldDark.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(_icon, size: 30 * s, color: AppColors.goldDark),
    );
  }

  /// Producto: foto si hay URL; icono de categoria si no hay, carga o falla.
  Widget _productVisual(double s) {
    final url = widget.product.imagenUrl;
    if (url == null) return _iconBadge(s);

    return Padding(
      padding: EdgeInsets.fromLTRB(16 * s, 34 * s, 16 * s, 26 * s),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        fadeInDuration: const Duration(milliseconds: 420),
        fadeInCurve: Curves.easeOutCubic,
        placeholder: (context, _) => Center(child: _iconBadge(s)),
        errorWidget: (context, _, __) => Center(child: _iconBadge(s)),
      ),
    );
  }

  Widget _hero(double s) {
    final p = widget.product;
    final topThree = widget.rank <= 3;
    final isFirst = widget.rank == 1;

    return Stack(
      children: [
        // Fondo champan.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFBF3E6), Color(0xFFF1DDBB)],
              ),
            ),
          ),
        ),
        // Foco de luz teñido con el color de la categoria.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0.15),
                radius: 0.8,
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  _accent.withValues(alpha: 0.2),
                  _accent.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        // Anillos dorados concentricos.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _RingsPainter(s: s)),
          ),
        ),

        // Producto flotando y su sombra de apoyo.
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _float,
            builder: (context, _) {
              final f = Curves.easeInOut.transform(_float.value);
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Sombra de apoyo: se estrecha cuando el producto sube.
                  Positioned(
                    bottom: 14 * s,
                    child: Transform.scale(
                      scaleX: 1 - 0.18 * f,
                      child: Container(
                        width: 58 * s,
                        height: 8 * s,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: AppColors.brownDark.withValues(alpha: 0.10 - 0.03 * f),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brownDark.withValues(alpha: 0.16 - 0.05 * f),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, -5 * s * f),
                    child: _productVisual(s),
                  ),
                ],
              );
            },
          ),
        ),

        // Insignia de posicion.
        Positioned(
          left: 10 * s,
          top: 10 * s,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20 * s),
              gradient: topThree
                  ? const LinearGradient(colors: [AppColors.goldLight, AppColors.gold])
                  : null,
              border: topThree
                  ? null
                  : Border.all(color: AppColors.brownDark.withValues(alpha: 0.4)),
              boxShadow: isFirst
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.45),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFirst) ...[
                  Icon(Icons.workspace_premium_rounded, size: 13 * s, color: AppColors.brownDark),
                  SizedBox(width: 3 * s),
                ],
                Text(
                  '#${widget.rank}',
                  style: AppFonts.style(
                    size: 11 * s,
                    weight: FontWeight.w800,
                    color: AppColors.brownDark,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Chip de categoria con su color.
        Positioned(
          right: 10 * s,
          top: 10 * s,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20 * s),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6 * s,
                  height: 6 * s,
                  decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
                ),
                SizedBox(width: 5 * s),
                Text(
                  p.categoria,
                  style: AppFonts.style(
                    size: 9.5 * s,
                    weight: FontWeight.w700,
                    color: AppColors.brownDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(double s) {
    final p = widget.product;
    final delay = widget.rank * 120;

    return Padding(
      padding: EdgeInsets.fromLTRB(12 * s, 10 * s, 12 * s, 12 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            p.nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.style(
              size: 12.5 * s,
              weight: FontWeight.w600,
              color: AppColors.brownDark,
              height: 1.25,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: p.precio),
                    duration: Duration(milliseconds: 900 + delay),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Text(
                      _money(v),
                      style: AppFonts.style(
                        size: 17 * s,
                        weight: FontWeight.w800,
                        color: AppColors.brownDark,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6 * s),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
                decoration: BoxDecoration(
                  color: AppColors.beige,
                  borderRadius: BorderRadius.circular(20 * s),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: p.ventas.toDouble()),
                  duration: Duration(milliseconds: 800 + delay),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    '${v.round()} uds',
                    style: AppFonts.style(
                      size: 10.5 * s,
                      weight: FontWeight.w700,
                      color: AppColors.brown,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_percent(p.participacion)} % de las ventas',
                style: AppFonts.style(
                  size: 10 * s,
                  weight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              SizedBox(height: 5 * s),
              _ShareBar(
                fraction: widget.maxShare > 0
                    ? (p.participacion / widget.maxShare).clamp(0.05, 1.0)
                    : 0,
                delay: delay,
                s: s,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final isFirst = widget.rank == 1;
    final radius = 20 * s;
    final border = 1.6 * s;

    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(isFirst ? radius - border : radius),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 10, child: _hero(s)),
              Expanded(flex: 10, child: _body(s)),
            ],
          ),
          // Brillo unico del #1.
          if (isFirst)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _sheen,
                  builder: (context, _) {
                    if (_sheen.value == 0 || _sheen.value == 1) {
                      return const SizedBox.shrink();
                    }
                    final p = Curves.easeInOut.transform(_sheen.value);
                    final x0 = -1.6 + 3.2 * p;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(x0, -0.7),
                          end: Alignment(x0 + 0.6, 0.7),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.38),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );

    final card = Container(
      padding: isFirst ? EdgeInsets.all(border) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        gradient: isFirst
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isFirst
                ? AppColors.gold.withValues(alpha: 0.28)
                : AppColors.brownDark.withValues(alpha: 0.06),
            blurRadius: isFirst ? 20 : 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: isFirst
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radius - border),
              ),
              child: inner,
            )
          : inner,
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap!();
      },
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }
}

/// Dos anillos dorados concentricos detras del producto.
class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.s});

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.55);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    paint.color = AppColors.gold.withValues(alpha: 0.2);
    canvas.drawCircle(c, math.min(size.width, size.height) * 0.36, paint);
    paint.color = AppColors.gold.withValues(alpha: 0.11);
    canvas.drawCircle(c, math.min(size.width, size.height) * 0.52, paint);
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.s != s;
}

/// Barra fina de participacion que se llena al aparecer.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.fraction, required this.delay, required this.s});

  final double fraction;
  final int delay;
  final double s;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: fraction),
      duration: Duration(milliseconds: 700 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Container(
        height: 4 * s,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.beige,
          borderRadius: BorderRadius.circular(4 * s),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4 * s),
              gradient: const LinearGradient(
                colors: [AppColors.goldLight, AppColors.gold],
              ),
            ),
          ),
        ),
      ),
    );
  }
}