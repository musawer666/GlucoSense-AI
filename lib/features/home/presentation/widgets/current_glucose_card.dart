import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/glucose_recent_trend_chart.dart';
import '../../../log_reading/domain/glucose_log_entry.dart';

enum GlucoseTrend { rising, steady, falling }

extension on GlucoseTrend {
  IconData get icon {
    switch (this) {
      case GlucoseTrend.rising:
        return Icons.north_east_rounded;
      case GlucoseTrend.falling:
        return Icons.south_east_rounded;
      case GlucoseTrend.steady:
        return Icons.east_rounded;
    }
  }

  String get label {
    switch (this) {
      case GlucoseTrend.rising:
        return 'Rising over last 2 hours';
      case GlucoseTrend.falling:
        return 'Falling over last 2 hours';
      case GlucoseTrend.steady:
        return 'Steady over last 2 hours';
    }
  }
}

/// Hero glucose card: header chip, hero value + unit, trend row, recent log chart.
class CurrentGlucoseCard extends StatelessWidget {
  const CurrentGlucoseCard({
    super.key,
    required this.valueMgDl,
    required this.statusLabel,
    required this.inRange,
    required this.trend,
    required this.chartLogs,
  });

  final int? valueMgDl;
  final String statusLabel;
  final bool inRange;
  final GlucoseTrend trend;
  final List<GlucoseLogEntry> chartLogs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  size: 16,
                  color: AppColors.primary700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CURRENT GLUCOSE',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              _StatusPill(label: statusLabel, inRange: inRange),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  valueMgDl?.toString() ?? '—',
                  style: GoogleFonts.manrope(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary700,
                    height: 1.0,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'mg/dL',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(trend.icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  trend.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlucoseRecentTrendChart(
            logs: chartLogs,
            height: 156,
            showValueLabels: true,
            timeBasedXAxis: true,
            showStemSpikes: true,
            highlightLastPoint: true,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.inRange});

  final String label;
  final bool inRange;

  @override
  Widget build(BuildContext context) {
    final bg = inRange ? AppColors.primary100 : AppColors.tertiary100;
    final fg = inRange ? AppColors.primary800 : AppColors.tertiary800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
