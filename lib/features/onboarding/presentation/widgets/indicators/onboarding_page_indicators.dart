import 'package:flutter/material.dart';

import '../../../../../core/colors/app_colors.dart';
import '../../constants/onboarding_colors.dart';

/// Pill for active page + grey dots for the rest.
class OnboardingPageIndicators extends StatelessWidget {
  const OnboardingPageIndicators({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: active ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary600
                  : OnboardingColors.indicatorInactive,
              borderRadius: BorderRadius.circular(999),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.primary700.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
