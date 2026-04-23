import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../colors/app_colors.dart';
import '../../features/log_reading/domain/glucose_log_entry.dart';

/// Home glucose chart using the same visual language as Risk mini bars,
/// but backed by real Home logs.
class GlucoseRecentTrendChart extends StatelessWidget {
  const GlucoseRecentTrendChart({
    super.key,
    required this.logs,
    this.height = 156,
    this.emptyMessage = 'Your trend appears here after you log readings.',
    this.showValueLabels = true,
    this.timeBasedXAxis = true,
    this.showStemSpikes = true,
    this.highlightLastPoint = true,
  });

  final List<GlucoseLogEntry> logs;
  final double height;
  final String emptyMessage;

  /// Shows mg/dL above each bar.
  final bool showValueLabels;

  /// Kept for API compatibility; bars still represent readings in time order.
  final bool timeBasedXAxis;

  /// Kept for API compatibility.
  final bool showStemSpikes;

  /// Highlights newest bar.
  final bool highlightLastPoint;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.neutral200.withValues(alpha: 0.85),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final sorted = List<GlucoseLogEntry>.from(logs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final visible = sorted.length <= 7
        ? sorted
        : sorted.sublist(sorted.length - 7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '${visible.length} reading${visible.length == 1 ? '' : 's'} · '
            'latest in time order',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(
          height: height,
          child: _RiskStyleGlucoseBars(
            entries: visible,
            showValueLabels: showValueLabels,
            highlightLastPoint: highlightLastPoint,
          ),
        ),
      ],
    );
  }
}

class _RiskStyleGlucoseBars extends StatelessWidget {
  const _RiskStyleGlucoseBars({
    required this.entries,
    required this.showValueLabels,
    required this.highlightLastPoint,
  });

  final List<GlucoseLogEntry> entries;
  final bool showValueLabels;
  final bool highlightLastPoint;

  @override
  Widget build(BuildContext context) {
    final values = entries.map((e) => e.glucoseMgDl.toDouble()).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs();
    final fmt = DateFormat('h:mm a');

    double normalize(double v) {
      if (span < 0.001) return 0.62;
      return ((v - minV) / span).clamp(0.0, 1.0);
    }

    double barHeight(double v) => 28 + (normalize(v) * 44);

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(entries.length, (i) {
              final entry = entries[i];
              final isLatest = highlightLastPoint && i == entries.length - 1;
              final color = isLatest ? AppColors.primary300 : AppColors.primary700;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (showValueLabels)
                        Text(
                          '${entry.glucoseMgDl}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (showValueLabels) const SizedBox(height: 4),
                      Container(
                        height: barHeight(entry.glucoseMgDl.toDouble()),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withValues(alpha: 0.95),
                              color.withValues(alpha: 0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fmt.format(entry.timestamp.toLocal()),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
