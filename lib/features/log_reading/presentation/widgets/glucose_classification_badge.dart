import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../domain/glucose_classification.dart';
import '../../domain/glucose_log_entry.dart';

/// Live clinical classification of the glucose value the user is typing.
///
/// Shows nothing while [value] is null, otherwise renders an animated
/// colored badge (Low / Normal / Elevated / High) with a short helper.
class GlucoseClassificationBadge extends StatelessWidget {
  const GlucoseClassificationBadge({
    super.key,
    required this.value,
    required this.type,
  });

  final int? value;
  final GlucoseReadingType type;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: value == null
            ? const SizedBox.shrink()
            : _Badge(
                key: ValueKey<int>(value!),
                status: GlucoseClassifier.classify(value!, type),
                value: value!,
              ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({super.key, required this.status, required this.value});

  final GlucoseStatus status;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            status.color.withValues(alpha: 0.10),
            status.softColor,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status.color.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: status.color.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(status.icon, color: status.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      status.label,
                      style: GoogleFonts.manrope(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: status.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· $value mg/dL',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  status.helper,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
