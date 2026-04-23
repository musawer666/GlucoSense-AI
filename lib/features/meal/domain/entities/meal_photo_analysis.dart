import 'package:equatable/equatable.dart';

/// Diabetic-safety verdict produced by the meal analyser.
enum MealSafetyVerdict { safe, caution, risky }

/// One ingredient (or nutrient) flagged as unfavourable, plus a
/// short reason and a relative impact score `0..1`.
class IngredientImpact extends Equatable {
  const IngredientImpact({
    required this.label,
    required this.impact,
    required this.reason,
  });

  final String label;

  /// Relative impact `0..1` (1 = worst for a diabetic profile).
  final double impact;

  /// One-sentence explanation safe to render in the UI.
  final String reason;

  @override
  List<Object?> get props => [label, impact, reason];
}

/// Lower-impact meal swap suggested by the analyser (e.g. brown
/// basmati biryani instead of white-rice biryani).
///
/// These are AI-generated — there is no hardcoded fallback in the
/// presentation layer. When the model returns an empty list, the UI
/// simply hides the "Smarter Alternatives" section.
///
/// Every field beyond [name] is optional from the domain's perspective
/// (missing fields render as hidden sections rather than fake data), but
/// the Gemini schema currently requires the model to produce all of them
/// so the detail sheet always has rich content.
class SmarterAlternative extends Equatable {
  const SmarterAlternative({
    required this.name,
    required this.estPeakMgDl,
    required this.reason,
    this.summary = '',
    this.benefits = const <String>[],
    this.portionGuide = '',
  });

  final String name;

  /// Model-estimated post-meal peak glucose in mg/dL for the swap.
  /// Rendered as-is in the UI — no additional math.
  final int estPeakMgDl;

  /// Short one-liner — why this swap is better. Empty string renders
  /// nothing.
  final String reason;

  /// Longer (2-3 sentence) paragraph shown in the alternative detail
  /// sheet. Empty string hides the section.
  final String summary;

  /// Bullet-style highlights (e.g. "Higher fibre", "Lower GI").
  final List<String> benefits;

  /// One-line portion guidance tailored to the user (e.g. "½ cup rice +
  /// 1 roti"). Empty string hides the section.
  final String portionGuide;

  @override
  List<Object?> get props => [
        name,
        estPeakMgDl,
        reason,
        summary,
        benefits,
        portionGuide,
      ];
}

/// Pure domain result of a meal-photo analysis. Renderers (cards,
/// list tiles, etc.) consume this directly — they never see raw
/// model JSON.
class MealPhotoAnalysis extends Equatable {
  const MealPhotoAnalysis({
    required this.verdict,
    required this.headline,
    required this.summary,
    required this.factors,
    required this.problematicIngredients,
    required this.recommendations,
    required this.smarterAlternatives,
    required this.confidence,
    required this.mealName,
  });

  final MealSafetyVerdict verdict;

  /// Short verdict line, e.g. *"Eat with caution"*.
  final String headline;

  /// One- or two-sentence explanation paragraph.
  final String summary;

  /// Bullet chips shown in the "Factors Considered" section
  /// (e.g. "Fasting avg: 96 mg/dL", "Pre-meal avg: 105 mg/dL").
  final List<String> factors;
  final List<IngredientImpact> problematicIngredients;
  final List<String> recommendations;

  /// AI-generated lower-impact swaps tailored to the detected dish.
  /// May be empty.
  final List<SmarterAlternative> smarterAlternatives;

  /// Integer confidence percentage `0..100`.
  final int confidence;
  final String mealName;

  @override
  List<Object?> get props => [
        verdict,
        headline,
        summary,
        factors,
        problematicIngredients,
        recommendations,
        smarterAlternatives,
        confidence,
        mealName,
      ];
}
