import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/widgets/gluco_sliver_app_bar.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../log_reading/data/datasources/glucose_log_remote_data_source.dart';
import '../../../log_reading/data/repositories/glucose_log_repository_impl.dart';
import '../../../log_reading/domain/glucose_log_entry.dart';
import '../cubit/trends_cubit.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrendsCubit(
        logRepository: GlucoseLogRepositoryImpl(
          remoteDataSource: GlucoseLogRemoteDataSourceImpl(),
        ),
        authRepository: AuthRepositoryImpl(
          remoteDataSource: AuthRemoteDataSourceImpl(),
        ),
      )..startListening(),
      child: const _TrendsView(),
    );
  }
}

class _TrendsView extends StatefulWidget {
  const _TrendsView();

  @override
  State<_TrendsView> createState() => _TrendsViewState();
}

class _TrendsViewState extends State<_TrendsView> {
  String _period = 'Daily';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final pad = (w * 0.06).clamp(16.0, 24.0);
        return Scaffold(
          backgroundColor: AppColors.neutral50,
          body: Stack(
            children: [
              Positioned(
                top: -120,
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary200.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -140,
                left: -90,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary100.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              BlocBuilder<TrendsCubit, TrendsState>(
                builder: (context, state) {
                  if (state.status == TrendsStatus.failure &&
                      state.logs.isEmpty) {
                    return CustomScrollView(
                      slivers: [
                        const GlucoSliverAppBar(
                          title: 'Trends & Analytics',
                          subtitle: 'Live readings from your log',
                          showBackButton: true,
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.all(pad),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  state.errorMessage ??
                                      'Something went wrong.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: () => context
                                      .read<TrendsCubit>()
                                      .startListening(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final logs = state.logs;
                  final filtered = _filterLogsForMetrics(logs, _period);

                  final fastingAvg = _averageOfType(
                    filtered,
                    GlucoseReadingType.fasting,
                  );
                  final preAvg = _averageOfType(
                    filtered,
                    GlucoseReadingType.preMeal,
                  );
                  final postAvg = _averageOfType(
                    filtered,
                    GlucoseReadingType.postMeal,
                  );
                  final overall = _overallAverage(filtered);
                  final values =
                      filtered.map((e) => e.glucoseMgDl.toDouble()).toList();
                  final variability =
                      values.isEmpty ? null : _stdDev(values);
                  final inRange = filtered.isEmpty
                      ? null
                      : filtered
                                .where(
                                  (e) =>
                                      e.glucoseMgDl >= 70 &&
                                      e.glucoseMgDl <= 180,
                                )
                                .length /
                            filtered.length *
                            100;
                  final highCount =
                      filtered.where((e) => e.glucoseMgDl > 180).length;
                  final lowCount =
                      filtered.where((e) => e.glucoseMgDl < 70).length;

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      const GlucoSliverAppBar(
                        title: 'Trends & Analytics',
                        subtitle: 'Live readings from your log',
                        showBackButton: true,
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (state.isLoading && logs.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 48),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else ...[
                                _PeriodSwitcher(
                                  selected: _period,
                                  onChanged: (v) =>
                                      setState(() => _period = v),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _periodDescription(_period),
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _AnimatedCard(
                                  delay: 40,
                                  child: _periodBarChartCard(
                                    logs: logs,
                                    period: _period,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _AnimatedCard(
                                      delay: 90,
                                      child: _metric(
                                        'Average',
                                        _fmt(overall),
                                        'mg/dL',
                                      ),
                                    ),
                                    _AnimatedCard(
                                      delay: 130,
                                      child: _metric(
                                        'Fasting Avg',
                                        _fmt(fastingAvg),
                                        'mg/dL',
                                      ),
                                    ),
                                    _AnimatedCard(
                                      delay: 170,
                                      child: _metric(
                                        'Pre-Meal Avg',
                                        _fmt(preAvg),
                                        'mg/dL',
                                      ),
                                    ),
                                    _AnimatedCard(
                                      delay: 210,
                                      child: _metric(
                                        'Post-Meal Avg',
                                        _fmt(postAvg),
                                        'mg/dL',
                                      ),
                                    ),
                                    _AnimatedCard(
                                      delay: 250,
                                      child: _metric(
                                        'Variability',
                                        _fmt(variability),
                                        'SD',
                                      ),
                                    ),
                                    _AnimatedCard(
                                      delay: 290,
                                      child: _metric(
                                        'Time in Range',
                                        _fmt(inRange),
                                        '%',
                                      ),
                                    ),
                                    _AnimatedCard(
                                      delay: 330,
                                      child: _metric(
                                        'High Count',
                                        '$highCount',
                                        'events',
                                      ),
                                    ),
                                    _AnimatedCard(
                                      delay: 370,
                                      child: _metric(
                                        'Low Count',
                                        '$lowCount',
                                        'events',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _AnimatedCard(
                                  delay: 420,
                                  child: _mealPatterns(filtered),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Bar chart: **Daily** = last 7 calendar days · **Weekly** = last 6 Mon–Sun
  /// weeks (rolls forward when a new week starts) · **Monthly** = last 6 months.
  Widget _periodBarChartCard({
    required List<GlucoseLogEntry> logs,
    required String period,
  }) {
    final data = _trendBarDataForPeriod(logs, period);
    final highlightIndex = _barHighlightIndex(data.heights);

    return Container(
      height: 256,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            AppColors.primary50.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.heights.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _DayBar(
                      height: data.heights[i],
                      label: data.labels[i],
                      highlighted:
                          highlightIndex >= 0 && i == highlightIndex,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String title, String value, String unit) {
    final palette = _metricPalette(title);
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: palette.shadow.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: palette.iconBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.border),
                  ),
                  child: Icon(
                    _metricIcon(title),
                    size: 16,
                    color: palette.iconColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: palette.titleColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$value $unit',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: palette.valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealPatterns(List<GlucoseLogEntry> logs) {
    final byMeal = <String, List<int>>{};
    for (final e in logs) {
      byMeal
          .putIfAbsent(e.mealTag.label, () => <int>[])
          .add(e.glucoseMgDl);
    }
    final entries = byMeal.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6F8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary200.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal Pattern Summary',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Text(
              'No meal patterns in this period.',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ...entries.take(3).map((e) {
            final avg = e.value.reduce((a, b) => a + b) / e.value.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: e.key.length.isEven
                      ? const Color(0xFFEFF7FF)
                      : const Color(0xFFF2F8F3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: e.key.length.isEven
                        ? const Color(0xFFC8DCF9)
                        : const Color(0xFFCDEBD5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: e.key.length.isEven
                            ? const Color(0xFFDDEBFF)
                            : const Color(0xFFDFF3E4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        size: 15,
                        color: e.key.length.isEven
                            ? const Color(0xFF2D5B9E)
                            : const Color(0xFF1D6E3A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10203A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFD5DFEF)),
                      ),
                      child: Text(
                        '${avg.toStringAsFixed(0)} mg/dL',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1C3C6B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _fmt(double? v) => v == null ? '--' : v.toStringAsFixed(1);

  _MetricPalette _metricPalette(String title) {
    final t = title.toLowerCase();
    if (t.contains('high') || t.contains('low')) {
      return const _MetricPalette(
        background: Color(0xFFFFFBF4),
        border: Color(0xFFF5E7C9),
        iconBackground: Color(0xFFFFF0D8),
        iconColor: Color(0xFF9A5B00),
        titleColor: Color(0xFF6F5C3C),
        valueColor: Color(0xFF2E2413),
        shadow: Color(0xFFE9C982),
      );
    }
    if (t.contains('range') || t.contains('variability')) {
      return const _MetricPalette(
        background: Color(0xFFF5F8FF),
        border: Color(0xFFDCE5F8),
        iconBackground: Color(0xFFE8EFFF),
        iconColor: Color(0xFF2F5EA8),
        titleColor: Color(0xFF4F6186),
        valueColor: Color(0xFF142C59),
        shadow: Color(0xFFB5C7F3),
      );
    }
    return const _MetricPalette(
      background: Color(0xFFF3FFFD),
      border: Color(0xFFC9F1EA),
      iconBackground: Color(0xFFD9F9F1),
      iconColor: Color(0xFF0D6A62),
      titleColor: Color(0xFF4B6271),
      valueColor: Color(0xFF0F1E33),
      shadow: Color(0xFF9EDFD2),
    );
  }

  IconData _metricIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('fasting')) return Icons.wb_sunny_outlined;
    if (t.contains('pre-meal')) return Icons.restaurant_outlined;
    if (t.contains('post-meal')) return Icons.local_dining_outlined;
    if (t.contains('variability')) return Icons.multiline_chart_rounded;
    if (t.contains('range')) return Icons.track_changes_rounded;
    if (t.contains('high')) return Icons.arrow_upward_rounded;
    if (t.contains('low')) return Icons.arrow_downward_rounded;
    return Icons.analytics_outlined;
  }

  double _stdDev(List<double> x) {
    final mean = x.reduce((a, b) => a + b) / x.length;
    final variance =
        x.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
            x.length;
    return math.sqrt(variance);
  }
}

class _TrendBarData {
  const _TrendBarData({
    required this.heights,
    required this.labels,
    required this.title,
    required this.subtitle,
  });

  final List<double> heights;
  final List<String> labels;
  final String title;
  final String subtitle;
}

double _avgToBarHeight(double avg) => (avg - 60).clamp(24, 110).toDouble();

/// Calendar date in the **device local** zone. Firestore often stores UTC;
/// comparing with [DateTime.now] without this mis-buckets days (wrong labels).
DateTime _localCalendarDate(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Monday (local) of the week containing [d]. Dart weekday: Mon = 1 … Sun = 7.
DateTime _startOfWeekMonday(DateTime d) {
  final day = _localCalendarDate(d);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// First day of the month [monthsBefore] months before the **current local** month.
DateTime _monthStartMonthsBefore(int monthsBefore) {
  final today = _localCalendarDate(DateTime.now());
  final anchor = DateTime(today.year, today.month, 1);
  var y = anchor.year;
  var m = anchor.month - monthsBefore;
  while (m <= 0) {
    m += 12;
    y--;
  }
  return DateTime(y, m, 1);
}

_TrendBarData _trendBarDataForPeriod(List<GlucoseLogEntry> all, String period) {
  switch (period) {
    case 'Daily':
      return _dailyTrendBars(all);
    case 'Weekly':
      return _weeklyTrendBars(all);
    case 'Monthly':
    default:
      return _monthlyTrendBars(all);
  }
}

/// **Current week Mon → Sun** (local). Bar = avg mg/dL that calendar day.
_TrendBarData _dailyTrendBars(List<GlucoseLogEntry> all) {
  final today = _localCalendarDate(DateTime.now());
  final monday = _startOfWeekMonday(today);
  final heights = <double>[];
  final labels = <String>[];
  const wd = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  final dFmt = DateFormat('d');
  for (var i = 0; i < 7; i++) {
    final day = monday.add(Duration(days: i));
    final dayLogs = all
        .where((e) => _localCalendarDate(e.timestamp) == day)
        .toList();
    if (dayLogs.isEmpty) {
      heights.add(14);
    } else {
      final avg = dayLogs.map((e) => e.glucoseMgDl).reduce((a, b) => a + b) /
          dayLogs.length;
      heights.add(_avgToBarHeight(avg));
    }
    labels.add('${wd[i]}\n${dFmt.format(day)}');
  }
  return _TrendBarData(
    heights: heights,
    labels: labels,
    title: 'Daily view',
    subtitle: 'This week Mon–Sun (local time) · one bar per day',
  );
}

/// Last **6 Mon–Sun weeks** (local). [start, end) aligned to local midnights.
_TrendBarData _weeklyTrendBars(List<GlucoseLogEntry> all) {
  final nowLocal = DateTime.now().toLocal();
  final thisWeekStart = _startOfWeekMonday(nowLocal);
  final heights = <double>[];
  final labels = <String>[];
  final fmt = DateFormat('MMM d');
  for (var w = 5; w >= 0; w--) {
    final start = thisWeekStart.subtract(Duration(days: 7 * w));
    final end = start.add(const Duration(days: 7));
    final inWeek = all.where((e) {
      final t = e.timestamp.toLocal();
      return !t.isBefore(start) && t.isBefore(end);
    }).toList();
    if (inWeek.isEmpty) {
      heights.add(14);
    } else {
      final avg = inWeek.map((e) => e.glucoseMgDl).reduce((a, b) => a + b) /
          inWeek.length;
      heights.add(_avgToBarHeight(avg));
    }
    labels.add(fmt.format(start));
  }
  return _TrendBarData(
    heights: heights,
    labels: labels,
    title: 'Weekly view',
    subtitle: 'Last 6 weeks (Mon–Sun) · new week shifts the chart',
  );
}

/// Last **6 calendar months** (local), one bar per month.
_TrendBarData _monthlyTrendBars(List<GlucoseLogEntry> all) {
  final heights = <double>[];
  final labels = <String>[];
  final fmt = DateFormat('MMM yy');
  for (var k = 0; k < 6; k++) {
    final start = _monthStartMonthsBefore(5 - k);
    final end = DateTime(start.year, start.month + 1, 1);
    final inMonth = all.where((e) {
      final t = e.timestamp.toLocal();
      return !t.isBefore(start) && t.isBefore(end);
    }).toList();
    if (inMonth.isEmpty) {
      heights.add(14);
    } else {
      final avg = inMonth.map((e) => e.glucoseMgDl).reduce((a, b) => a + b) /
          inMonth.length;
      heights.add(_avgToBarHeight(avg));
    }
    labels.add(fmt.format(start));
  }
  return _TrendBarData(
    heights: heights,
    labels: labels,
    title: 'Monthly view',
    subtitle: 'Last 6 calendar months · one bar per month',
  );
}

/// Lowest bar among **real** readings (ignores empty 14px stubs).
int _barHighlightIndex(List<double> bars) {
  var minIdx = -1;
  var minVal = double.infinity;
  for (var i = 0; i < bars.length; i++) {
    if (bars[i] <= 14) continue;
    if (bars[i] < minVal) {
      minVal = bars[i];
      minIdx = i;
    }
  }
  return minIdx;
}

String _periodDescription(String period) {
  switch (period) {
    case 'Daily':
      return 'Daily: this week Mon–Sun · metrics match the same week.';
    case 'Weekly':
      return 'Weekly: last 6 Mon–Sun weeks (local) · metrics match that span.';
    case 'Monthly':
    default:
      return 'Monthly: last 6 calendar months (local) · metrics match that span.';
  }
}

/// Stats cards use the same time window as the chart for the selected tab.
List<GlucoseLogEntry> _filterLogsForMetrics(
  List<GlucoseLogEntry> all,
  String period,
) {
  if (all.isEmpty) return const [];
  final nowLocal = DateTime.now().toLocal();
  switch (period) {
    case 'Daily':
      final today = _localCalendarDate(nowLocal);
      final monday = _startOfWeekMonday(today);
      final sunday = monday.add(const Duration(days: 6));
      return all.where((e) {
        final ld = _localCalendarDate(e.timestamp);
        return !ld.isBefore(monday) && !ld.isAfter(sunday);
      }).toList();
    case 'Weekly':
      final weekStart = _startOfWeekMonday(nowLocal);
      final rangeStart = weekStart.subtract(const Duration(days: 7 * 5));
      return all.where((e) {
        final t = e.timestamp.toLocal();
        return !t.isBefore(rangeStart);
      }).toList();
    case 'Monthly':
    default:
      final oldest = _monthStartMonthsBefore(5);
      final today = _localCalendarDate(nowLocal);
      final endExclusive = DateTime(today.year, today.month + 1, 1);
      return all.where((e) {
        final t = e.timestamp.toLocal();
        return !t.isBefore(oldest) && t.isBefore(endExclusive);
      }).toList();
  }
}

double? _averageOfType(List<GlucoseLogEntry> logs, GlucoseReadingType type) {
  final subset = logs.where((e) => e.readingType == type).toList();
  if (subset.isEmpty) return null;
  return subset.map((e) => e.glucoseMgDl).reduce((a, b) => a + b) /
      subset.length;
}

double? _overallAverage(List<GlucoseLogEntry> logs) {
  if (logs.isEmpty) return null;
  return logs.map((e) => e.glucoseMgDl).reduce((a, b) => a + b) / logs.length;
}

class _MetricPalette {
  const _MetricPalette({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.iconColor,
    required this.titleColor,
    required this.valueColor,
    required this.shadow,
  });

  final Color background;
  final Color border;
  final Color iconBackground;
  final Color iconColor;
  final Color titleColor;
  final Color valueColor;
  final Color shadow;
}

class _AnimatedCard extends StatefulWidget {
  const _AnimatedCard({required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      offset: _show ? Offset.zero : const Offset(0, 0.06),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 320),
        opacity: _show ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

class _PeriodSwitcher extends StatelessWidget {
  const _PeriodSwitcher({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = <String>['Daily', 'Weekly', 'Monthly'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.neutral300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: items.map((e) {
          final isSelected = selected == e;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onChanged(e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary100 : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary300
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  e,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.primary800
                        : AppColors.neutral700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.height,
    required this.label,
    required this.highlighted,
  });

  final double height;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final barColor = highlighted ? AppColors.tertiary300 : AppColors.primary700;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: height,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          height: 6,
          width: double.infinity,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: AppColors.neutral200,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: label.contains('\n') ? 9 : 10,
            fontWeight: FontWeight.w700,
            color: AppColors.neutral700,
            letterSpacing: 0.2,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}
