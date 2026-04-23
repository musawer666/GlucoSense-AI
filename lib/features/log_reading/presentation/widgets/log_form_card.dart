import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';

/// White surface with soft teal outline used as the main form container
/// on the Log Reading screen.
class LogFormCard extends StatelessWidget {
  const LogFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primary50.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary200),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary200.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
