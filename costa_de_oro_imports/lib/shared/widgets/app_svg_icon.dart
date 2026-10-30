import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Ícono de línea fina. Si no se indica color o tamaño, toma los del
/// IconTheme que lo rodea (por eso sigue la animación de AppTextField).
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(this.svg, {super.key, this.size, this.color});

  final String svg;
  final double? size;
  final Color? color;

  static const _open =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="none" stroke="#000" stroke-width="1.6" '
      'stroke-linecap="round" stroke-linejoin="round">';

  static const mail = '$_open'
      '<rect width="20" height="16" x="2" y="4" rx="3"/>'
      '<path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>';

  static const lock = '$_open'
      '<rect width="18" height="11" x="3" y="11" rx="3"/>'
      '<path d="M7 11V7a5 5 0 0 1 10 0v4"/>'
      '<path d="M12 16v.01"/></svg>';

  static const eye = '$_open'
      '<path d="M2.06 12.35a1 1 0 0 1 0-.7 10.75 10.75 0 0 1 19.88 0 '
      '1 1 0 0 1 0 .7 10.75 10.75 0 0 1-19.88 0"/>'
      '<circle cx="12" cy="12" r="3"/></svg>';

  static const eyeOff = '$_open'
      '<path d="M10.73 5.08a10.74 10.74 0 0 1 11.21 6.57 1 1 0 0 1 0 .7 '
      '10.75 10.75 0 0 1-1.44 2.49"/>'
      '<path d="M14.08 14.16a3 3 0 0 1-4.24-4.24"/>'
      '<path d="M17.48 17.5a10.75 10.75 0 0 1-15.42-5.15 1 1 0 0 1 0-.7 '
      '10.75 10.75 0 0 1 4.45-5.14"/>'
      '<path d="m2 2 20 20"/></svg>';

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final c = color ?? theme.color ?? Colors.black;
    final s = size ?? theme.size ?? 24;

    return SvgPicture.string(
      svg,
      width: s,
      height: s,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}