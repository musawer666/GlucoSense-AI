import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../domain/entities/saved_meal.dart';
import 'meal_photo_ai_card.dart';

class SavedMealTile extends StatelessWidget {
  const SavedMealTile({
    super.key,
    required this.entry,
    required this.onView,
    required this.onDelete,
  });

  final SavedMeal entry;
  final VoidCallback onView;
  final VoidCallback onDelete;

  Color get _accent => switch (entry.analysis.verdict) {
    MealSafetyVerdict.safe => AppColors.primary600,
    MealSafetyVerdict.caution => AppColors.tertiary500,
    MealSafetyVerdict.risky => AppColors.destructive,
  };

  Color get _accentSoft => switch (entry.analysis.verdict) {
    MealSafetyVerdict.safe => AppColors.primary100,
    MealSafetyVerdict.caution => AppColors.tertiary100,
    MealSafetyVerdict.risky => const Color(0xFFFEE2E2),
  };

  IconData get _verdictIcon => switch (entry.analysis.verdict) {
    MealSafetyVerdict.safe => Icons.verified_rounded,
    MealSafetyVerdict.caution => Icons.warning_amber_rounded,
    MealSafetyVerdict.risky => Icons.dangerous_outlined,
  };

  String get _verdictLabel => switch (entry.analysis.verdict) {
    MealSafetyVerdict.safe => 'SAFE',
    MealSafetyVerdict.caution => 'CAUTION',
    MealSafetyVerdict.risky => 'RISKY',
  };

  String get _formattedTime {
    final t = entry.savedAt;
    final now = DateTime.now();
    final isToday = t.year == now.year && t.month == now.month && t.day == now.day;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    if (isToday) return 'Today, $hh:$mm';
    return '${t.day}/${t.month}/${t.year} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onView,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_verdictIcon, color: _accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.analysis.mealName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (entry.isAlternative) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary100,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.primary300),
                          ),
                          child: Text(
                            'ALT',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _accentSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _verdictLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _accent,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formattedTime,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.opacity_rounded,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.currentGlucoseMgDl == null
                            ? '— mg/dL'
                            : '${entry.currentGlucoseMgDl} mg/dL',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: onDelete,
              icon: Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
