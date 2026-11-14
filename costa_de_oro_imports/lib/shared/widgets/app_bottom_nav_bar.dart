// RAMA: chore/Core
// ============================================================================
// WIDGET: AppBottomNavBar
// ============================================================================
// Barra de navegacion inferior estilo "pildora expandible".
// Cuenta con 4 modulos: Inicio, Productos, Prediccion y Perfil.
// Utiliza un solo icono por modulo, cambiando su color y grosor al estar activo.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart'; 
import 'package:hugeicons/hugeicons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  // Definicion de los 4 modulos con un solo icono
  static final List<_NavItem> _items = [
    const _NavItem(
      label: 'Inicio',
      icon: HugeIcons.strokeRoundedHome03,
    ),
    const _NavItem(
      label: 'Productos',
      icon: HugeIcons.strokeRoundedShoppingBag01,
    ),
    const _NavItem(
      label: 'Predicción',
      icon: HugeIcons.strokeRoundedAnalytics02,
    ),
    const _NavItem(
      label: 'Perfil',
      icon: HugeIcons.strokeRoundedUser02,
    ),
  ];

  // ==========================================================================
  // LOGICA DE DETECCION DE RUTA
  // ==========================================================================
  int _getCurrentIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    
    if (path.startsWith('/dashboard')) return 0;
    if (path.startsWith('/products')) return 1;
    if (path.startsWith('/prediction')) return 2;
    if (path.startsWith('/profile') || 
        path.startsWith('/edit-profile') || 
        path.startsWith('/account-details')) return 3;
    
    return 0; 
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;
    final activeIndex = _getCurrentIndex(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32 * s)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brownDark.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_items.length, (index) {
              final isSelected = activeIndex == index;

              return _NavBarItem(
                item: _items[index],
                isSelected: isSelected,
                s: s,
                onTap: () {
                  HapticFeedback.selectionClick();
                  
                  if (index == 0) context.go('/dashboard');
                  if (index == 1) context.go('/products');
                  if (index == 2) context.go('/prediction');
                  if (index == 3) context.go('/profile');
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MODELO DE DATOS PARA LOS ITEMS
// ============================================================================
class _NavItem {
  final String label;
  final List<List<dynamic>> icon;

  const _NavItem({
    required this.label,
    required this.icon,
  });
}

// ============================================================================
// WIDGET INDIVIDUAL (PILDORA EXPANDIBLE)
// ============================================================================
class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final double s;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.s,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 * s : 12 * s,
          vertical: 10 * s,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldLight.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(30 * s),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              // Usamos el mismo ícono siempre
              icon: item.icon,
              // El color cambia: café oscuro si está activo, gris suave si no.
              color: isSelected ? AppColors.brownDark : AppColors.muted,
              size: 24 * s,
              // El grosor del trazo aumenta ligeramente cuando está activo para dar sensación de "peso".
              strokeWidth: isSelected ? 2.4 : 1.8,
            ),
            
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Row(
                      children: [
                        SizedBox(width: 8 * s),
                        Text(
                          item.label,
                          style: AppFonts.style(
                            size: 14 * s,
                            weight: FontWeight.w700,
                            color: AppColors.brownDark,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}