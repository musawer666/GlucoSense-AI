import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/snack_reminder.dart';
import 'day_of_week_chips.dart';
import 'reminder_time_picker_tile.dart';

/// Modal bottom sheet for creating / editing a [SnackReminder].
/// Returns the edited snack via `Navigator.pop` or `null` if cancelled.
class AddSnackReminderSheet extends StatefulWidget {
  const AddSnackReminderSheet({super.key, this.initial});

  /// When provided, the sheet starts in "edit" mode.
  final SnackReminder? initial;

  static Future<SnackReminder?> show(
    BuildContext context, {
    SnackReminder? initial,
  }) {
    return showModalBottomSheet<SnackReminder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSnackReminderSheet(initial: initial),
    );
  }

  @override
  State<AddSnackReminderSheet> createState() => _AddSnackReminderSheetState();
}

class _AddSnackReminderSheetState extends State<AddSnackReminderSheet> {
  late TextEditingController _labelCtrl;
  late TimeOfDay _time;
  late Set<int> _days;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(
      text: widget.initial?.label ?? 'Afternoon snack',
    );
    _time = widget.initial?.time ?? const TimeOfDay(hour: 16, minute: 30);
    _days = widget.initial?.daysOfWeek ?? const <int>{};
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _labelCtrl.text.trim();
    final result = SnackReminder(
      id: widget.initial?.id ?? 'pending',
      label: label.isEmpty ? 'Snack' : label,
      time: _time,
      enabled: widget.initial?.enabled ?? true,
      daysOfWeek: _days,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              isEdit ? 'Edit snack reminder' : 'New snack reminder',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'We\'ll ping you around this time to log a glucose reading.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _labelCtrl,
              textInputAction: TextInputAction.done,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Label',
                hintText: 'e.g. Afternoon snack',
                prefixIcon: Icon(Icons.label_outline_rounded,
                    color: AppColors.primary700),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary100),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ReminderTimePickerTile(
                label: 'Time',
                time: _time,
                icon: Icons.schedule_rounded,
                onChanged: (t) => setState(() => _time = t),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Repeat on',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            DayOfWeekChips(
              selected: _days,
              onChanged: (next) => setState(() => _days = next),
            ),
            const SizedBox(height: 20),
            AppGradientButton(
              label: isEdit ? 'Save changes' : 'Create reminder',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
