import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../app/theme/app_colors.dart';

/// Reusable loading treatment for a complete screen or a section of the UI.
class AppSkeletonizer extends StatelessWidget {
  const AppSkeletonizer({
    required this.enabled,
    required this.child,
    super.key,
  });

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: enabled,
      enableSwitchAnimation: true,
      effect: const ShimmerEffect(
        baseColor: AppColors.skeletonBase,
        highlightColor: AppColors.skeletonHighlight,
        duration: Duration(milliseconds: 1300),
      ),
      child: child,
    );
  }
}
