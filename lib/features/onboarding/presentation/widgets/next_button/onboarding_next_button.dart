import 'package:flutter/material.dart';

import '../../../../../core/colors/app_colors.dart';

/// Circular teal CTA — forward arrow (step 1–2) or check (final step).
class OnboardingNextButton extends StatelessWidget {
  const OnboardingNextButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final diameter = (shortest * 0.14).clamp(52.0, 60.0);
    final iconSize = icon == Icons.check_rounded
        ? (diameter * 0.5).clamp(24.0, 30.0)
        : (diameter * 0.45).clamp(22.0, 28.0);

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary500, AppColors.primary700],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary700.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
