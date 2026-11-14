// RAMA: chore/Core
// ============================================================================
// WIDGET: AppBottomNavBar
// ============================================================================
// Barra de navegacion inferior estilo "pildora expandible".
// Detecta automaticamente la ruta actual para iluminar el boton correcto
// y maneja la navegacion internamente usando GoRouter.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';

class AppBottomNavBar extends StatelessWidget {
  // Ya no recibe parametros, la barra es autonoma.
  const AppBottomNavBar({super.key});

  // Definicion de los modulos principales
  static final List<_NavItem> _items = [
    const _NavItem(
      label: 'Inicio',
      icon: HugeIcons.strokeRoundedHome01,
      activeIcon: HugeIcons.strokeRoundedHome04,
    ),
    const _NavItem(
      label: 'Buscar',
      icon: HugeIcons.strokeRoundedSearch01,
      activeIcon: HugeIcons.strokeRoundedSearch01,
    ),
    const _NavItem(
      label: 'Productos',
      icon: HugeIcons.strokeRoundedShoppingBag01,
      activeIcon: HugeIcons.strokeRoundedShoppingBag02,
    ),
    const _NavItem(
      label: 'Perfil',
      icon: HugeIcons.strokeRoundedUser,
      activeIcon: HugeIcons.strokeRoundedUserCircle,
    ),
    const _NavItem(
      label: 'Mas',
      icon: HugeIcons.strokeRoundedMenu01,
      activeIcon: HugeIcons.strokeRoundedMenu01,
    ),
  ];

  // ==========================================================================
  // LOGICA DE DETECCION DE RUTA
  // ==========================================================================
  // Lee la URL actual y retorna el indice del boton que debe iluminarse.
  int _getCurrentIndex(BuildContext context) {
    // Obtenemos la ruta actual desde GoRouter
    final path = GoRouterState.of(context).uri.path;
    
    // Evaluamos la ruta y retornamos el indice correspondiente
    if (path.startsWith('/dashboard')) return 0;
    if (path.startsWith('/search')) return 1;
    if (path.startsWith('/products') || path.startsWith('/orders')) return 2;
    if (path.startsWith('/profile') || path.startsWith('/edit-profile') || path.startsWith('/account-details')) return 3;
    
    // Por defecto, si no coincide con ninguna, iluminamos Inicio
    return 0; 
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;
    // Obtenemos el indice activo basado en la URL
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
              final isMore = index == 4;

              return _NavBarItem(
                item: _items[index],
                isSelected: isSelected,
                s: s,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (isMore) {
                    _showMoreMenu(context, s);
                  } else {
                    // NAVEGACION DIRECTA
                    if (index == 0) context.go('/dashboard');
                    if (index == 1) { /* TODO: context.go('/search') */ }
                    if (index == 2) context.go('/products');
                    if (index == 3) context.go('/profile');
                  }
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // MENU DESPLEGABLE (MODULOS DE ADMINISTRACION)
  // ==========================================================================
  void _showMoreMenu(BuildContext context, double s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Container(
          padding: EdgeInsets.all(24 * s),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F6F0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32 * s)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40 * s,
                  height: 4 * s,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 24 * s),
              
              Text(
                'Modulos de Administracion',
                style: AppFonts.style(size: 20 * s, weight: FontWeight.w700, color: AppColors.brownDark),
              ),
              SizedBox(height: 16 * s),
              
              _buildMenuItem(
                context: bottomSheetContext,
                icon: HugeIcons.strokeRoundedShoppingBag01,
                title: 'Productos',
                subtitle: 'Gestiona el inventario de licores',
                route: '/products',
                s: s,
              ),
              SizedBox(height: 8 * s),
              _buildMenuItem(
                context: bottomSheetContext,
                icon: HugeIcons.strokeRoundedInvoice01,
                title: 'Compras',
                subtitle: 'Revisa el historial de pedidos',
                route: '/orders',
                s: s,
              ),
              SizedBox(height: 8 * s),
              _buildMenuItem(
                context: bottomSheetContext,
                icon: HugeIcons.strokeRoundedUserGroup,
                title: 'Clientes',
                subtitle: 'Directorio de usuarios registrados',
                route: '/clients',
                s: s,
              ),
              
              SizedBox(height: 24 * s),
              Divider(color: Colors.grey.shade300),
              SizedBox(height: 16 * s),
              
              _buildMenuItem(
                context: bottomSheetContext,
                icon: HugeIcons.strokeRoundedSettings01,
                title: 'Configuracion',
                subtitle: 'Preferencias de la app',
                route: '/settings',
                s: s,
              ),
              SizedBox(height: 24 * s),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required List<List<dynamic>> icon,
    required String title,
    required String subtitle,
    required String route,
    required double s,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Cierra el BottomSheet
        context.push(route); // Navega a la ruta seleccionada
      },
      borderRadius: BorderRadius.circular(16 * s),
      child: Container(
        padding: EdgeInsets.all(16 * s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * s),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            HugeIcon(icon: icon, color: AppColors.brownDark, size: 24 * s),
            SizedBox(width: 16 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppFonts.style(size: 15 * s, weight: FontWeight.w600, color: AppColors.brownDark)),
                  SizedBox(height: 2 * s),
                  Text(subtitle, style: AppFonts.style(size: 12 * s, weight: FontWeight.w400, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.muted),
          ],
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
  final List<List<dynamic>> activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
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
              icon: isSelected ? item.activeIcon : item.icon,
              color: isSelected ? AppColors.brownDark : AppColors.muted,
              size: 24 * s,
              strokeWidth: isSelected ? 2.2 : 1.5,
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