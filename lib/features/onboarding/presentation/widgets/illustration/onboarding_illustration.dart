import 'package:flutter/material.dart';

import '../../../../../core/colors/app_colors.dart';

/// Rounded card with soft teal wash + [image] (full-bleed illustration asset).
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.imageAsset,
  });

  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final radius = (maxW * 0.06).clamp(18.0, 28.0);
        final pad = (maxW * 0.04).clamp(12.0, 20.0);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary50,
                  AppColors.primary100.withValues(alpha: 0.95),
                  AppColors.primary200.withValues(alpha: 0.35),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary900.withValues(alpha: 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: AspectRatio(
                aspectRatio: 1.05,
                child: Padding(
                  padding: EdgeInsets.all((maxW * 0.04).clamp(12.0, 24.0)),
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
