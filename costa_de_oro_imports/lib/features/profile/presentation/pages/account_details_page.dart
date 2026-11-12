// RAMA: feature/Profile
// ============================================================================
// PANTALLA: AccountDetailsPage
// ============================================================================
// Orquestador de la vista de cuenta. Maneja el scroll, el estado de carga y 
// la transición entre el hero oscuro y la hoja clara.
// ============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../profile_rules.dart';

import '../../presentation/widget/account_details/account_details_hero.dart';
import '../../presentation/widget/account_details/account_details_skeleton.dart';
import '../../presentation/widget/account_details/account_details_top_bar.dart';
import '../../presentation/widget/profile_bento/profile_bento.dart';

const Color _kSheet = Color(0xFFF9F6F0);
const Color _kDarkA = Color(0xFF1E130C);
const Color _kDarkB = Color(0xFF3A2414);

double _heroHeight(double s, double top) => top + kToolbarHeight + 262 * s;

void _editField(BuildContext context, String field) =>
    context.push('/edit-profile?campo=$field');

class AccountDetailsPage extends ConsumerStatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  ConsumerState<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends ConsumerState<AccountDetailsPage> {
  final ScrollController _scroll = ScrollController();
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(authControllerProvider.notifier).refreshProfile();
      } finally {
        if (mounted) setState(() => _isInitialLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    // IMPORTANTE: El fondo ahora es _kSheet para que el hueco inferior
    // de la superposición sea invisible.
    return Scaffold(
      backgroundColor: _kSheet, 
      body: _isInitialLoading
          ? AccountDetailsSkeleton(s: s)
          : _buildContent(s),
    );
  }

  Widget _buildContent(double s) {
    final user = ref.watch(authControllerProvider).user;

    final nombres = ProfileRules.cleanName(user?.nombres);
    final apellidos = ProfileRules.cleanName(user?.apellidos);
    final displayName = [nombres, apellidos].whereType<String>().join(' ');

    final phoneDigits = ProfileRules.cleanPhone(user?.telefono);
    final phone = phoneDigits == null ? null : formatPhoneCo(phoneDigits);
    final address = ProfileRules.cleanAddress(user?.direccion);
    final documentType = ProfileRules.cleanText(user?.tipoIdentificacion);
    final documentNumber = ProfileRules.cleanText(user?.numeroIdentificacion);

    final done = ProfileRules.doneCount(
      nombres: user?.nombres,
      apellidos: user?.apellidos,
      tipo: user?.tipoIdentificacion,
      numero: user?.numeroIdentificacion,
      telefono: user?.telefono,
      direccion: user?.direccion,
    );
    final remaining = ProfileRules.totalFields - done;
    final progress = done / ProfileRules.totalFields;

    final pending = <String>{
      if (nombres == null || apellidos == null) 'nombres',
      if (documentType == null || documentNumber == null) 'documento',
      if (phone == null) 'telefono',
      if (address == null) 'direccion',
    };

    final top = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final heroH = _heroHeight(s, top);
    final overlap = 40 * s;

    final scrollView = CustomScrollView(
      controller: _scroll,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: AccountDetailsHero(
            s: s,
            top: top,
            height: heroH,
            scroll: _scroll,
            imageUrl: user?.imagen,
            initials: user?.initials ?? 'U',
            fullName: displayName,
            email: user?.correo ?? 'correo@ejemplo.com',
            progress: progress,
            complete: remaining == 0,
            onEditName: () => _editField(context, 'nombres'),
            onEditProfile: () => context.push('/edit-profile'),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Transform.translate(
            offset: Offset(0, -overlap),
            child: Container(
              // ELIMINAMOS EL constraints QUE CAUSABA EL SCROLL EXTRA
              decoration: BoxDecoration(
                color: _kSheet,
                borderRadius: BorderRadius.vertical(top: Radius.circular(44 * s)),
                boxShadow: [
                  BoxShadow(
                    color: _kDarkA.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(20 * s, 56 * s, 20 * s, 28 * s + bottomInset),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ProfileBento(
                    s: s,
                    documentType: documentType,
                    documentNumber: documentNumber,
                    phone: phone,
                    address: address,
                    pending: pending,
                    maskNumber: true,
                    onFieldTap: (field) => _editField(context, field),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Stack(
      children: [
        scrollView,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _scroll,
            builder: (context, _) {
              final off = _scroll.hasClients ? math.max(0.0, _scroll.offset) : 0.0;
              final collapse = heroH - overlap - (top + kToolbarHeight);
              final t = ((off - (collapse - 36 * s)) / (36 * s))
                  .clamp(0.0, 1.0)
                  .toDouble();

              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: t < 0.5
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                child: AccountDetailsTopBar(
                  s: s,
                  top: top,
                  t: t,
                  onBack: () => context.pop(),
                  onEdit: () => context.push('/edit-profile'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}