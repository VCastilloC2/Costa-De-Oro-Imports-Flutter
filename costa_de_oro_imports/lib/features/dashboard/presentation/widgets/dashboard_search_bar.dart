// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: DashboardSearchBar
// ============================================================================
// Barra de búsqueda del Dashboard. Por decisión de diseño y UX, este widget
// NO es un TextField, sino un GestureDetector que simula serlo.
// Esto evita por completo el bug de que el teclado del teléfono se abra
// automáticamente al entrar a la pantalla.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';

class DashboardSearchBar extends StatelessWidget {
  final double s;

  const DashboardSearchBar({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Reemplazar por context.push('/search') cuando exista la pantalla.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Búsqueda próximamente'), behavior: SnackBarBehavior.floating),
        );
      },
      child: Container(
        height: 46 * s,
        padding: EdgeInsets.symmetric(horizontal: 16 * s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12 * s),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: AppColors.muted, size: 20 * s, strokeWidth: 2.0),
            SizedBox(width: 12 * s),
            Text('Buscar...', style: AppFonts.style(size: 14 * s, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}