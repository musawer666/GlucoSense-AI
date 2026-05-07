import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import 'reminder_time_picker_tile.dart';

/// Dedicated card for the fasting (morning) reminder — clinically
/// distinct from the three main meal slots, so it lives on its own.
class FastingReminderCard extends StatelessWidget {
  const FastingReminderCard({
    super.key,
    required this.enabled,
    required this.time,
    required this.onEnabledChanged,
    required this.onTimeChanged,
    required this.interactive,
  });

  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return _RemindersCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.tertiary100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.wb_twilight_rounded,
                  size: 20,
                  color: AppColors.tertiary700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fasting reminder',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Right after you wake up, before breakfast.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: enabled,
                onChanged: interactive ? onEnabledChanged : null,
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: !enabled
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ReminderTimePickerTile(
                      label: 'Fire at',
                      time: time,
                      onChanged: onTimeChanged,
                      enabled: interactive,
                      icon: Icons.schedule_rounded,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Shared card shell used by fasting + meal cards to keep visuals
// coherent without duplicating the decoration everywhere.
class _RemindersCard extends StatelessWidget {
  const _RemindersCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.primary50.withValues(alpha: 0.55)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary100),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary200.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
