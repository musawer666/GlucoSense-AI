import '../../../profile/domain/entities/user_profile.dart';
import '../entities/risk_output.dart';
import 'glucoiq_ml_prediction_mapper.dart';

/// Rebuilds [RiskOutput] from denormalized fields on [UserProfile] / Firestore.
RiskOutput? savedMlRiskFromUserProfile(UserProfile? profile) {
  if (profile == null) return null;
  final cat = profile.lastMlRiskCategory?.trim();
  if (cat == null || cat.isEmpty) return null;

  final probs = profile.lastMlRiskProbabilities;
  final confidence = profile.lastMlRiskConfidence ?? 0;
  final score = probs != null && probs.isNotEmpty
      ? probs.values.reduce((a, b) => a > b ? a : b)
      : confidence.toDouble();

  return RiskOutput(
    level: riskLevelFromMlCategory(cat),
    label: cat,
    confidence: confidence,
    explanation:
        profile.lastMlRiskAdvice != null &&
                profile.lastMlRiskAdvice!.trim().isNotEmpty
            ? profile.lastMlRiskAdvice!.trim()
            : 'No advice was stored for this result.',
    score: score,
    classProbabilitiesPercent: probs == null || probs.isEmpty
        ? null
        : Map<String, double>.unmodifiable(Map<String, double>.from(probs)),
  );
}
