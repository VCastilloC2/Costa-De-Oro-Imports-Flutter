// RAMA: feature/Passkeys
// ============================================================================
// PANTALLA: PasskeysPage
// ============================================================================
// Gestiona las passkeys de la cuenta contra el backend FastAPI:
//  - Lista:   GET    /api/v1/auth/passkey/credentials
//  - Agregar: register/start + register/finish (vía PasskeyEnrollment)
//  - Revocar: DELETE /api/v1/auth/passkey/credentials/{passkey_id}
// La passkey de este dispositivo se marca para que el usuario sepa cuál deja
// de funcionar aquí si la revoca.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/models/passkey_credential.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/widgets/passkey_widgets.dart';

/// ID de la passkey de este dispositivo (para la etiqueta "Este dispositivo").
final _devicePasskeyIdProvider = FutureProvider.autoDispose<String?>(
  (ref) => ref.read(sessionStorageProvider).readPasskeyCredentialId(),
);

class PasskeysPage extends ConsumerWidget {
  const PasskeysPage({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(myPasskeysProvider);
    ref.invalidate(_devicePasskeyIdProvider);
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    if (await PasskeyEnrollment.enroll(context, ref)) _refresh(ref);
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    PasskeyCredential passkey,
    bool isThisDevice,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text(
          '¿Eliminar esta passkey?',
          style: AppFonts.style(
            size: 19,
            weight: FontWeight.w700,
            color: AppColors.brownDark,
          ),
        ),
        content: Text(
          isThisDevice
              ? 'Ya no podrás entrar con ${passkeyBiometricLabel()} en este '
                    'dispositivo. Podrás volver a activarla cuando quieras.'
              : 'El dispositivo "${passkey.displayName}" ya no podrá iniciar '
                    'sesión con esta passkey.',
          style: AppFonts.style(size: 15, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('passkey-revoke-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).revokePasskey(passkey);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Passkey eliminada.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _refresh(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passkeys = ref.watch(myPasskeysProvider);
    final deviceId = ref.watch(_devicePasskeyIdProvider).value;
    final available = ref.watch(passkeyAvailableProvider).value == true;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.brownDark,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Passkeys y biometría',
          style: AppFonts.style(
            size: 20,
            weight: FontWeight.w700,
            color: AppColors.brownDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.goldDark,
          onRefresh: () async {
            _refresh(ref);
            await ref
                .read(myPasskeysProvider.future)
                .catchError((_) => <PasskeyCredential>[]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _IntroCard(
                available: available,
                onAdd: available ? () => _add(context, ref) : null,
              ),
              const SizedBox(height: 20),
              ...passkeys.when(
                loading: () => const [
                  Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.goldDark,
                      ),
                    ),
                  ),
                ],
                error: (error, _) => [
                  ErrorStateWidget(
                    message: error is ApiException
                        ? error.message
                        : 'No pudimos cargar tus passkeys.',
                    onAction: () => _refresh(ref),
                  ),
                ],
                data: (items) => items.isEmpty
                    ? [const _EmptyState()]
                    : [
                        for (final passkey in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PasskeyTile(
                              passkey: passkey,
                              isThisDevice:
                                  deviceId != null &&
                                  deviceId.replaceAll('=', '') ==
                                      passkey.credentialId.replaceAll('=', ''),
                              onRevoke: (isThisDevice) =>
                                  _revoke(context, ref, passkey, isThisDevice),
                            ),
                          ),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.available, required this.onAdd});

  final bool available;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(passkeyBiometricIcon(), color: AppColors.goldDark, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Entra sin contraseña',
                  style: AppFonts.style(
                    size: 18,
                    weight: FontWeight.w700,
                    color: AppColors.brownDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Con una passkey inicias sesión con ${passkeyBiometricLabel()}. '
            'Tus datos biométricos nunca salen del teléfono.',
            style: AppFonts.style(size: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              key: const Key('passkey-add-button'),
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, color: AppColors.creamText),
              label: Text(
                available
                    ? 'Agregar en este dispositivo'
                    : 'No disponible en este dispositivo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  size: 16,
                  weight: FontWeight.w600,
                  color: AppColors.creamText,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brownDark,
                disabledBackgroundColor: AppColors.muted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasskeyTile extends StatelessWidget {
  const _PasskeyTile({
    required this.passkey,
    required this.isThisDevice,
    required this.onRevoke,
  });

  final PasskeyCredential passkey;
  final bool isThisDevice;
  final void Function(bool isThisDevice) onRevoke;

  static String _date(DateTime? value) =>
      value == null ? '—' : DateFormat('dd/MM/yyyy').format(value.toLocal());

  @override
  Widget build(BuildContext context) {
    final details = [
      'Creada: ${_date(passkey.createdAt)}',
      'Último uso: ${passkey.lastUsedAt == null ? 'nunca' : _date(passkey.lastUsedAt)}',
      if (passkey.backedUp) 'Sincronizada (iCloud / Google)',
    ];
    return Container(
      key: Key('passkey-tile-${passkey.id}'),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isThisDevice ? AppColors.gold : AppColors.border,
          width: isThisDevice ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.key_rounded, color: AppColors.goldDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      passkey.displayName,
                      style: AppFonts.style(
                        size: 16,
                        weight: FontWeight.w700,
                        color: AppColors.brownDark,
                      ),
                    ),
                    if (isThisDevice)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.creamDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Este dispositivo',
                          style: AppFonts.style(
                            size: 12,
                            weight: FontWeight.w600,
                            color: AppColors.caramel,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                for (final line in details)
                  Text(
                    line,
                    style: AppFonts.style(size: 13, color: AppColors.muted),
                  ),
              ],
            ),
          ),
          IconButton(
            key: Key('passkey-revoke-${passkey.id}'),
            tooltip: 'Eliminar passkey',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            onPressed: () => onRevoke(isThisDevice),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.key_off_rounded, size: 48, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            'Aún no tienes passkeys.',
            textAlign: TextAlign.center,
            style: AppFonts.style(
              size: 15,
              weight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
