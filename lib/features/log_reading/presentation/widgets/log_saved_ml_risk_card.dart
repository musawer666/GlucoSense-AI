import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../risk_prediction/domain/entities/risk_output.dart';
import '../../../risk_prediction/presentation/pages/risk_prediction_screen.dart';

/// Compact summary of the last saved ML risk result for the Log tab.
class LogSavedMlRiskCard extends StatelessWidget {
  const LogSavedMlRiskCard({
    super.key,
    required this.result,
    this.analyzedAt,
  });

  final RiskOutput result;
  final DateTime? analyzedAt;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(result.level);
    final dateLine = analyzedAt != null ? _fmtDate(analyzedAt!) : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const RiskPredictionScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.14),
                AppColors.primary50.withValues(alpha: 0.55),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.auto_graph_rounded, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest AI risk',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.label,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    if (dateLine != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        dateLine,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutral500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final y = d.year;
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return 'Saved $mm/$dd/$y · $hh:$min';
  }

  Color _accentFor(RiskLevel level) {
    switch (level) {
      case RiskLevel.normal:
        return AppColors.primary700;
      case RiskLevel.prediabetic:
        return AppColors.tertiary700;
      case RiskLevel.diabetic:
        return const Color(0xFFB91C1C);
    }
  }
}
