import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/colors/app_colors.dart';

/// Short intro under the app bar (title lives in [GlucoSliverAppBar]).
class ProfileSetupIntro extends StatelessWidget {
  const ProfileSetupIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return Padding(
          padding: EdgeInsets.only(bottom: (w * 0.02).clamp(4.0, 8.0)),
          child: Text(
            'A few details help us tailor insights, BMI, and glucose targets '
            'to you.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: (w * 0.038).clamp(14.0, 16.0),
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}
