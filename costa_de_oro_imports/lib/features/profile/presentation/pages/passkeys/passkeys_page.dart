import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/storage/session_storage.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../auth/data/auth_repository.dart';
import '../../../../auth/data/biometric_mode.dart';
import '../../../../auth/data/biometric_prefs.dart';
import '../../../../auth/presentation/providers/auth_controller.dart';
import '../../widget/passkeys/passkeys_skeleton.dart';
import '../../widget/passkeys/device_card.dart';
import '../../widget/passkeys/empty_state.dart';
import '../../widget/passkeys/passkeys_shared.dart';
import '../../widget/passkeys/security_hero.dart';

// ============================================================================
// Seguridad y acceso. El esquema lo decide kUsePasskeys (biometric_mode.dart):
//   false -> huella local (local_auth): un solo teléfono.
//   true  -> passkeys (WebAuthn): varios dispositivos.
// ============================================================================

class PasskeysPage extends ConsumerStatefulWidget {
  const PasskeysPage({super.key});

  @override
  ConsumerState<PasskeysPage> createState() => _PasskeysPageState();
}

class _PasskeysPageState extends ConsumerState<PasskeysPage>
    with SingleTickerProviderStateMixin {
  List<PasskeyCredential> _credentials = const [];
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

  /// Passkeys: 1, 2 o 3 según cuántas llaves. Huella local: 1 (sin activar)
  /// o 3 (activa, anillo completo).
  int get _level {
    if (_credentials.isEmpty) return 1;
    if (!kUsePasskeys) return 3;
    return _credentials.length == 1 ? 2 : 3;
  }

  /// Este teléfono, representado con el mismo modelo que usa DeviceCard.
  static const PasskeyCredential _thisPhone = PasskeyCredential(
    passkeyId: 0,
    deviceName: 'Este teléfono',
    deviceType: 'single_device',
    backedUp: false,
  );

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() { _loading = true; _error = null; });
    }
    try {
      final prefs = BiometricPrefs.instance;
      List<PasskeyCredential> list;

      if (kUsePasskeys) {
        list = await ref.read(authControllerProvider.notifier).listPasskeys();
        if (list.isEmpty && prefs.hasPasskey) await prefs.markDisabled();
        if (list.isNotEmpty && !prefs.hasPasskey) await prefs.markEnabled();
      } else {
        final deviceId =
            await ref.read(sessionStorageProvider).readBiometricDeviceId();
        // Mantiene sincronizado el flag con lo que realmente hay guardado.
        if (deviceId == null && prefs.hasPasskey) await prefs.markDisabled();
        if (deviceId != null && !prefs.hasPasskey) await prefs.markEnabled();
        list = deviceId == null ? const [] : const [_thisPhone];
      }

      if (mounted) {
        setState(() {
          _credentials = list;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No pudimos cargar tus dispositivos.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isCancel(ApiException e) => e.message.toLowerCase().contains('cancel');

  Future<void> _register() async {
    if (_working) return;
    if (!kUsePasskeys && _credentials.isNotEmpty) {
      _message('Este teléfono ya tiene la huella activada.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _working = true);
    try {
      if (kUsePasskeys) {
        await ref.read(authControllerProvider.notifier).registerPasskey();
      } else {
        await ref.read(authControllerProvider.notifier).registerBiometric();
      }
      await BiometricPrefs.instance.markEnabled();
      HapticFeedback.heavyImpact();
      if (mounted) {
        _pulse.forward(from: 0);
        _message(kUsePasskeys ? '¡Listo! Tu llave de acceso quedó activa.' : '¡Listo! Tu huella quedó activa en este teléfono.');
      }
      await _load(silent: true);
    } on ApiException catch (e) {
      if (mounted && !_isCancel(e)) _message(e.message, isError: true);
    } catch (_) {
      if (mounted) _message('No pudimos activar la huella. Inténtalo de nuevo.', isError: true);
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
        isLast: !kUsePasskeys || _credentials.length == 1,
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _working = true);
    try {
      if (kUsePasskeys) {
        await ref
            .read(authControllerProvider.notifier)
            .revokePasskey(credential.passkeyId);
        if (mounted) _message('Dispositivo eliminado.');
      } else {
        await ref.read(sessionStorageProvider).clearBiometricCredential();
        await BiometricPrefs.instance.markDisabled();
        if (mounted) _message('Huella desactivada en este teléfono.');
      }
      await _load(silent: true);
    } on ApiException catch (e) {
      if (mounted) _message(e.message, isError: true);
    } catch (_) {
      if (mounted) _message('No pudimos desactivarla. Inténtalo de nuevo.', isError: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, style: AppFonts.style(size: 14, weight: FontWeight.w500, color: Colors.white)),
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
        title: Text('Seguridad y acceso', style: AppFonts.style(size: 20 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
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
                    // Con huella local ya activa no hay nada más que añadir.
                    onActivate: (!kUsePasskeys && _credentials.isNotEmpty)
                        ? null
                        : _register,
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