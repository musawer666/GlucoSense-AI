import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';
import 'glucose_log_entry.dart';

/// Clinical status buckets used to color-code a glucose reading.
///
/// Thresholds follow ADA guidance and are segmented by reading type so
/// the same numeric value is interpreted correctly (e.g. 130 mg/dL is
/// normal pre-meal but elevated post-meal).
enum GlucoseStatus { low, normal, elevated, high }

extension GlucoseStatusX on GlucoseStatus {
  String get label => switch (this) {
        GlucoseStatus.low => 'Low',
        GlucoseStatus.normal => 'Normal',
        GlucoseStatus.elevated => 'Elevated',
        GlucoseStatus.high => 'High',
      };

  Color get color => switch (this) {
        GlucoseStatus.low => AppColors.secondary500,
        GlucoseStatus.normal => AppColors.primary600,
        GlucoseStatus.elevated => AppColors.tertiary500,
        GlucoseStatus.high => AppColors.destructive,
      };

  Color get softColor => switch (this) {
        GlucoseStatus.low => AppColors.secondary50,
        GlucoseStatus.normal => AppColors.primary50,
        GlucoseStatus.elevated => AppColors.tertiary50,
        GlucoseStatus.high => const Color(0xFFFEF2F2),
      };

  IconData get icon => switch (this) {
        GlucoseStatus.low => Icons.arrow_downward_rounded,
        GlucoseStatus.normal => Icons.check_circle_rounded,
        GlucoseStatus.elevated => Icons.trending_up_rounded,
        GlucoseStatus.high => Icons.warning_amber_rounded,
      };

  String get helper => switch (this) {
        GlucoseStatus.low =>
          'Below safe range — consider a fast-acting carb and recheck.',
        GlucoseStatus.normal => "Great — you're in a healthy range.",
        GlucoseStatus.elevated =>
          'Slightly above target — monitor over the next hours.',
        GlucoseStatus.high =>
          'Out of range — follow your care plan guidance.',
      };
}

/// Stateless ADA-aligned classifier for a single glucose reading.
abstract final class GlucoseClassifier {
  GlucoseClassifier._();

  /// Classifies a [value] (mg/dL) against thresholds that vary by
  /// [type]. Any value under 70 mg/dL is always [GlucoseStatus.low].
  static GlucoseStatus classify(int value, GlucoseReadingType type) {
    if (value < 70) return GlucoseStatus.low;
    switch (type) {
      case GlucoseReadingType.fasting:
        if (value < 100) return GlucoseStatus.normal;
        if (value < 126) return GlucoseStatus.elevated;
        return GlucoseStatus.high;
      case GlucoseReadingType.preMeal:
        if (value <= 130) return GlucoseStatus.normal;
        if (value <= 180) return GlucoseStatus.elevated;
        return GlucoseStatus.high;
      case GlucoseReadingType.postMeal:
        if (value < 140) return GlucoseStatus.normal;
        if (value <= 180) return GlucoseStatus.elevated;
        return GlucoseStatus.high;
    }
  }
}
