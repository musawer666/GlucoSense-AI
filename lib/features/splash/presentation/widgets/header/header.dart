import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/colors/app_colors.dart';

/// App title + tagline (centered).
class SplashHeader extends StatelessWidget {
  const SplashHeader({
    super.key,
    required this.maxContentWidth,
  });

  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.clamp(0, maxContentWidth);
        final titleSize = (w * 0.1).clamp(28.0, 36.0);
        final tagSize = (w * 0.042).clamp(14.0, 16.0);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: (w * 0.06).clamp(8.0, 20.0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GlucoIQ',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                  color: const Color(0xFF134E4A),
                ),
              ),
              SizedBox(height: (w * 0.025).clamp(8.0, 14.0)),
              Text(
                'The Luminous Pulse of Your Metabolic Health.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: tagSize,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
