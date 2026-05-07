import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';

/// Hero card that hosts the global reminders on/off switch.
class RemindersMasterSwitch extends StatelessWidget {
  const RemindersMasterSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: value
              ? [AppColors.primary500, AppColors.primary700]
              : [AppColors.neutral200, AppColors.neutral300],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: value
            ? [
                BoxShadow(
                  color: AppColors.primary500.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              value
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminders',
                  style: GoogleFonts.manrope(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value
                      ? 'You\'ll be pinged around meal times.'
                      : 'All reminders are paused.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary800,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.neutral400,
          ),
        ],
      ),
    );
  }
}
