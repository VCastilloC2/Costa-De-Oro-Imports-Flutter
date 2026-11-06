// RAMA: feature/Profile
// ============================================================================
// PANTALLA: AccountDetailsPage
// ============================================================================
// Vista de solo lectura con la informacion de la cuenta del usuario.
// Organiza los datos en tarjetas con etiqueta sobre valor, de modo que ningun
// texto largo pueda desbordar la fila (el valor ocupa todo el ancho y, si hace
// falta, pasa a una segunda linea).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

// ----------------------------------------------------------------------------
// DATOS PROVISIONALES
// ----------------------------------------------------------------------------
// UserModel todavia no incluye direccion, tipo ni numero de documento. Estos
// valores son marcadores de posicion y deben reemplazarse por los datos reales
// del usuario cuando la API los entregue.
// TODO(feature/Profile): leer estos valores desde UserModel.
const String? _addressPlaceholder = 'Calle 123 #45-67 (Pendiente)';
const String? _documentTypePlaceholder = 'Cédula de Ciudadanía (CC)';
const String? _documentNumberPlaceholder = 'Registrado';

/// Valor que la API usa cuando el usuario no registro telefono.
const String _emptyPhone = '0000000000';

class AccountDetailsPage extends ConsumerWidget {
  const AccountDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = MediaQuery.sizeOf(context).width / 390;
    final user = ref.watch(authControllerProvider).user;

    // Telefono: null cuando no hay un valor util para mostrar.
    final rawPhone = user?.telefono;
    final phone =
        (rawPhone == null || rawPhone.isEmpty || rawPhone == _emptyPhone)
            ? null
            : rawPhone;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      // El cuerpo se extiende detras de la barra superior para que el
      // resplandor dorado del fondo la cubra tambien. Antes empezaba justo
      // debajo de la barra y dejaba una franja clara visible sobre el titulo.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 16 * s),
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
          // Resplandor dorado suave detras de la cabecera.
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
                      AppColors.goldLight.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              // kToolbarHeight compensa la barra superior, que ahora queda
              // flotando sobre el cuerpo.
              padding: EdgeInsets.fromLTRB(
                20 * s,
                kToolbarHeight + 12 * s,
                20 * s,
                32 * s,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CABECERA: AVATAR, NOMBRE Y CORREO ---
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
                  SizedBox(height: 28 * s),

                  // --- INFORMACION DE CONTACTO ---
                  _Reveal(
                    order: 1,
                    child: _Section(
                      s: s,
                      title: 'Información de contacto',
                      rows: [
                        _InfoRow(
                          s: s,
                          icon: Icons.phone_outlined,
                          label: 'Teléfono',
                          value: phone,
                          onAdd: () => context.push('/edit-profile'),
                        ),
                        _InfoRow(
                          s: s,
                          icon: Icons.location_on_outlined,
                          label: 'Dirección de envío',
                          value: _addressPlaceholder,
                          onAdd: () => context.push('/edit-profile'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24 * s),

                  // --- DOCUMENTO DE IDENTIDAD ---
                  _Reveal(
                    order: 2,
                    child: _Section(
                      s: s,
                      title: 'Documento de identidad',
                      rows: [
                        _InfoRow(
                          s: s,
                          icon: Icons.badge_outlined,
                          label: 'Tipo de documento',
                          value: _documentTypePlaceholder,
                          onAdd: () => context.push('/edit-profile'),
                        ),
                        _InfoRow(
                          s: s,
                          icon: Icons.tag_rounded,
                          label: 'Número de documento',
                          // Por seguridad no se muestra el numero completo.
                          value: _documentNumberPlaceholder,
                          onAdd: () => context.push('/edit-profile'),
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

/// Entrada suave: aparece con fundido y sube un poco. Cada bloque entra un
/// instante despues del anterior segun [order]. Respeta la preferencia del
/// sistema de reducir animaciones.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration:
          reduce ? Duration.zero : Duration(milliseconds: 420 + order * 140),
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

/// Cabecera con el avatar, el nombre y el correo del usuario, sobre el fondo.
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
      style: AppFonts.style(
        size: 38 * s,
        weight: FontWeight.w700,
        color: AppColors.brownDark,
      ),
    );

    // Sin tarjeta blanca: el avatar, el nombre y el correo van directamente
    // sobre el fondo de la pagina.
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
                // Anillo dorado con degradado alrededor del avatar.
                Container(
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
                              errorBuilder: (context, error, stackTrace) =>
                                  initialsText,
                            ),
                          )
                        : initialsText,
                  ),
                ),
                // Boton de camara. La subida de foto aun no esta disponible.
                Positioned(
                  right: -2 * s,
                  bottom: -2 * s,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'La foto de perfil estará disponible pronto.',
                            ),
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
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 16 * s,
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
            style: AppFonts.style(
              size: 22 * s,
              weight: FontWeight.w800,
              color: AppColors.brownDark,
            ),
          ),
          SizedBox(height: 4 * s),
          Text(
            email,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.style(
              size: 14 * s,
              weight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloque con titulo (marca dorada a la izquierda) y una tarjeta de filas.
class _Section extends StatelessWidget {
  const _Section({
    required this.s,
    required this.title,
    required this.rows,
  });

  final double s;
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    // Divisores entre filas, alineados con el texto (despues del icono).
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: EdgeInsets.only(left: 72 * s),
            child: const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF2ECE2),
            ),
          ),
        );
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
                height: 16 * s,
                decoration: BoxDecoration(
                  color: AppColors.goldDark,
                  borderRadius: BorderRadius.circular(4 * s),
                ),
              ),
              SizedBox(width: 8 * s),
              Text(
                title,
                style: AppFonts.style(
                  size: 14 * s,
                  weight: FontWeight.w700,
                  color: AppColors.brown,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12 * s),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22 * s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Fila de informacion: icono en un recuadro, etiqueta pequena y valor debajo.
/// El valor ocupa todo el ancho disponible, asi que un texto largo se parte en
/// dos lineas en vez de desbordar. Si [value] es null se muestra "No registrado"
/// con un enlace "Agregar".
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.s,
    required this.icon,
    required this.label,
    required this.value,
    this.onAdd,
  });

  final double s;
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 14 * s),
      child: Row(
        children: [
          Container(
            width: 42 * s,
            height: 42 * s,
            decoration: BoxDecoration(
              color: AppColors.beige.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14 * s),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.brown, size: 21 * s),
          ),
          SizedBox(width: 14 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.style(
                    size: 12.5 * s,
                    weight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
                SizedBox(height: 3 * s),
                Text(
                  hasValue ? value! : 'No registrado',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.style(
                    size: 15.5 * s,
                    weight: hasValue ? FontWeight.w600 : FontWeight.w500,
                    color: hasValue ? AppColors.brownDark : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (!hasValue && onAdd != null)
            TextButton(
              onPressed: onAdd,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10 * s),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Agregar',
                style: AppFonts.style(
                  size: 14 * s,
                  weight: FontWeight.w700,
                  color: AppColors.goldDark,
                ),
              ),
            ),
        ],
      ),
    );
  }
}