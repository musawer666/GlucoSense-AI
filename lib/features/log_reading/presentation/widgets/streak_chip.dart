import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../domain/glucose_log_entry.dart';

/// Pill chip that shows the user's consecutive-day logging streak.
///
/// Hidden when [days] is 0 so the hero layout stays clean for new users.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    if (days <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.tertiary100, AppColors.tertiary50],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.tertiary200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 13,
            color: AppColors.tertiary600,
          ),
          const SizedBox(width: 6),
          Text(
            '$days-day streak',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.tertiary700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pure helper — counts consecutive calendar days (ending today) that
/// contain at least one log entry.
int computeLoggingStreak(List<GlucoseLogEntry> logs) {
  if (logs.isEmpty) return 0;
  final days = <DateTime>{
    for (final e in logs)
      DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day),
  };
  var cursor = DateTime.now();
  cursor = DateTime(cursor.year, cursor.month, cursor.day);
  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
