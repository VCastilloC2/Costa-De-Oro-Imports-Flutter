// RAMA: chore/Core
// ============================================================================
// WIDGET: AppBottomNavBar
// ============================================================================
// Barra de navegación inferior estilo "píldora expandible".
// El ítem seleccionado se expande mostrando su icono relleno y texto.
// Los ítems inactivos se muestran compactos con iconos de línea fina.
// Utiliza iconos de Hugeicons y un BottomSheet para las opciones secundarias.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Lista de iconos con el tipo de dato correcto para Hugeicons
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
      label: 'Análisis',
      icon: HugeIcons.strokeRoundedAnalytics01,
      activeIcon: HugeIcons.strokeRoundedAnalytics02,
    ),
    const _NavItem(
      label: 'Perfil',
      icon: HugeIcons.strokeRoundedUser,
      activeIcon: HugeIcons.strokeRoundedUserCircle,
    ),
    const _NavItem(
      label: 'Más',
      icon: HugeIcons.strokeRoundedMenu01,
      activeIcon: HugeIcons.strokeRoundedMenu01,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_items.length, (index) {
              final isSelected = currentIndex == index;
              final isMore = index == 4;

              return _NavBarItem(
                item: _items[index],
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (isMore) {
                    _showMoreMenu(context);
                  } else {
                    onTap(index);
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
  // MENÚ DESPLEGABLE (MÁS OPCIONES)
  // ==========================================================================
  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Más opciones',
                style: AppFonts.style(
                  size: 20,
                  weight: FontWeight.w700,
                  color: AppColors.brownDark,
                ),
              ),
              SizedBox(height: 16),
              _buildMenuItem(
                context: bottomSheetContext,
                icon: HugeIcons.strokeRoundedSettings01,
                title: 'Configuración',
                subtitle: 'Preferencias de la app',
                onTap: () => Navigator.pop(bottomSheetContext),
              ),
              SizedBox(height: 8),
              _buildMenuItem(
                context: bottomSheetContext,
                icon: HugeIcons.strokeRoundedHelpCircle,
                title: 'Ayuda y Soporte',
                subtitle: 'Preguntas frecuentes',
                onTap: () => Navigator.pop(bottomSheetContext),
              ),
              SizedBox(height: 8),
              _buildMenuItem(
                context: bottomSheetContext,
                icon: HugeIcons.strokeRoundedLogout01,
                title: 'Cerrar sesión',
                subtitle: 'Salir de tu cuenta',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  // Al quedar sin sesión, el router lleva al login solo.
                  ProviderScope.containerOf(context)
                      .read(authControllerProvider.notifier)
                      .logout();
                },
                isDestructive: true,
              ),
              SizedBox(height: 24),
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
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.brownDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            HugeIcon(icon: icon, color: color, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.style(
                      size: 15,
                      weight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppFonts.style(
                      size: 12,
                      weight: FontWeight.w400,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MODELO DE DATOS PARA LOS ÍTEMS
// ============================================================================
class _NavItem {
  final String label;
  // Tipo correcto para Hugeicons
  final List<List<dynamic>> icon;
  final List<List<dynamic>> activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

// ============================================================================
// WIDGET INDIVIDUAL (PÍLDORA EXPANDIBLE)
// ============================================================================
class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
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
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          // Color de fondo de la píldora cuando está seleccionado
          color: isSelected
              ? AppColors.goldLight.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono (cambia a activo si está seleccionado)
            HugeIcon(
              icon: isSelected ? item.activeIcon : item.icon,
              color: isSelected ? AppColors.brownDark : AppColors.muted,
              size: 24,
              strokeWidth: isSelected ? 2.2 : 1.5,
            ),

            // Texto animado (solo aparece si está seleccionado)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Row(
                      children: [
                        SizedBox(width: 8),
                        Text(
                          item.label,
                          style: AppFonts.style(
                            size: 14,
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
