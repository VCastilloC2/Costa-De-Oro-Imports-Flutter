import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';

/// ============================================================================
/// BARRA DE NAVEGACIÓN INFERIOR
/// ============================================================================
/// - Barra blanca con esquinas superiores redondeadas y sombra suave.
/// - Un único indicador beige que se desliza entre las opciones.
/// - El ícono activo cambia a su versión rellena y crece un poco.
/// - Vibración ligera al tocar y soporte de lectores de pantalla.
/// - Insignias opcionales (por ejemplo, pedidos pendientes) con [badges].
///
/// Opciones: 0 Inicio, 1 Productos, 2 Compras, 3 Clientes, 4 Más.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Número a mostrar sobre cada opción. Ejemplo: `{2: 5}` muestra un 5 en
  /// "Compras". Si el valor es 0 o la opción no está en el mapa, no se muestra.
  final Map<int, int> badges;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges = const {},
  });

  static const _items = <_NavItem>[
    _NavItem('Inicio', Icons.home_outlined, Icons.home_rounded),
    _NavItem(
      'Productos',
      Icons.shopping_bag_outlined,
      Icons.shopping_bag_rounded,
    ),
    _NavItem(
      'Compras',
      Icons.receipt_long_outlined,
      Icons.receipt_long_rounded,
    ),
    _NavItem('Clientes', Icons.people_outline_rounded, Icons.people_rounded),
    _NavItem('Más', Icons.menu_rounded, Icons.menu_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;
    final pillWidth = 62 * s;
    final pillHeight = 54 * s;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24 * s)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brownDark.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8 * s, 10 * s, 8 * s, 8 * s),
          child: SizedBox(
            height: pillHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / _items.length;

                return Stack(
                  children: [
                    // Indicador que se desliza hasta la opción activa
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: currentIndex * itemWidth + (itemWidth - pillWidth) / 2,
                      top: 0,
                      width: pillWidth,
                      height: pillHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.beige,
                          borderRadius: BorderRadius.circular(18 * s),
                        ),
                      ),
                    ),

                    // Opciones
                    Row(
                      children: List.generate(_items.length, (index) {
                        return Expanded(
                          child: _NavButton(
                            item: _items[index],
                            selected: index == currentIndex,
                            badge: badges[index] ?? 0,
                            s: s,
                            onTap: () {
                              if (index != currentIndex) {
                                HapticFeedback.selectionClick();
                              }
                              onTap(index);
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(this.label, this.icon, this.activeIcon);
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final int badge;
  final double s;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.badge,
    required this.s,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brownDark : AppColors.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        selected ? item.activeIcon : item.icon,
                        key: ValueKey(selected),
                        color: color,
                        size: 24 * s,
                      ),
                    ),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -8 * s,
                      top: -5 * s,
                      child: _Badge(count: badge, s: s),
                    ),
                ],
              ),
              SizedBox(height: 3 * s),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppFonts.style(
                  size: 11 * s,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(item.label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final double s;

  const _Badge({required this.count, required this.s});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';

    return Container(
      constraints: BoxConstraints(minWidth: 16 * s, minHeight: 16 * s),
      padding: EdgeInsets.symmetric(horizontal: 4 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(10 * s),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppFonts.style(
          size: 9 * s,
          weight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}