import 'package:flutter/material.dart';

import '../colors/app_colors.dart';

/// Pastel page background: teal (top-right) + violet (bottom-left).
/// [profileSoft] adds a softer lilac wash for profile flows.
class SoftBlobBackground extends StatelessWidget {
  const SoftBlobBackground({
    super.key,
    required this.child,
    this.profileSoft = false,
  });

  final Widget child;
  final bool profileSoft;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final blob = w * 0.72;

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.neutral50),
            if (profileSoft)
              Positioned(
                top: -blob * 0.35,
                left: w * 0.1,
                width: blob * 1.1,
                height: blob * 0.9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary100.withValues(alpha: 0.55),
                        AppColors.secondary50.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: -blob * 0.15,
              right: -blob * 0.2,
              width: blob,
              height: blob,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary200.withValues(alpha: 0.42),
                      AppColors.primary100.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -blob * 0.12,
              left: -blob * 0.18,
              width: blob * 1.05,
              height: blob * 1.05,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary200.withValues(alpha: 0.38),
                      AppColors.secondary100.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}
