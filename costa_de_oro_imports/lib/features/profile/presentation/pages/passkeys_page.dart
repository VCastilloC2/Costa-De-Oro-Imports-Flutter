import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

class PasskeysPage extends ConsumerStatefulWidget {
  const PasskeysPage({super.key});

  @override
  ConsumerState<PasskeysPage> createState() => _PasskeysPageState();
}

class _PasskeysPageState extends ConsumerState<PasskeysPage> {
  List<PasskeyCredential> _credentials = const [];
  bool _loading = true;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final credentials = await ref
          .read(authControllerProvider.notifier)
          .listPasskeys();
      if (mounted) setState(() => _credentials = credentials);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    setState(() => _working = true);
    try {
      await ref.read(authControllerProvider.notifier).registerPasskey();
      if (mounted) {
        _message('Passkey registrada correctamente.');
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        _message(e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        _message('No se pudo registrar la Passkey: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _revoke(PasskeyCredential credential) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Passkey'),
        content: Text(
          '¿Quieres revocar "${credential.deviceName ?? 'este dispositivo'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _working = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .revokePasskey(credential.passkeyId);
      if (mounted) {
        _message('Passkey revocada.');
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        _message(e.message, isError: true);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: isError ? Colors.red.shade700 : AppColors.brownDark,
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.brownDark,
      title: Text(
        'Passkeys',
        style: AppFonts.style(
          size: 20,
          weight: FontWeight.w700,
          color: AppColors.brownDark,
        ),
      ),
    ),
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.goldDark),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.fingerprint,
                          color: AppColors.goldDark,
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Usa tu huella, rostro o PIN del dispositivo',
                          style: AppFonts.style(
                            size: 17,
                            weight: FontWeight.w700,
                            color: AppColors.brownDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Las Passkeys se sincronizan según el proveedor de credenciales configurado en cada dispositivo.',
                          style: AppFonts.style(
                            size: 14,
                            weight: FontWeight.w400,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _working ? null : _register,
                            icon: const Icon(Icons.add),
                            label: Text(
                              _working ? 'Procesando…' : 'Registrar Passkey',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brownDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.red)),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
                const SizedBox(height: 20),
                Text(
                  'Passkeys registradas (${_credentials.length})',
                  style: AppFonts.style(
                    size: 17,
                    weight: FontWeight.w700,
                    color: AppColors.brownDark,
                  ),
                ),
                const SizedBox(height: 8),
                if (_credentials.isEmpty && _error == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Todavía no tienes Passkeys registradas.'),
                  ),
                for (final credential in _credentials)
                  Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: const Icon(
                        Icons.fingerprint,
                        color: AppColors.goldDark,
                      ),
                      title: Text(credential.deviceName ?? 'Dispositivo'),
                      subtitle: Text(
                        [
                          if (credential.deviceType != null)
                            credential.deviceType!,
                          if (credential.createdAt != null)
                            'Registrada: ${credential.createdAt}',
                          if (credential.backedUp)
                            'Sincronizada por el proveedor',
                        ].join(' · '),
                      ),
                      trailing: IconButton(
                        tooltip: 'Revocar Passkey',
                        onPressed: _working ? null : () => _revoke(credential),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );
}
