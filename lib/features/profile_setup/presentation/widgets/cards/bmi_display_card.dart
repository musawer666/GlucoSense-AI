import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/colors/app_colors.dart';
import '../../utils/bmi_utils.dart';

class BmiDisplayCard extends StatelessWidget {
  const BmiDisplayCard({
    super.key,
    required this.bmi,
  });

  final double? bmi;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final valueSize = (w * 0.085).clamp(28.0, 36.0);
        final bmiValue = bmi;
        final hasValue = bmiValue != null && bmiValue.isFinite;
        final radius = (w * 0.045).clamp(18.0, 22.0);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: (w * 0.05).clamp(18.0, 24.0),
            vertical: (w * 0.045).clamp(16.0, 22.0),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: hasValue
                  ? AppColors.primary200
                  : AppColors.neutral200,
              width: hasValue ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary900.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary100),
                ),
                child: Icon(
                  Icons.monitor_weight_outlined,
                  color: AppColors.primary700,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculated BMI',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          hasValue ? bmiValue.toStringAsFixed(1) : '—',
                          style: GoogleFonts.manrope(
                            fontSize: valueSize,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            color: AppColors.primary700,
                          ),
                        ),
                        if (hasValue) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              'kg/m²',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!hasValue) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Enter height and weight above',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.3,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasValue)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary600,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    bmiRangeLabel(bmiValue),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
