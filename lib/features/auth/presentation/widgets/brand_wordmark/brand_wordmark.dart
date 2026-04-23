import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/colors/app_colors.dart';

/// Centered **GlucoIQ** title + subtle tagline above auth forms.
class LoginBrandWordmark extends StatelessWidget {
  const LoginBrandWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final titleSize = (w * 0.09).clamp(26.0, 34.0);
        final tagSize = (w * 0.032).clamp(12.0, 14.0);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GlucoIQ',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: AppColors.primary900,
                height: 1.05,
              ),
            ),
            SizedBox(height: (w * 0.02).clamp(6.0, 10.0)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.primary200),
              ),
              child: Text(
                'AI glucose companion',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: tagSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: AppColors.primary700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
