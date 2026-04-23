import '../../../profile/domain/entities/user_profile.dart';
import '../entities/risk_output.dart';
import 'compute_missing_risk_fields.dart';

/// Evaluates diabetes risk from the user's profile + latest glucose
/// readings using a deterministic, explainable heuristic.
///
/// Returns `null` when any required field is missing — callers
/// should surface the missing list from
/// [computeMissingRiskFields] and let the user fill it in.
RiskOutput? predictRisk(UserProfile? profile) {
  if (profile == null) return null;
  final missing = computeMissingRiskFields(profile);
  if (missing.isNotEmpty) return null;

  // Safe to force-unwrap: all of these are guarded by the missing
  // list above.
  final bmi = profile.bmi!;
  final hba1c = profile.hba1c!;
  final fasting = profile.latestFastingMgDl!;
  final pre = profile.latestPreMealMgDl!;
  final post = profile.latestPostMealMgDl!;

  var score = 0.0;

  // BMI: 0.3 lean / 1.2 overweight / 2.2 obese.
  score += bmi > 30
      ? 2.2
      : bmi > 25
          ? 1.2
          : 0.3;

  // HbA1c: 0.2 normal / 1.3 prediabetic / 2.6 diabetic range.
  score += hba1c >= 6.5
      ? 2.6
      : hba1c >= 5.7
          ? 1.3
          : 0.2;

  // Fasting: 0.2 normal / 1.1 impaired / 2.2 diabetic.
  score += fasting >= 126
      ? 2.2
      : fasting >= 100
          ? 1.1
          : 0.2;

  // Pre-meal baseline.
  score += pre >= 130
      ? 1.0
      : pre >= 100
          ? 0.5
          : 0.1;

  // Post-meal spike.
  score += post >= 200
      ? 2.0
      : post >= 140
          ? 1.0
          : 0.3;

  if (profile.hypertension) score += 0.8;
  if (profile.heartDisease) score += 0.8;
  if (profile.familyHistory) score += 0.7;

  if (score >= 7.0) {
    return RiskOutput(
      level: RiskLevel.diabetic,
      label: 'Diabetic',
      confidence: 91,
      explanation:
          'Combined glycemic markers and metabolic context indicate high diabetes risk. Prioritize clinical follow-up promptly.',
      score: score,
    );
  }
  if (score >= 4.2) {
    return RiskOutput(
      level: RiskLevel.prediabetic,
      label: 'Prediabetic',
      confidence: 86,
      explanation:
          'Pattern suggests increased insulin resistance and early dysglycemia. Lifestyle and monitoring interventions are recommended.',
      score: score,
    );
  }
  return RiskOutput(
    level: RiskLevel.normal,
    label: 'Normal',
    confidence: 89,
    explanation:
        'Current profile and glucose trend suggest stable regulation with lower near-term diabetes risk.',
    score: score,
  );
}
