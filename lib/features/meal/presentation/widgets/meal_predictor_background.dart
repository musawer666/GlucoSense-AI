import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';

class MealPredictorBackground extends StatelessWidget {
  const MealPredictorBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return Stack(
          children: [
            Positioned(
              right: -w * 0.28,
              top: w * 0.4,
              child: Container(
                width: w * 0.75,
                height: w * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary100.withValues(alpha: 0.33),
                ),
              ),
            ),
            Positioned(
              left: -w * 0.25,
              bottom: w * 0.05,
              child: Container(
                width: w * 0.65,
                height: w * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary50.withValues(alpha: 0.8),
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
