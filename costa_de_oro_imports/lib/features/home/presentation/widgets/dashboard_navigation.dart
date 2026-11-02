import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/dashboard_models.dart';

enum DashboardSection { home, products, statistics, predictions }

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.section,
    required this.profile,
    required this.onMenu,
    required this.onBack,
    super.key,
  });

  final DashboardSection section;
  final DashboardProfile? profile;
  final VoidCallback onMenu;
  final VoidCallback onBack;

  bool get _usesSearch =>
      section == DashboardSection.home ||
      section == DashboardSection.predictions;

  String get _title => switch (section) {
    DashboardSection.home => 'Panel de control',
    DashboardSection.products => 'Productos y pedidos',
    DashboardSection.statistics => 'Estadísticas',
    DashboardSection.predictions => '',
  };

  @override
  Widget build(BuildContext context) {
    final name = profile?.name.trim() ?? '';
    final initials = name.isEmpty
        ? 'CO'
        : name
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              _CircleAction(
                icon: _usesSearch
                    ? Icons.menu_rounded
                    : Icons.arrow_back_rounded,
                onPressed: _usesSearch ? onMenu : onBack,
              ),
              if (_usesSearch) ...[
                const SizedBox(width: 10),
                if (section == DashboardSection.home)
                  Expanded(
                    child: Text(
                      _title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Expanded(child: _SearchPill()),
                if (section == DashboardSection.home) ...[
                  const SizedBox(width: 8),
                  _NotificationAction(onPressed: () {}),
                  const SizedBox(width: 8),
                  _ProfileAvatar(initials: initials, image: profile?.image),
                ] else ...[
                  const SizedBox(width: 8),
                  _NotificationAction(onPressed: () {}),
                  const SizedBox(width: 8),
                  _ProfileAvatar(initials: initials, image: profile?.image),
                ],
              ] else ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ),
                _CircleAction(
                  icon: Icons.notifications_none_rounded,
                  onPressed: () {},
                ),
              ],
            ],
          ),
          if (section == DashboardSection.home) ...[
            const SizedBox(height: 12),
            const _SearchPill(),
          ],
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill();

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        const Icon(Icons.search_rounded, size: 19, color: Color(0xFF9A8264)),
        const SizedBox(width: 8),
        Text(
          'Buscar...',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: const Color(0xFF9A8264)),
        ),
      ],
    ),
  );
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onPressed,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: const Color(0xFF4B5563), size: 21),
      ),
    ),
  );
}

class _NotificationAction extends StatelessWidget {
  const _NotificationAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _CircleAction(
    icon: Icons.notifications_none_rounded,
    onPressed: onPressed,
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initials, this.image});

  final String initials;
  final String? image;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 20,
    backgroundColor: const Color(0xFFF0D5B1),
    backgroundImage: image == null || image!.isEmpty
        ? null
        : NetworkImage(image!),
    child: image != null && image!.isNotEmpty
        ? null
        : Text(
            initials,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF5A4636),
              fontWeight: FontWeight.w700,
            ),
          ),
  );
}

class DashboardBottomNavigation extends StatelessWidget {
  const DashboardBottomNavigation({
    required this.section,
    required this.onHome,
    required this.onProducts,
    required this.onPurchases,
    required this.onClients,
    required this.onPredictions,
    required this.onMore,
    super.key,
  });

  final DashboardSection section;
  final VoidCallback onHome;
  final VoidCallback onProducts;
  final VoidCallback onPurchases;
  final VoidCallback onClients;
  final VoidCallback onPredictions;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final items = section == DashboardSection.predictions
        ? [
            _NavItem('Panel', 'assets/icons/dashboard_home.svg', onHome),
            _NavItem(
              'Productos',
              'assets/icons/dashboard_cart.svg',
              onProducts,
            ),
            _NavItem('Compras', 'assets/icons/dashboard_bag.svg', onPurchases),
            _NavItem(
              'Predicciones',
              'assets/icons/dashboard_pie.svg',
              onPredictions,
            ),
            _NavItem('Más', 'assets/icons/dashboard_more.svg', onMore),
          ]
        : [
            _NavItem('Inicio', 'assets/icons/dashboard_home.svg', onHome),
            _NavItem(
              'Productos',
              'assets/icons/dashboard_cart.svg',
              onProducts,
            ),
            _NavItem('Compras', 'assets/icons/dashboard_list.svg', onPurchases),
            _NavItem('Clientes', 'assets/icons/dashboard_users.svg', onClients),
            _NavItem('Más', 'assets/icons/dashboard_more.svg', onMore),
          ];
    final selected = switch (section) {
      DashboardSection.home => 0,
      DashboardSection.products => 1,
      DashboardSection.statistics => 4,
      DashboardSection.predictions => 3,
    };

    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(
                child: _BottomNavButton(
                  item: items[index],
                  selected: selected == index,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.asset, this.onTap);
  final String label;
  final String asset;
  final VoidCallback onTap;
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({required this.item, required this.selected});

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brown : const Color(0xFF8B8B8B);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0D5B1) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              item.asset,
              width: 19,
              height: 19,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({
    required this.profile,
    required this.selectedSection,
    required this.onSelect,
    required this.onLogout,
    required this.onUnavailable,
    super.key,
  });

  final DashboardProfile? profile;
  final DashboardSection selectedSection;
  final ValueChanged<DashboardSection> onSelect;
  final VoidCallback onLogout;
  final ValueChanged<String> onUnavailable;

  @override
  Widget build(BuildContext context) {
    final name = profile?.name.isNotEmpty == true
        ? profile!.name
        : 'Administrador';
    final email = profile?.email ?? '';

    return Drawer(
      width: 304,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Text(
                      'CO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Costa de Oro',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'IMPORT',
                          style: TextStyle(
                            color: Color(0xFF8B8B8B),
                            fontSize: 10,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar menú',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: SvgPicture.asset(
                      'assets/icons/dashboard_close.svg',
                      width: 18,
                      height: 18,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _DrawerEntry(
                    label: 'Panel de control',
                    asset: 'assets/icons/dashboard_home.svg',
                    selected: selectedSection == DashboardSection.home,
                    onTap: () => _choose(context, DashboardSection.home),
                  ),
                  const _DrawerGroupTitle('Administración de tiendas'),
                  _DrawerEntry(
                    label: 'Productos',
                    asset: 'assets/icons/dashboard_cart.svg',
                    selected: selectedSection == DashboardSection.products,
                    onTap: () => _choose(context, DashboardSection.products),
                  ),
                  _DrawerEntry(
                    label: 'Categorías',
                    asset: 'assets/icons/dashboard_list.svg',
                    onTap: () => _notReady('Categorías'),
                  ),
                  _DrawerEntry(
                    label: 'Compras',
                    asset: 'assets/icons/dashboard_bag.svg',
                    onTap: () => _choose(context, DashboardSection.products),
                  ),
                  _DrawerEntry(
                    label: 'Proveedores',
                    asset: 'assets/icons/dashboard_store.svg',
                    onTap: () => _notReady('Proveedores'),
                  ),
                  _DrawerEntry(
                    label: 'Clientes',
                    asset: 'assets/icons/dashboard_users.svg',
                    onTap: () => _notReady('Clientes'),
                  ),
                  _DrawerEntry(
                    label: 'Reseñas',
                    asset: 'assets/icons/dashboard_star.svg',
                    onTap: () => _notReady('Reseñas'),
                  ),
                  _DrawerEntry(
                    label: 'Predicciones',
                    asset: 'assets/icons/dashboard_pie.svg',
                    selected: selectedSection == DashboardSection.predictions,
                    onTap: () => _choose(context, DashboardSection.predictions),
                  ),
                  const _DrawerGroupTitle('Configuración del sitio'),
                  _DrawerEntry(
                    label: 'Blog',
                    asset: 'assets/icons/dashboard_news.svg',
                    onTap: () => _notReady('Blog'),
                  ),
                  _DrawerEntry(
                    label: 'PQRS',
                    asset: 'assets/icons/dashboard_message.svg',
                    onTap: () => _notReady('PQRS'),
                  ),
                  _DrawerEntry(
                    label: 'Reportes',
                    asset: 'assets/icons/dashboard_printer.svg',
                    selected: selectedSection == DashboardSection.statistics,
                    onTap: () => _choose(context, DashboardSection.statistics),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFF0D5B1),
                    foregroundColor: AppColors.brown,
                    child: Icon(Icons.person_outline_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: onLogout,
                    icon: SvgPicture.asset(
                      'assets/icons/dashboard_logout.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _choose(BuildContext context, DashboardSection section) {
    Navigator.of(context).pop();
    onSelect(section);
  }

  void _notReady(String section) {
    onUnavailable(section);
  }
}

class _DrawerGroupTitle extends StatelessWidget {
  const _DrawerGroupTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 16, 10, 7),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

class _DrawerEntry extends StatelessWidget {
  const _DrawerEntry({
    required this.label,
    required this.asset,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final String asset;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Material(
      color: selected ? const Color(0xFFF0D5B1) : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                SvgPicture.asset(
                  asset,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF888888),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.brown : const Color(0xFF777777),
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
