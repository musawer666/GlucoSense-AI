import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../log_reading/domain/glucose_log_entry.dart';
import '../../domain/entities/meal_reminder_slot.dart';
import 'day_of_week_chips.dart';
import 'reminder_time_picker_tile.dart';

/// Expandable card for a single main-meal slot.
///
/// Layout:
///   • Header: icon + meal label + master switch.
///   • When expanded:
///       - Pre-meal row (switch + time picker)
///       - Post-meal row (switch + time picker)
///       - Days of week chips
class MealReminderCard extends StatefulWidget {
  const MealReminderCard({
    super.key,
    required this.slot,
    required this.interactive,
    required this.onEnabledChanged,
    required this.onPreMealEnabledChanged,
    required this.onPostMealEnabledChanged,
    required this.onPreMealTimeChanged,
    required this.onPostMealTimeChanged,
    required this.onDaysChanged,
  });

  final MealReminderSlot slot;
  final bool interactive;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool> onPreMealEnabledChanged;
  final ValueChanged<bool> onPostMealEnabledChanged;
  final ValueChanged<TimeOfDay> onPreMealTimeChanged;
  final ValueChanged<TimeOfDay> onPostMealTimeChanged;
  final ValueChanged<Set<int>> onDaysChanged;

  @override
  State<MealReminderCard> createState() => _MealReminderCardState();
}

class _MealReminderCardState extends State<MealReminderCard> {
  bool _expanded = false;

  String get _label => switch (widget.slot.mealTag) {
        MealLogTag.breakfast => 'Breakfast',
        MealLogTag.lunch => 'Lunch',
        MealLogTag.dinner => 'Dinner',
        MealLogTag.snack => 'Snack',
      };

  IconData get _icon => switch (widget.slot.mealTag) {
        MealLogTag.breakfast => Icons.free_breakfast_rounded,
        MealLogTag.lunch => Icons.lunch_dining_rounded,
        MealLogTag.dinner => Icons.dinner_dining_rounded,
        MealLogTag.snack => Icons.cookie_rounded,
      };

  Color get _accent => switch (widget.slot.mealTag) {
        MealLogTag.breakfast => AppColors.tertiary400,
        MealLogTag.lunch => AppColors.primary400,
        MealLogTag.dinner => AppColors.secondary500,
        MealLogTag.snack => AppColors.secondary400,
      };

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final interactive = widget.interactive && slot.enabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary100),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary200.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.interactive
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_icon, size: 20, color: _accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _label,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle(slot),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 220),
                    turns: _expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch.adaptive(
                    value: slot.enabled,
                    onChanged: widget.interactive
                        ? widget.onEnabledChanged
                        : null,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: (_expanded && slot.enabled)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 6),
                      Divider(height: 1, color: AppColors.neutral200),
                      const SizedBox(height: 6),
                      _RowTimeWithSwitch(
                        label: 'Pre-meal',
                        icon: Icons.restaurant_menu_rounded,
                        enabled: slot.preMealEnabled,
                        time: slot.preMealTime,
                        interactive: interactive,
                        onEnabledChanged: widget.onPreMealEnabledChanged,
                        onTimeChanged: widget.onPreMealTimeChanged,
                      ),
                      Divider(height: 1, color: AppColors.neutral100),
                      _RowTimeWithSwitch(
                        label: 'Post-meal (2h after)',
                        icon: Icons.update_rounded,
                        enabled: slot.postMealEnabled,
                        time: slot.postMealTime,
                        interactive: interactive,
                        onEnabledChanged: widget.onPostMealEnabledChanged,
                        onTimeChanged: widget.onPostMealTimeChanged,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Days of week',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      DayOfWeekChips(
                        selected: slot.daysOfWeek,
                        onChanged: widget.onDaysChanged,
                        enabled: interactive,
                      ),
                      const SizedBox(height: 4),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _subtitle(MealReminderSlot slot) {
    final parts = <String>[];
    if (slot.preMealEnabled) {
      parts.add('Pre ${_fmt(slot.preMealTime)}');
    }
    if (slot.postMealEnabled) {
      parts.add('Post ${_fmt(slot.postMealTime)}');
    }
    if (parts.isEmpty) return 'Tap to configure';
    return parts.join(' • ');
  }

  static String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$mm $suffix';
  }
}

class _RowTimeWithSwitch extends StatelessWidget {
  const _RowTimeWithSwitch({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.time,
    required this.interactive,
    required this.onEnabledChanged,
    required this.onTimeChanged,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final TimeOfDay time;
  final bool interactive;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: ReminderTimePickerTile(
              label: label,
              time: time,
              icon: icon,
              onChanged: onTimeChanged,
              enabled: interactive && enabled,
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: interactive ? onEnabledChanged : null,
          ),
        ],
      ),
    );
  }
}
