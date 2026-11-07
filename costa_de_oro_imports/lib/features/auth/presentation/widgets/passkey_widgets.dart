// RAMA: feature/Passkeys
// ============================================================================
// WIDGETS: Passkeys
// ============================================================================
// - [PasskeyLoginButton]: botón "Ingresar con Face ID / huella" del login.
// - [PasskeyEnrollment]: ofrece y ejecuta el registro de una passkey
//   (tras crear la cuenta, tras un login con contraseña y desde el perfil).
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';
import '../../data/passkey_service.dart';
import '../providers/auth_controller.dart';

/// Nombre del método biométrico que el usuario reconoce en su teléfono.
String passkeyBiometricLabel() => switch (defaultTargetPlatform) {
  TargetPlatform.iOS => 'Face ID / Touch ID',
  TargetPlatform.android => 'tu huella',
  _ => 'tu passkey',
};

IconData passkeyBiometricIcon() => defaultTargetPlatform == TargetPlatform.iOS
    ? Icons.face_retouching_natural_rounded
    : Icons.fingerprint_rounded;

/// Botón secundario del login. Solo se dibuja si el dispositivo soporta
/// passkeys y `PASSKEY_RP_ID` está configurado.
class PasskeyLoginButton extends StatelessWidget {
  const PasskeyLoginButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        key: const Key('passkey-login-button'),
        onPressed: onPressed,
        icon: Icon(passkeyBiometricIcon(), color: AppColors.goldDark, size: 26),
        label: Text(
          'Ingresar con ${passkeyBiometricLabel()}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.style(
            size: 17,
            weight: FontWeight.w600,
            color: AppColors.brownDark,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.gold, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}

/// Flujo de activación de passkeys. No lanza excepciones: muestra los
/// errores en un SnackBar y devuelve `true` si la passkey quedó activa.
class PasskeyEnrollment {
  PasskeyEnrollment._();

  /// Ofrece activar la passkey si aplica (dispositivo compatible, sin
  /// passkey previa y, salvo [afterSignUp], sin rechazo anterior).
  /// Si el usuario dice "Ahora no", no se vuelve a ofrecer tras el login.
  static Future<bool> maybeOffer(
    BuildContext context,
    WidgetRef ref, {
    bool afterSignUp = false,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final bool shouldOffer;
    try {
      shouldOffer = await repo.shouldOfferPasskeyEnrollment(
        ignoreDismissed: afterSignUp,
      );
    } catch (error) {
      PasskeyService.log('offer', error);
      return false;
    }
    if (!shouldOffer || !context.mounted) return false;

    final accepted = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _PasskeyOfferSheet(),
    );

    if (accepted != true) {
      await repo.dismissPasskeyOffer();
      return false;
    }
    if (!context.mounted) return false;
    return enroll(context, ref);
  }

  /// Muestra la hoja del sistema para crear la passkey.
  static Future<bool> enroll(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    void show(String message, Color color) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }

    if (!await ref.read(authRepositoryProvider).isPasskeyAvailable()) {
      show(
        'Las passkeys no están disponibles en este dispositivo.',
        AppColors.error,
      );
      return false;
    }

    try {
      await ref.read(authControllerProvider.notifier).registerPasskey();
    } on PasskeyException catch (e) {
      if (!e.isCancelled) show(e.message, AppColors.error);
      return false;
    } on ApiException catch (e) {
      show(e.message, AppColors.error);
      return false;
    } catch (error) {
      PasskeyService.log('enroll', error);
      show('No fue posible activar la passkey.', AppColors.error);
      return false;
    }

    ref.invalidate(passkeyAvailableProvider);
    show(
      'Listo: la próxima vez entra con ${passkeyBiometricLabel()}.',
      AppColors.success,
    );
    return true;
  }
}

class _PasskeyOfferSheet extends StatelessWidget {
  const _PasskeyOfferSheet();

  @override
  Widget build(BuildContext context) {
    final label = passkeyBiometricLabel();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(passkeyBiometricIcon(), size: 56, color: AppColors.goldDark),
            const SizedBox(height: 16),
            Text(
              'Entra más rápido con $label',
              textAlign: TextAlign.center,
              style: AppFonts.style(
                size: 22,
                weight: FontWeight.w700,
                color: AppColors.brownDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una passkey: inicias sesión sin contraseña y tus datos '
              'biométricos nunca salen de tu teléfono.',
              textAlign: TextAlign.center,
              style: AppFonts.style(
                size: 15,
                weight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                key: const Key('passkey-offer-accept'),
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brownDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Activar',
                  style: AppFonts.style(
                    size: 17,
                    weight: FontWeight.w600,
                    color: AppColors.creamText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('passkey-offer-dismiss'),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Ahora no',
                style: AppFonts.style(
                  size: 15,
                  weight: FontWeight.w600,
                  color: AppColors.goldDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
