import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../domain/glucose_classification.dart';
import '../../domain/glucose_log_entry.dart';

/// Horizontal strip of 3 stat tiles summarizing today's glucose logs.
///
/// Pure function of [logs] — re-renders instantly when a new reading is
/// saved via the cubit's `recentLogs` update.
class TodaySummaryStrip extends StatelessWidget {
  const TodaySummaryStrip({super.key, required this.logs});

  final List<GlucoseLogEntry> logs;

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  _TodayStats get _stats {
    final today = logs.where((e) => _isToday(e.timestamp)).toList();
    if (today.isEmpty) {
      return const _TodayStats(count: 0, avg: null, inRangePct: null);
    }
    final sum = today.fold<int>(0, (a, e) => a + e.glucoseMgDl);
    final avg = (sum / today.length).round();
    final inRange = today
        .where(
          (e) =>
              GlucoseClassifier.classify(e.glucoseMgDl, e.readingType) ==
              GlucoseStatus.normal,
        )
        .length;
    final pct = ((inRange / today.length) * 100).round();
    return _TodayStats(count: today.length, avg: avg, inRangePct: pct);
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats;
    // Each tile self-sizes to its own content on the cross axis so the
    // Row never receives an unbounded height constraint from the outer
    // scroll Column. All three tiles have equivalent vertical layout,
    // so they end up visually aligned without relying on stretch.
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.today_rounded,
            label: 'Today',
            value: '${s.count}',
            suffix: s.count == 1 ? ' log' : ' logs',
            accent: AppColors.secondary500,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.insights_rounded,
            label: 'Average',
            value: s.avg != null ? '${s.avg}' : '—',
            suffix: s.avg != null ? ' mg/dL' : '',
            accent: AppColors.tertiary500,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.check_circle_rounded,
            label: 'In range',
            value: s.inRangePct != null ? '${s.inRangePct}%' : '—',
            suffix: '',
            accent: AppColors.primary600,
          ),
        ),
      ],
    );
  }
}

class _TodayStats {
  const _TodayStats({
    required this.count,
    required this.avg,
    required this.inRangePct,
  });

  final int count;
  final int? avg;
  final int? inRangePct;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.suffix,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String suffix;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: accent),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
              ),
              Text(
                suffix,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
