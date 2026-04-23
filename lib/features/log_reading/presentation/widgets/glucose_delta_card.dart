import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';
import '../../domain/glucose_log_entry.dart';

/// Compact comparison card: current value vs the user's most recent
/// reading of the same [readingType]. Hidden until the user types a
/// value and there is a previous entry of the same type on record.
class GlucoseDeltaCard extends StatelessWidget {
  const GlucoseDeltaCard({
    super.key,
    required this.currentValue,
    required this.readingType,
    required this.recentLogs,
  });

  final int? currentValue;
  final GlucoseReadingType readingType;
  final List<GlucoseLogEntry> recentLogs;

  GlucoseLogEntry? get _lastSameType {
    for (final e in recentLogs) {
      if (e.readingType == readingType) return e;
    }
    return null;
  }

  String _typeLabel() => switch (readingType) {
        GlucoseReadingType.fasting => 'fasting',
        GlucoseReadingType.preMeal => 'pre-meal',
        GlucoseReadingType.postMeal => 'post-meal',
      };

  String _relTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'just now';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final last = _lastSameType;
    final visible = currentValue != null && last != null;
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: !visible ? const SizedBox.shrink() : _Card(
              current: currentValue!,
              last: last,
              typeLabel: _typeLabel(),
              relTime: _relTime(last.timestamp),
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.current,
    required this.last,
    required this.typeLabel,
    required this.relTime,
  });

  final int current;
  final GlucoseLogEntry last;
  final String typeLabel;
  final String relTime;

  @override
  Widget build(BuildContext context) {
    final delta = current - last.glucoseMgDl;
    final isUp = delta > 0;
    final isFlat = delta == 0;
    final color = isFlat
        ? AppColors.neutral600
        : (isUp ? AppColors.tertiary600 : AppColors.primary700);
    final arrow = isFlat
        ? Icons.remove_rounded
        : (isUp
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded);
    final sign = isFlat ? '' : (isUp ? '+' : '');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(arrow, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$sign$delta mg/dL',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'vs last $typeLabel',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Previous: ${last.glucoseMgDl} mg/dL · $relTime',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
