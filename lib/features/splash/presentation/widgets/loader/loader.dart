import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/colors/app_colors.dart';

/// Animated thin progress line + "Syncing Insights..." — `progress` is 0.0–1.0.
class SplashLoader extends StatelessWidget {
  const SplashLoader({
    super.key,
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final barH = (w * 0.009).clamp(2.0, 4.0);
        final fontSize = (w * 0.034).clamp(12.0, 14.0);
        final horizontal = (w * 0.1).clamp(24.0, 48.0);
        final p = progress.clamp(0.0, 1.0);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: barH,
                  child: LayoutBuilder(
                    builder: (context, barConstraints) {
                      final totalW = barConstraints.maxWidth;
                      final fillW = totalW * p;

                      return Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          ColoredBox(
                            color: AppColors.neutral200.withValues(alpha: 0.65),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: fillW,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    AppColors.primary300,
                                    AppColors.primary500,
                                    AppColors.primary600,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (p > 0.04 && p < 0.995)
                            Positioned(
                              left: (fillW - 2).clamp(0.0, totalW - 2),
                              top: 0,
                              bottom: 0,
                              width: 3,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary100.withValues(
                                        alpha: 0.95,
                                      ),
                                      blurRadius: 6,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: (w * 0.028).clamp(10.0, 16.0)),
              Text(
                'Syncing Insights...',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
