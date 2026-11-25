import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/biometric_mode.dart';
import '../../../auth/data/biometric_prefs.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../widget/passkeys/passkeys_skeleton.dart';
import '../widget/passkeys/device_card.dart';
import '../widget/passkeys/empty_state.dart';
import '../widget/passkeys/passkeys_shared.dart';
import '../widget/passkeys/security_hero.dart';

// ============================================================================
// Seguridad y acceso. El esquema lo decide kUsePasskeys (biometric_mode.dart):
//   false -> huella local (local_auth) con los endpoints /auth/biometric/*:
//            register, login, GET devices y DELETE devices/{credential_id}.
//   true  -> passkeys (WebAuthn).
// ============================================================================

class PasskeysPage extends ConsumerStatefulWidget {
  const PasskeysPage({super.key});

  @override
  ConsumerState<PasskeysPage> createState() => _PasskeysPageState();
}

class _PasskeysPageState extends ConsumerState<PasskeysPage>
    with SingleTickerProviderStateMixin {
  List<PasskeyCredential> _credentials = const [];

  /// Huella local: id de la credencial de ESTE teléfono en el servidor
  /// (null si este teléfono no la tiene activa).
  int? _thisId;

  bool _loading = true;
  bool _working = false;
  String? _error;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// En huella local: ¿este teléfono ya la tiene activa?
  bool get _thisActive => _thisId != null;

  /// Passkeys: 1, 2 o 3 según cuántas llaves. Huella local: 1 (este teléfono
  /// sin activar) o 3 (activa, anillo completo).
  int get _level {
    if (kUsePasskeys) {
      if (_credentials.isEmpty) return 1;
      return _credentials.length == 1 ? 2 : 3;
    }
    return _thisActive ? 3 : 1;
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final prefs = BiometricPrefs.instance;
      final controller = ref.read(authControllerProvider.notifier);
      List<PasskeyCredential> list;
      int? thisId;

      if (kUsePasskeys) {
        list = await controller.listPasskeys();
        if (list.isEmpty && prefs.hasPasskey) await prefs.markDisabled();
        if (list.isNotEmpty && !prefs.hasPasskey) await prefs.markEnabled();
      } else {
        final storage = ref.read(sessionStorageProvider);
        final localId = await storage.readBiometricDeviceId();
        final devices = await controller.listBiometricDevices();

        final mine = <PasskeyCredential>[];
        final others = <PasskeyCredential>[];
        for (final d in devices) {
          final isThis = localId != null && d.deviceId == localId;
          if (isThis) thisId = d.credentialId;
          final card = PasskeyCredential(
            passkeyId: d.credentialId,
            deviceName: isThis
                ? 'Este teléfono · ${d.deviceName ?? 'Android'}'
                : (d.deviceName ?? 'Dispositivo'),
            deviceType: 'platform',
            backedUp: false,
            createdAt: d.createdAt,
          );
          (isThis ? mine : others).add(card);
        }
        list = [...mine, ...others];

        // El teléfono guardaba un secreto, pero el servidor ya no lo tiene
        // (se revocó desde otro lado): se limpia para no mostrar un botón roto.
        if (localId != null && thisId == null) {
          await storage.clearBiometricCredential();
        }
        if (thisId == null && prefs.hasPasskey) await prefs.markDisabled();
        if (thisId != null && !prefs.hasPasskey) await prefs.markEnabled();
      }

      if (mounted) {
        setState(() {
          _credentials = list;
          _thisId = thisId;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No pudimos cargar tus dispositivos.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isCancel(ApiException e) => e.message.toLowerCase().contains('cancel');

  Future<void> _register() async {
    if (_working) return;
    if (!kUsePasskeys && _thisActive) {
      _message('Este teléfono ya tiene la huella activada.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _working = true);
    try {
      final controller = ref.read(authControllerProvider.notifier);
      if (kUsePasskeys) {
        await controller.registerPasskey();
      } else {
        await controller.registerBiometric();
      }
      await BiometricPrefs.instance.markEnabled();
      HapticFeedback.heavyImpact();
      if (mounted) {
        _pulse.forward(from: 0);
        _message(kUsePasskeys
            ? '¡Listo! Tu llave de acceso quedó activa.'
            : '¡Listo! Tu huella quedó activa en este teléfono.');
      }
      await _load(silent: true);
    } on ApiException catch (e) {
      if (mounted && !_isCancel(e)) _message(e.message, isError: true);
    } catch (_) {
      if (mounted) {
        _message('No pudimos activar la huella. Inténtalo de nuevo.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _revoke(PasskeyCredential credential) async {
    final s = context.s;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RevokeSheet(
        s: s,
        deviceName: credential.deviceName ?? 'Este dispositivo',
        isLast: _credentials.length == 1,
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _working = true);
    try {
      final controller = ref.read(authControllerProvider.notifier);
      if (kUsePasskeys) {
        await controller.revokePasskey(credential.passkeyId);
      } else {
        // Primero se revoca en el servidor; si falla, el secreto local
        // se conserva y el usuario puede reintentar.
        await controller.revokeBiometricDevice(credential.passkeyId);
        if (credential.passkeyId == _thisId) {
          await ref.read(sessionStorageProvider).clearBiometricCredential();
          await BiometricPrefs.instance.markDisabled();
        }
      }
      if (mounted) _message('Dispositivo eliminado.');
      await _load(silent: true);
    } on ApiException catch (e) {
      if (mounted) _message(e.message, isError: true);
    } catch (_) {
      if (mounted) {
        _message('No pudimos eliminarlo. Inténtalo de nuevo.', isError: true);
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
          content: Text(text,
              style: AppFonts.style(
                  size: 14, weight: FontWeight.w500, color: Colors.white)),
          backgroundColor: isError ? Colors.red.shade800 : AppColors.brownDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_loading) return PasskeysSkeleton(s: s);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brownDark),
        centerTitle: true,
        title: Text('Seguridad y acceso',
            style: AppFonts.style(
                size: 20 * s,
                weight: FontWeight.w700,
                color: AppColors.brownDark)),
      ),
      body: RefreshIndicator(
        color: AppColors.goldDark,
        onRefresh: () => _load(silent: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20 * s, 8 * s, 20 * s, 36 * s),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SecurityHero(
                    s: s,
                    level: _level,
                    working: _working,
                    pulse: _pulse,
                    multiDevice: kUsePasskeys,
                    // Con la huella ya activa en este teléfono no hay nada
                    // más que activar.
                    onActivate: (!kUsePasskeys && _thisActive) ? null : _register,
                  ),
                  if (_error != null) ...[
                    SizedBox(height: 16 * s),
                    ErrorCard(s: s, message: _error!, onRetry: _load),
                  ],
                  SizedBox(height: 30 * s),
                  SectionHeader(s: s, count: _credentials.length),
                  SizedBox(height: 14 * s),
                  if (_credentials.isEmpty && _error == null)
                    Reveal(index: 0, child: EmptyKeys(s: s))
                  else
                    for (var i = 0; i < _credentials.length; i++)
                      Reveal(
                        index: i,
                        child: DeviceCard(
                          s: s,
                          credential: _credentials[i],
                          busy: _working,
                          showLastUse: kUsePasskeys,
                          onRevoke: () => _revoke(_credentials[i]),
                        ),
                      ),
                  if (_credentials.isNotEmpty) ...[
                    SizedBox(height: 8 * s),
                    LostPhoneNote(s: s),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}