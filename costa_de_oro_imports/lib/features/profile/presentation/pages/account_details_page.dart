// RAMA: feature/Profile
// ============================================================================
// PANTALLA: AccountDetailsPage
// ============================================================================
// Vista de solo lectura con la informacion de la cuenta del usuario.
// Organiza los datos en tarjetas con etiqueta sobre valor, de modo que ningun
// texto largo pueda desbordar la fila (el valor ocupa todo el ancho y, si hace
// falta, pasa a una segunda linea). Utiliza Hugeicons y diseño responsivo.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../widget/profile_hero.dart' show kProfileAvatarHeroTag;

/// Valor que la API usa cuando el usuario no registro telefono.
const String _emptyPhone = '0000000000';

/// Abre la edicion de perfil directamente en el campo indicado.
/// [field]: nombres, apellidos, documento, telefono o direccion.
void _editField(BuildContext context, String field) =>
    context.push('/edit-profile?campo=$field');

class AccountDetailsPage extends ConsumerWidget {
  const AccountDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final user = ref.watch(authControllerProvider).user;

    // Telefono: null cuando no hay un valor util; si existe, con el mismo
    // formato que se usa al editarlo (+57 310 223 3445).
    final rawPhone = user?.telefono;
    final phone =
        (rawPhone == null || rawPhone.isEmpty || rawPhone == _emptyPhone)
            ? null
            : formatPhoneCo(rawPhone);

    // Datos reales desde el UserModel
    final address = (user?.direccion == null || user!.direccion!.isEmpty || user.direccion == 'Por definir') 
        ? null 
        : user.direccion;

    final documentType = (user?.tipoIdentificacion == null || user!.tipoIdentificacion!.isEmpty) 
        ? null 
        : user.tipoIdentificacion;

    final documentNumber = (user?.numeroIdentificacion == null || user!.numeroIdentificacion!.isEmpty) 
        ? null 
        : user.numeroIdentificacion;

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
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 380 * s,
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
              ),
            ),
          ),
          
          ResponsiveLayout(
            useSafeArea: true,
            useScrollView: true,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20 * s,
                kToolbarHeight + 12 * s,
                20 * s,
                32 * s,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Reveal(
                    order: 0,
                    child: _ProfileHeader(
                      s: s,
                      imageUrl: user?.imagen,
                      initials: user?.initials ?? 'U',
                      fullName: user?.fullName ?? 'Usuario',
                      email: user?.correo ?? 'correo@ejemplo.com',
                    ),
                  ),
                  SizedBox(height: 24 * s),

                  if (user?.isProfileIncomplete ?? false) ...[
                    _Reveal(
                      order: 1,
                      child: _CompletionBanner(
                        s: s,
                        onTap: () => context.push('/edit-profile'),
                      ),
                    ),
                    SizedBox(height: 24 * s),
                  ],

                  _Reveal(
                    order: 1,
                    child: _Section(
                      s: s,
                      title: 'Información de contacto',
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
                  SizedBox(height: 24 * s),

                  _Reveal(
                    order: 2,
                    child: _Section(
                      s: s,
                      title: 'Documento de identidad',
                      rows: [
                        _InfoRow(
                          s: s,
                          icon: HugeIcons.strokeRoundedIdentityCard,
                          label: 'Tipo de documento',
                          value: documentType,
                          onTap: () => _editField(context, 'documento'),
                        ),
                        _InfoRow(
                          s: s,
                          icon: HugeIcons.strokeRoundedHashtag,
                          label: 'Número de documento',
                          value: documentNumber == null
                              ? null
                              : maskDocument(documentNumber),
                          onTap: () => _editField(context, 'documento'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPONENTES PRIVADOS
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
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
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
  });

  final double s;
  final String? imageUrl;
  final String initials;
  final String fullName;
  final String email;

  @override
  Widget build(BuildContext context) {
    final avatarSize = 108 * s;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    final initialsText = Text(
      initials,
      style: AppFonts.style(size: 38 * s, weight: FontWeight.w700, color: AppColors.brownDark),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20 * s, 8 * s, 20 * s, 0),
      child: Column(
        children: [
          SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Hero(
                  tag: kProfileAvatarHeroTag,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      padding: EdgeInsets.all(3.5 * s),
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
                          border: Border.all(color: Colors.white, width: 3 * s),
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
                  right: -2 * s,
                  bottom: -2 * s,
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
                      padding: EdgeInsets.all(8 * s),
                      decoration: BoxDecoration(
                        color: AppColors.brownDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3 * s),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCamera01,
                        color: Colors.white,
                        size: 16 * s,
                        strokeWidth: 2.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18 * s),
          Text(
            fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.style(size: 22 * s, weight: FontWeight.w800, color: AppColors.brownDark),
          ),
          SizedBox(height: 4 * s),
          Text(
            email,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.style(size: 14 * s, weight: FontWeight.w500, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
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
              Container(width: 4 * s, height: 16 * s, decoration: BoxDecoration(color: AppColors.goldDark, borderRadius: BorderRadius.circular(4 * s))),
              SizedBox(width: 8 * s),
              Text(title, style: AppFonts.style(size: 14 * s, weight: FontWeight.w700, color: AppColors.brown)),
            ],
          ),
        ),
        SizedBox(height: 12 * s),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22 * s),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22 * s),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(width: double.infinity, child: Column(children: children)),
          ),
        ),
      ],
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner({required this.s, required this.onTap});

  final double s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20 * s),
      side: BorderSide(color: AppColors.goldDark.withValues(alpha: 0.45)),
    );

    return Material(
      color: AppColors.goldLight.withValues(alpha: 0.2),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16 * s),
          child: Row(
            children: [
              Container(
                width: 42 * s, height: 42 * s,
                decoration: BoxDecoration(color: AppColors.brownDark, borderRadius: BorderRadius.circular(14 * s)),
                child: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, size: 22 * s, color: AppColors.goldLight, strokeWidth: 2.0),
              ),
              SizedBox(width: 14 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Completa tu perfil', style: AppFonts.style(size: 15.5 * s, weight: FontWeight.w800, color: AppColors.brownDark)),
                    SizedBox(height: 2 * s),
                    Text('Te faltan datos para gestionar tus envios y tu facturacion.', style: AppFonts.style(size: 13 * s, weight: FontWeight.w500, color: AppColors.brown.withValues(alpha: 0.85), height: 1.3)),
                  ],
                ),
              ),
              HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 24 * s, color: AppColors.brown, strokeWidth: 2.0),
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
        padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 14 * s),
        child: Row(
          children: [
            Container(
              width: 38 * s, height: 38 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.beige.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12 * s),
              ),
              child: HugeIcon(icon: icon, color: AppColors.brown, size: 19 * s, strokeWidth: 2.0),
            ),
            SizedBox(width: 14 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppFonts.style(size: 13 * s, weight: FontWeight.w500, color: AppColors.brown.withValues(alpha: 0.78))),
                  SizedBox(height: 3 * s),
                  Text(
                    hasValue ? value! : 'Sin registrar',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: AppFonts.style(size: 15.5 * s, weight: hasValue ? FontWeight.w600 : FontWeight.w500, color: hasValue ? AppColors.brownDark : AppColors.muted),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8 * s),
            if (hasValue)
              HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 20 * s, color: AppColors.brown.withValues(alpha: 0.45), strokeWidth: 2.0)
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 7 * s),
                decoration: BoxDecoration(
                  color: AppColors.goldLight.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20 * s),
                  border: Border.all(color: AppColors.goldDark.withValues(alpha: 0.55)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 14 * s, color: AppColors.brown, strokeWidth: 2.0),
                    SizedBox(width: 4 * s),
                    Text('Agregar', style: AppFonts.style(size: 13 * s, weight: FontWeight.w700, color: AppColors.brown)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}