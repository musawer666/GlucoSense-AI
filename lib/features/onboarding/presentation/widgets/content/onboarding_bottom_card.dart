import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/colors/app_colors.dart';
import '../../constants/onboarding_colors.dart';
import '../indicators/onboarding_page_indicators.dart';
import '../next_button/onboarding_next_button.dart';

/// White bottom sheet: headline, body, indicators + next.
class OnboardingBottomCard extends StatelessWidget {
  const OnboardingBottomCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pageIndex,
    required this.pageCount,
    required this.onNext,
    this.ctaIcon = Icons.arrow_forward_rounded,
  });

  final String title;
  final String subtitle;
  final int pageIndex;
  final int pageCount;
  final VoidCallback onNext;
  final IconData ctaIcon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final topRadius = (w * 0.08).clamp(24.0, 32.0);
        final hPad = (w * 0.07).clamp(20.0, 28.0);
        final vPadTop = (w * 0.09).clamp(26.0, 36.0);
        final titleSize = (w * 0.065).clamp(22.0, 28.0);
        final bodySize = (w * 0.038).clamp(14.0, 16.0);

        return Material(
          color: Colors.white,
          elevation: 14,
          shadowColor: AppColors.primary900.withValues(alpha: 0.10),
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(topRadius),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(topRadius),
              ),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, AppColors.neutral50],
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.primary100.withValues(alpha: 0.8),
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, vPadTop, hPad, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary50,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.primary100),
                          ),
                          child: Text(
                            'GlucoSense AI',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: AppColors.primary700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: (w * 0.035).clamp(12.0, 16.0)),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: (w * 0.035).clamp(12.0, 16.0)),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: bodySize,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          color: OnboardingColors.bodyGrey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: (w * 0.08).clamp(22.0, 32.0)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      OnboardingPageIndicators(
                        count: pageCount,
                        activeIndex: pageIndex,
                      ),
                      const Spacer(),
                      OnboardingNextButton(
                        onPressed: onNext,
                        icon: ctaIcon,
                      ),
                    ],
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
