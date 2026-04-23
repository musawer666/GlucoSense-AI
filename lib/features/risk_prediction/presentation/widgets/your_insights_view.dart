import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors/app_colors.dart';

class YourInsightsView extends StatefulWidget {
  const YourInsightsView({super.key});

  @override
  State<YourInsightsView> createState() => _YourInsightsViewState();
}

class _YourInsightsViewState extends State<YourInsightsView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TimeInRangeCard(),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(
              child: _MetricSnapshotCard(
                icon: Icons.sunny,
                title: 'Fasting',
                value: '94',
                unit: 'mg/dL Avg',
                accent: AppColors.secondary500,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricSnapshotCard(
                icon: Icons.restaurant,
                title: 'Post-Meal',
                value: '128',
                unit: 'mg/dL Avg',
                accent: AppColors.tertiary700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _MealPatternsCard(),
      ],
    );
  }
}

class _TimeInRangeCard extends StatelessWidget {
  const _TimeInRangeCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -22,
                child: Container(
                  width: w * 0.45,
                  height: w * 0.34,
                  decoration: BoxDecoration(
                    color: AppColors.primary100.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all((w * 0.05).clamp(16.0, 20.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time in Range',
                                style: GoogleFonts.manrope(
                                  fontSize: 30 * 0.62,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Target: 70 - 180 mg/dL',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary100,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '↗ +5%',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: (w * 0.04).clamp(12.0, 16.0)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '82',
                          style: GoogleFonts.manrope(
                            fontSize: (w * 0.16).clamp(54.0, 66.0),
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary700,
                            height: 0.95,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '%',
                            style: GoogleFonts.manrope(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Avg. 102 mg/dL',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: (w * 0.035).clamp(10.0, 14.0)),
                    const _MiniRangeBars(),
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

class _MiniRangeBars extends StatelessWidget {
  const _MiniRangeBars();

  @override
  Widget build(BuildContext context) {
    const bars = [28.0, 42.0, 26.0, 54.0, 50.0, 30.0, 40.0];
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return SizedBox(
      height: 132,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(bars.length, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: bars[i],
                    decoration: BoxDecoration(
                      color: i == 2 ? AppColors.tertiary300 : AppColors.primary700,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    labels[i],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MetricSnapshotCard extends StatelessWidget {
  const _MetricSnapshotCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all((c.maxWidth * 0.11).clamp(14.0, 18.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 48 * 0.72,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MealPatternsCard extends StatelessWidget {
  const _MealPatternsCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all((w * 0.05).clamp(16.0, 20.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _MealPatternRow(
                  icon: Icons.bakery_dining_rounded,
                  title: 'High Carbs',
                  status: 'Spike +45',
                  statusColor: Color(0xFFB91C1C),
                  barColor: Color(0xFFB91C1C),
                  widthFactor: 0.78,
                  subtitle: 'Often follows pasta or heavy bread meals.',
                ),
                SizedBox(height: 14),
                _MealPatternRow(
                  icon: Icons.water_drop_rounded,
                  title: 'Protein Forward',
                  status: 'Stable +12',
                  statusColor: AppColors.primary700,
                  barColor: AppColors.primary700,
                  widthFactor: 0.45,
                  subtitle: 'Excellent stability post-breakfast.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MealPatternRow extends StatelessWidget {
  const _MealPatternRow({
    required this.icon,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.barColor,
    required this.widthFactor,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String status;
  final Color statusColor;
  final Color barColor;
  final double widthFactor;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: (c.maxWidth * 0.14).clamp(44.0, 54.0),
              height: (c.maxWidth * 0.14).clamp(44.0, 54.0),
              decoration: const BoxDecoration(
                color: AppColors.neutral100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.tertiary700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.manrope(
                            fontSize: 22 * 0.72,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 6,
                      color: AppColors.neutral200,
                      child: FractionallySizedBox(
                        widthFactor: widthFactor,
                        alignment: Alignment.centerLeft,
                        child: Container(color: barColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
