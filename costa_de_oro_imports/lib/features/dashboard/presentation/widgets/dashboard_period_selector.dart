// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: DashboardPeriodSelector
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';

// IMPORTANTE: Verifica que esta ruta sea la correcta hacia el provider.
// Si tu carpeta se llama diferente, ajustala aqui.
import '../../presentation/widgets/dashboard_period_provider.dart';

class DashboardPeriodSelector extends ConsumerWidget {
  final double s;

  const DashboardPeriodSelector({super.key, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el estado actual
    final selected = ref.watch(dashboardPeriodProvider);

    return Container(
      padding: EdgeInsets.all(4 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(ref, 3, '3M', selected, s),
          _buildOption(ref, 6, '6M', selected, s),
          _buildOption(ref, 12, '12M', selected, s),
        ],
      ),
    );
  }

  Widget _buildOption(WidgetRef ref, int months, String label, int selected, double s) {
    final isActive = selected == months;

    return GestureDetector(
      // Aquí actualizamos el estado
      onTap: () => ref.read(dashboardPeriodProvider.notifier).state = months,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brownDark : Colors.transparent,
          borderRadius: BorderRadius.circular(8 * s),
        ),
        child: Text(
          label,
          style: AppFonts.style(
            size: 13 * s,
            weight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}