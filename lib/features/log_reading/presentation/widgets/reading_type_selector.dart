import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../domain/glucose_log_entry.dart';

/// Custom animated segmented control for [GlucoseReadingType].
///
/// Renders a pill container with a sliding gradient indicator for premium
/// feel, replacing the default Material [SegmentedButton].
class ReadingTypeSelector extends StatelessWidget {
  const ReadingTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final GlucoseReadingType selected;
  final ValueChanged<GlucoseReadingType> onChanged;

  static const _items = GlucoseReadingType.values;

  String _label(GlucoseReadingType t) => switch (t) {
        GlucoseReadingType.fasting => 'Fasting',
        GlucoseReadingType.preMeal => 'Pre-Meal',
        GlucoseReadingType.postMeal => 'Post-Meal',
      };

  IconData _icon(GlucoseReadingType t) => switch (t) {
        GlucoseReadingType.fasting => Icons.nightlight_round,
        GlucoseReadingType.preMeal => Icons.restaurant_menu_rounded,
        GlucoseReadingType.postMeal => Icons.local_dining_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final idx = _items.indexOf(selected);
    return Container(
      height: 58,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
      ),
      // Measure the *inner* width (after padding) so the sliding
      // indicator aligns with the Row cells and never overflows.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final innerW = constraints.maxWidth;
          final segW = innerW / _items.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                left: idx * segW,
                top: 0,
                bottom: 0,
                width: segW,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary500,
                        AppColors.primary700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary500.withValues(alpha: 0.38),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: _items.map((type) {
                    final isSelected = type == selected;
                    return Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => onChanged(type),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    child: Icon(
                                      _icon(type),
                                      key: ValueKey<bool>(isSelected),
                                      size: 14,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        letterSpacing: 0.1,
                                      ),
                                      child: Text(
                                        _label(type),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
