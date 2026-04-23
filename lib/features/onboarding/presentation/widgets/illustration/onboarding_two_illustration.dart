import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/colors/app_colors.dart';

/// Top panel: blue → peach gradient, serif heading, centered [imageAsset].
class OnboardingTwoIllustration extends StatelessWidget {
  const OnboardingTwoIllustration({
    super.key,
    required this.imageAsset,
    required this.heading,
  });

  final String imageAsset;
  final String heading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final radius = (maxW * 0.06).clamp(18.0, 28.0);
        final hPad = (maxW * 0.04).clamp(12.0, 20.0);
        final titleSize = (maxW * 0.05).clamp(17.0, 22.0);
        final innerPad = (maxW * 0.035).clamp(12.0, 20.0);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary50,
                  AppColors.secondary50.withValues(alpha: 0.62),
                  AppColors.tertiary50.withValues(alpha: 0.70),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary900.withValues(alpha: 0.08),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      innerPad,
                      innerPad + 4,
                      innerPad,
                      8,
                    ),
                    child: Text(
                      heading,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: AppColors.primary800,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      innerPad,
                      0,
                      innerPad,
                      innerPad + 4,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
