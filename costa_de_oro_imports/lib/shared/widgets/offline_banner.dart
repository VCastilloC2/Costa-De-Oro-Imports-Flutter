import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/network/network_status.dart';

/// Franja superior que avisa cuando la app no tiene conexión.
///
/// Envuelve toda la app (ver `App`), así cualquier pantalla la muestra sin
/// tener que hacer nada. Cuando hay datos guardados en pantalla, lo dice
/// para que el usuario sepa que pueden no estar al día.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);
    final offline = !status.isOnline;
    final message = status.showingCachedData
        ? 'Sin conexión · mostrando los últimos datos guardados'
        : 'Sin conexión · revisa tu Wi-Fi o datos móviles';

    final media = MediaQuery.of(context);
    return Column(
      children: [
        AnimatedSize(
          duration: AppDurations.medium,
          curve: Curves.easeOutCubic,
          child: offline
              ? Semantics(
                  liveRegion: true,
                  label: message,
                  excludeSemantics: true,
                  child: Material(
                    color: AppColors.brownDark,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        media.padding.top + AppSpacing.xs,
                        AppSpacing.md,
                        AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 18,
                            color: AppColors.goldLight,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              message,
                              style: AppFonts.style(
                                size: 12.5,
                                weight: FontWeight.w600,
                                color: AppColors.creamText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Expanded(
          // Con la franja visible, la barra de estado ya quedó cubierta:
          // las pantallas no deben volver a dejar ese espacio arriba.
          child: offline
              ? MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: child,
                )
              : child,
        ),
      ],
    );
  }
}
