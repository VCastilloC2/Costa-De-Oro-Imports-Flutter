// RAMA: feature/Profile
// ============================================================================
// PANTALLA: AccountDetailsPage
// ============================================================================
// Vista de solo lectura de la cuenta del usuario. Se han optimizado los
// espacios verticales para evitar scroll innecesario y mejorar la densidad
// de la información en pantalla.
// ============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../profile_rules.dart';
import '../widget/credential_card.dart';
import '../widget/profile_hero.dart' show kProfileAvatarHeroTag;

void _editField(BuildContext context, String field) =>
    context.push('/edit-profile?campo=$field');

class AccountDetailsPage extends ConsumerWidget {
  const AccountDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 16 * s),
          child: IconButton(
            tooltip: 'Volver',
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AppColors.brownDark,
              size: 20,
              strokeWidth: 2.0,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              shape: const CircleBorder(),
            ),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Detalles de la cuenta',
          style: AppFonts.style(
            size: 20 * s,
            weight: FontWeight.w700,
            color: AppColors.brownDark,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.push('/edit-profile'),
            child: Text(
              'Editar',
              style: AppFonts.style(
                size: 16 * s,
                weight: FontWeight.w600,
                color: AppColors.goldDark,
              ),
            ),
          ),
          SizedBox(width: 8 * s),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1),
            radius: 1.0,
            colors: [
              AppColors.goldLight.withValues(alpha: 0.42),
              Colors.transparent,
            ],
          ),
        ),
        child: ResponsiveLayout(
          useSafeArea: true,
          useScrollView: true,
          child: Padding(
            // REDUJIMOS EL MARGEN SUPERIOR PARA QUE EL CONTENIDO SUBA
            padding: EdgeInsets.fromLTRB(20 * s, kToolbarHeight + 8 * s, 20 * s, 20 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Reveal(
                  order: 0,
                  child: _ProfileHeader(
                    s: s,
                    imageUrl: user?.imagen,
                    initials: user?.initials ?? 'U',
                    fullName: displayName.isEmpty ? 'Cliente' : displayName,
                    email: user?.correo ?? 'correo@ejemplo.com',
                    progress: progress,
                    remaining: remaining,
                    onTapProgress: () => context.push('/edit-profile'),
                  ),
                ),
                // REDUJIMOS EL ESPACIO DE 24 A 16
                SizedBox(height: 16 * s),

                _Reveal(
                  order: 1,
                  child: CredentialCard(
                    name: displayName,
                    initials: user?.initials ?? 'U',
                    progress: progress,
                    documentType: documentType,
                    documentNumber: documentNumber,
                    maskNumber: true,
                    onTap: () => _editField(context, 'documento'),
                  ),
                ),
                // REDUJIMOS EL ESPACIO DE 20 A 16
                SizedBox(height: 16 * s),

                if (remaining > 0) ...[
                  _Reveal(
                    order: 2,
                    child: _CompletionBanner(
                      s: s,
                      remaining: remaining,
                      onTap: () => context.push('/edit-profile'),
                    ),
                  ),
                  // REDUJIMOS EL ESPACIO DE 24 A 20
                  SizedBox(height: 20 * s),
                ],

                _Reveal(
                  order: 3,
                  child: _Section(
                    s: s,
                    title: 'Contacto y envío',
                    rows: [
                      _InfoRow(
                        s: s,
                        icon: HugeIcons.strokeRoundedSmartPhone01,
                        label: 'Teléfono',
                        value: phone,
                        onTap: () => _editField(context, 'telefono'),
                      ),
                      _InfoRow(
                        s: s,
                        icon: HugeIcons.strokeRoundedLocation01,
                        label: 'Dirección de envío',
                        value: address,
                        onTap: () => _editField(context, 'direccion'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20 * s),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// COMPONENTES PRIVADOS (El resto del archivo queda exactamente igual)
// ============================================================================

class _Reveal extends StatelessWidget {
  const _Reveal({required this.order, required this.child});
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: reduce ? Duration.zero : Duration(milliseconds: 420 + order * 140),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.s,
    required this.imageUrl,
    required this.initials,
    required this.fullName,
    required this.email,
    required this.progress,
    required this.remaining,
    required this.onTapProgress,
  });

  final double s;
  final String? imageUrl;
  final String initials;
  final String fullName;
  final String email;
  final double progress;
  final int remaining;
  final VoidCallback onTapProgress;

  @override
  Widget build(BuildContext context) {
    final avatarSize = 100 * s; // Ligeramente reducido para ganar espacio
    final arcSize = avatarSize + 20 * s;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    final initialsText = Text(
      initials,
      style: AppFonts.style(size: 34 * s, weight: FontWeight.w700, color: AppColors.brownDark),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20 * s, 4 * s, 20 * s, 0),
      child: Column(
        children: [
          SizedBox(
            width: arcSize,
            height: arcSize,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CustomPaint(
                      painter: _ArcPainter(progress: value, stroke: 4.0 * s),
                    ),
                  ),
                ),
                Hero(
                  tag: kProfileAvatarHeroTag,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      padding: EdgeInsets.all(3.0 * s),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.goldLight, AppColors.goldDark],
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.beige,
                          border: Border.all(color: Colors.white, width: 2.5 * s),
                        ),
                        alignment: Alignment.center,
                        child: hasImage
                            ? ClipOval(
                                child: Image.network(
                                  imageUrl!,
                                  width: avatarSize,
                                  height: avatarSize,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => initialsText,
                                ),
                              )
                            : initialsText,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 4 * s,
                  bottom: 4 * s,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('La foto de perfil estará disponible pronto.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    },
                    child: Container(
                      padding: EdgeInsets.all(6 * s),
                      decoration: BoxDecoration(
                        color: AppColors.brownDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5 * s),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCamera01,
                        color: Colors.white,
                        size: 14 * s,
                        strokeWidth: 2.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8 * s), // Espacio reducido
          Text(
            fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.style(size: 20 * s, weight: FontWeight.w800, color: AppColors.brownDark),
          ),
          SizedBox(height: 2 * s),
          Text(
            email,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.style(size: 13 * s, weight: FontWeight.w500, color: AppColors.muted),
          ),
          SizedBox(height: 10 * s), // Espacio reducido
          _ProgressPill(
            s: s,
            progress: progress,
            complete: remaining == 0,
            onTap: onTapProgress,
          ),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({
    required this.s,
    required this.progress,
    required this.complete,
    required this.onTap,
  });

  final double s;
  final double progress;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = StadiumBorder(
      side: BorderSide(color: AppColors.goldDark.withValues(alpha: 0.45)),
    );

    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: complete
                    ? HugeIcons.strokeRoundedCheckmarkBadge01
                    : HugeIcons.strokeRoundedTimer01,
                size: 15 * s,
                color: AppColors.goldDark,
                strokeWidth: 2.0,
              ),
              SizedBox(width: 6 * s),
              Text(
                complete ? 'Perfil completo' : 'Perfil al ${(progress * 100).round()}%',
                style: AppFonts.style(size: 12 * s, weight: FontWeight.w700, color: AppColors.brown),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.progress, required this.stroke});

  final double progress;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.beige.withValues(alpha: 0.7),
    );

    if (progress <= 0) return;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = AppColors.goldDark,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.progress != progress || old.stroke != stroke;
}

class _Section extends StatelessWidget {
  const _Section({required this.s, required this.title, required this.rows});

  final double s;
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(const Divider(height: 1, thickness: 1, color: Color(0xFFF2ECE2)));
      }
      children.add(rows[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4 * s),
          child: Row(
            children: [
              Container(
                width: 4 * s,
                height: 14 * s,
                decoration: BoxDecoration(
                  color: AppColors.goldDark,
                  borderRadius: BorderRadius.circular(4 * s),
                ),
              ),
              SizedBox(width: 8 * s),
              Text(
                title,
                style: AppFonts.style(size: 13 * s, weight: FontWeight.w700, color: AppColors.brown),
              ),
            ],
          ),
        ),
        SizedBox(height: 8 * s), // Espacio reducido
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20 * s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20 * s),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(width: double.infinity, child: Column(children: children)),
          ),
        ),
      ],
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner({
    required this.s,
    required this.remaining,
    required this.onTap,
  });

  final double s;
  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20 * s),
      side: BorderSide(color: AppColors.goldDark.withValues(alpha: 0.45)),
    );
    final text = remaining == 1
        ? 'Te falta 1 dato para gestionar tus envíos y tu facturación.'
        : 'Te faltan $remaining datos para gestionar tus envíos y tu facturación.';

    return Material(
      color: AppColors.goldLight.withValues(alpha: 0.2),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14 * s),
          child: Row(
            children: [
              Container(
                width: 38 * s,
                height: 38 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brownDark,
                  borderRadius: BorderRadius.circular(12 * s),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedPencilEdit02,
                  size: 20 * s,
                  color: AppColors.goldLight,
                  strokeWidth: 2.0,
                ),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completa tu credencial',
                      style: AppFonts.style(
                        size: 14.5 * s,
                        weight: FontWeight.w800,
                        color: AppColors.brownDark,
                      ),
                    ),
                    SizedBox(height: 2 * s),
                    Text(
                      text,
                      style: AppFonts.style(
                        size: 12 * s,
                        weight: FontWeight.w500,
                        color: AppColors.brown.withValues(alpha: 0.85),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 22 * s,
                color: AppColors.brown,
                strokeWidth: 2.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.s,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final double s;
  final List<List<dynamic>> icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      splashColor: AppColors.goldLight.withValues(alpha: 0.25),
      highlightColor: AppColors.goldLight.withValues(alpha: 0.12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
        child: Row(
          children: [
            Container(
              width: 34 * s,
              height: 34 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.beige.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10 * s),
              ),
              child: HugeIcon(
                icon: icon,
                color: AppColors.brown,
                size: 18 * s,
                strokeWidth: 2.0,
              ),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppFonts.style(
                      size: 12 * s,
                      weight: FontWeight.w500,
                      color: AppColors.brown.withValues(alpha: 0.78),
                    ),
                  ),
                  SizedBox(height: 2 * s),
                  Text(
                    hasValue ? value! : 'Sin registrar',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.style(
                      size: 14.5 * s,
                      weight: hasValue ? FontWeight.w600 : FontWeight.w500,
                      color: hasValue ? AppColors.brownDark : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8 * s),
            if (hasValue)
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18 * s,
                color: AppColors.brown.withValues(alpha: 0.45),
                strokeWidth: 2.0,
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
                decoration: BoxDecoration(
                  color: AppColors.goldLight.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16 * s),
                  border: Border.all(color: AppColors.goldDark.withValues(alpha: 0.55)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      size: 12 * s,
                      color: AppColors.brown,
                      strokeWidth: 2.0,
                    ),
                    SizedBox(width: 4 * s),
                    Text(
                      'Agregar',
                      style: AppFonts.style(
                        size: 12 * s,
                        weight: FontWeight.w700,
                        color: AppColors.brown,
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
}