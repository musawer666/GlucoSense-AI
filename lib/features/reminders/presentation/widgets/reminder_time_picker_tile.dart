import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';

/// Compact row with a label + time pill. Tapping opens the native time
/// picker and returns the selected [TimeOfDay] via [onChanged].
class ReminderTimePickerTile extends StatelessWidget {
  const ReminderTimePickerTile({
    super.key,
    required this.label,
    required this.time,
    required this.onChanged,
    this.enabled = true,
    this.icon,
  });

  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;
  final bool enabled;
  final IconData? icon;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx)
              .copyWith(alwaysUse24HourFormat: false),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  String _format(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$mm $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? () => _pick(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: AppColors.primary700,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: enabled
                        ? AppColors.primary300
                        : AppColors.neutral200,
                    width: 1.2,
                  ),
                  boxShadow: enabled
                      ? [
                          BoxShadow(
                            color: AppColors.primary200.withValues(alpha: 0.24),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: enabled
                          ? AppColors.primary700
                          : AppColors.neutral500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _format(time),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? AppColors.primary800
                            : AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
