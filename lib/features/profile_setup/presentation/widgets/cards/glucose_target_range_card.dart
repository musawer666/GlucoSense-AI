import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/colors/app_colors.dart';
import 'profile_white_card.dart';

/// Dual-thumb range for fasting / target glucose band (mg/dL).
/// Starts at [RangeValues.zero] until the user adjusts the slider.
class GlucoseTargetRangeCard extends StatelessWidget {
  const GlucoseTargetRangeCard({
    super.key,
    required this.values,
    required this.onChanged,
  });

  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;

  static const double _min = 0;
  static const double _max = 400;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final start = values.start.round();
        final end = values.end.round();

        return ProfileWhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: AppColors.primary600,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Target glucose range',
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: (w * 0.02).clamp(6.0, 10.0)),
              Text(
                'Drag both handles to set your personal min and max (mg/dL).',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: (w * 0.05).clamp(14.0, 20.0)),
              Center(
                child: Text(
                  '$start – $end mg/dL',
                  style: GoogleFonts.manrope(
                    fontSize: (w * 0.055).clamp(20.0, 26.0),
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary700,
                  ),
                ),
              ),
              SizedBox(height: (w * 0.035).clamp(10.0, 14.0)),
              RangeSlider(
                values: values,
                min: _min,
                max: _max,
                divisions: 80,
                labels: RangeLabels(
                  '$start',
                  '$end',
                ),
                activeColor: AppColors.primary600,
                inactiveColor: AppColors.neutral200,
                onChanged: onChanged,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '400',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
