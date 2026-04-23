import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../domain/entities/meal_photo_analysis.dart';

/// Renders a single AI-generated lower-impact swap. All values come
/// from [alternative] — the widget never synthesizes numbers.
///
/// Tap behaviour is delegated to the parent via [onTap]; passing a
/// callback also shows a chevron affordance and an ink splash so users
/// know the tile is interactive.
class MealAlternativeTile extends StatelessWidget {
  const MealAlternativeTile({
    super.key,
    required this.alternative,
    this.onTap,
    this.isSaved = false,
  });

  final SmarterAlternative alternative;

  /// Opens the alternative detail sheet. When `null`, the tile is
  /// purely informational (no splash, no chevron).
  final VoidCallback? onTap;

  /// Renders a small "SAVED" pill on the right when true so the user
  /// can tell at a glance which alternatives they have already kept.
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.primary100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.primary700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alternative.name,
                        style: GoogleFonts.manrope(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (alternative.estPeakMgDl > 0)
                        Text(
                          'Est. Peak: ${alternative.estPeakMgDl} mg/dL',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary700,
                          ),
                        ),
                      if (alternative.reason.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          alternative.reason,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isSaved)
                  _SavedPill()
                else if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 12, color: AppColors.primary700),
          const SizedBox(width: 3),
          Text(
            'SAVED',
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primary700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
