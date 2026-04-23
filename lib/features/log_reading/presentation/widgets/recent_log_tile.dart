import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../domain/glucose_log_entry.dart';

/// Premium tile for a single glucose log. Color-codes by reading type
/// (fasting → violet, pre-meal → orange, post-meal → teal).
class RecentLogTile extends StatelessWidget {
  const RecentLogTile({
    super.key,
    required this.entry,
    required this.fmt,
  });

  final GlucoseLogEntry entry;
  final String Function(DateTime) fmt;

  Color get _accent => switch (entry.readingType) {
        GlucoseReadingType.fasting => AppColors.secondary500,
        GlucoseReadingType.preMeal => AppColors.tertiary500,
        GlucoseReadingType.postMeal => AppColors.primary600,
      };

  Color get _accentSoft => switch (entry.readingType) {
        GlucoseReadingType.fasting => AppColors.secondary50,
        GlucoseReadingType.preMeal => AppColors.tertiary50,
        GlucoseReadingType.postMeal => AppColors.primary50,
      };

  String get _typeLabel => switch (entry.readingType) {
        GlucoseReadingType.fasting => 'Fasting',
        GlucoseReadingType.preMeal => 'Pre-Meal',
        GlucoseReadingType.postMeal => 'Post-Meal',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _accent.withValues(alpha: 0.75),
                  _accent,
                ],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withValues(alpha: 0.18)),
            ),
            child: Icon(
              Icons.bloodtype_rounded,
              color: _accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _typeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: _accent,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${entry.glucoseMgDl} mg/dL',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.mealTag.label} · ${entry.mealName}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            fmt(entry.timestamp),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.neutral500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
