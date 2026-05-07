import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../domain/entities/snack_reminder.dart';

/// Visual list of snack reminders with inline enable/edit/delete actions.
class SnackRemindersSection extends StatelessWidget {
  const SnackRemindersSection({
    super.key,
    required this.snacks,
    required this.interactive,
    required this.onAddTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final List<SnackReminder> snacks;
  final bool interactive;
  final VoidCallback onAddTap;
  final void Function(SnackReminder snack) onEdit;
  final void Function(SnackReminder snack) onDelete;
  final void Function(SnackReminder snack, bool enabled) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary100),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary200.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.secondary100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.cookie_rounded,
                  size: 20,
                  color: AppColors.secondary700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Snack reminders',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      snacks.isEmpty
                          ? 'Add reminders for mid-morning or afternoon snacks.'
                          : '${snacks.length} reminder${snacks.length == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: interactive ? onAddTap : null,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(38, 38),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
              ),
            ],
          ),
          if (snacks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: AppColors.neutral100),
            const SizedBox(height: 4),
            for (var i = 0; i < snacks.length; i++) ...[
              if (i > 0) Divider(height: 1, color: AppColors.neutral100),
              _SnackRow(
                snack: snacks[i],
                interactive: interactive,
                onEdit: () => onEdit(snacks[i]),
                onDelete: () => onDelete(snacks[i]),
                onToggle: (v) => onToggle(snacks[i], v),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SnackRow extends StatelessWidget {
  const _SnackRow({
    required this.snack,
    required this.interactive,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final SnackReminder snack;
  final bool interactive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  static String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$mm $suffix';
  }

  String _daysLabel(Set<int> days) {
    if (days.isEmpty) return 'Every day';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return (days.toList()..sort()).map((d) => names[d - 1]).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: interactive ? onEdit : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondary100),
              ),
              child: Text(
                _fmt(snack.time),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snack.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _daysLabel(snack.daysOfWeek),
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: interactive ? onDelete : null,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.destructive.withValues(alpha: 0.8),
              ),
              tooltip: 'Delete',
            ),
            Switch.adaptive(
              value: snack.enabled,
              onChanged: interactive ? onToggle : null,
            ),
          ],
        ),
      ),
    );
  }
}
