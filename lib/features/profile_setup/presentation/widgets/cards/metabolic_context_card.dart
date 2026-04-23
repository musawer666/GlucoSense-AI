import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/colors/app_colors.dart';
import '../../constants/profile_setup_colors.dart';
import 'profile_white_card.dart';

enum DiabetesType { none, type1, type2, prediabetes }

class MetabolicContextCard extends StatelessWidget {
  const MetabolicContextCard({
    super.key,
    required this.diabetesType,
    required this.onDiabetesChanged,
    required this.familyHistory,
    required this.onFamilyHistoryChanged,
  });

  final DiabetesType diabetesType;
  final ValueChanged<DiabetesType> onDiabetesChanged;
  final bool familyHistory;
  final ValueChanged<bool> onFamilyHistoryChanged;

  static const _chips = <(DiabetesType, String)>[
    (DiabetesType.none, 'None'),
    (DiabetesType.type1, 'Type 1'),
    (DiabetesType.type2, 'Type 2'),
    (DiabetesType.prediabetes, 'Pre-diabetes'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return ProfileWhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    color: ProfileSetupColors.metabolicIcon,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Metabolic Context',
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: (w * 0.045).clamp(14.0, 18.0)),
              Text(
                'Diabetes Type',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral600,
                ),
              ),
              SizedBox(height: (w * 0.025).clamp(8.0, 12.0)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _chips.map((e) {
                  final selected = diabetesType == e.$1;
                  return Material(
                    color: selected
                        ? AppColors.primary600
                        : AppColors.neutral200.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () => onDiabetesChanged(e.$1),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Text(
                          e.$2,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: (w * 0.05).clamp(16.0, 22.0)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Family History',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'History of metabolic conditions in immediate family',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: familyHistory,
                    onChanged: onFamilyHistoryChanged,
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return null;
                    }),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary600;
                      }
                      return AppColors.neutral300;
                    }),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
