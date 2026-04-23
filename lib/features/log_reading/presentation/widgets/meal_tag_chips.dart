import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../domain/glucose_log_entry.dart';

/// Animated meal-tag chip row with icons and gradient highlight.
class MealTagChips extends StatelessWidget {
  const MealTagChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final MealLogTag selected;
  final ValueChanged<MealLogTag> onSelected;

  static IconData _icon(MealLogTag t) => switch (t) {
        MealLogTag.breakfast => Icons.wb_sunny_rounded,
        MealLogTag.lunch => Icons.lunch_dining_rounded,
        MealLogTag.dinner => Icons.dinner_dining_rounded,
        MealLogTag.snack => Icons.cookie_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: MealLogTag.values.map((tag) {
        final isSelected = tag == selected;
        return _MealTagChip(
          tag: tag,
          icon: _icon(tag),
          isSelected: isSelected,
          onTap: () => onSelected(tag),
        );
      }).toList(),
    );
  }
}

class _MealTagChip extends StatelessWidget {
  const _MealTagChip({
    required this.tag,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final MealLogTag tag;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary500, AppColors.primary700],
              )
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isSelected ? AppColors.primary600 : AppColors.neutral200,
          width: 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary500.withValues(alpha: 0.32),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color:
                      isSelected ? Colors.white : AppColors.primary700,
                ),
                const SizedBox(width: 6),
                Text(
                  tag.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
