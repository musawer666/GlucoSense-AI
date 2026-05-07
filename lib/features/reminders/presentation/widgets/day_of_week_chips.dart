import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';

/// Pill row for picking days of week (ISO 1..7).
///
/// An empty selection is treated as "every day" by the domain layer;
/// this widget surfaces that as the "All" chip being selected when
/// no specific day is chosen.
class DayOfWeekChips extends StatelessWidget {
  const DayOfWeekChips({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;
  final bool enabled;

  static const List<String> _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  void _toggle(int day) {
    if (!enabled) return;
    final next = Set<int>.of(selected);
    if (next.contains(day)) {
      next.remove(day);
    } else {
      next.add(day);
    }
    // Selecting all 7 == "every day" == empty set (domain convention).
    if (next.length == 7) {
      onChanged(const <int>{});
    } else {
      onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAll = selected.isEmpty;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Row(
        children: List<Widget>.generate(7, (i) {
          final day = i + 1;
          final isSel = isAll || selected.contains(day);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: enabled ? () => _toggle(day) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary600 : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color:
                          isSel ? AppColors.primary700 : AppColors.neutral200,
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _labels[i],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color:
                          isSel ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
