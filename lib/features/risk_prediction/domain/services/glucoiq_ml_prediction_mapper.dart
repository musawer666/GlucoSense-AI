import '../entities/glucoiq_ml_prediction.dart';
import '../entities/risk_output.dart';

/// Maps API / stored category string to [RiskLevel] (shared with saved profile).
RiskLevel riskLevelFromMlCategory(String raw) {
  final n = raw.trim().toLowerCase();
  if (n.isEmpty) return RiskLevel.normal;
  final isPre = n.contains('pre');
  final isDiabetic = n.contains('diabetic');
  if (isDiabetic && isPre) return RiskLevel.prediabetic;
  if (isDiabetic) return RiskLevel.diabetic;
  if (isPre) return RiskLevel.prediabetic;
  return RiskLevel.normal;
}

/// Maps the Flask API payload to the app's [RiskOutput] for the risk UI.
RiskOutput mapGlucoiqMlPredictionToRiskOutput(GlucoiqMlPrediction prediction) {
  final level = riskLevelFromMlCategory(prediction.riskCategory);
  final confidence = prediction.confidencePercent == null
      ? _confidenceFromLabel(prediction.confidencePercentLabel)
      : prediction.confidencePercent!.round().clamp(0, 100);

  final score = prediction.probabilitiesPercent.isEmpty
      ? confidence.toDouble()
      : prediction.probabilitiesPercent.values
          .reduce((a, b) => a > b ? a : b);

  return RiskOutput(
    level: level,
    label: prediction.riskCategory.trim().isEmpty
        ? _fallbackLabel(level)
        : prediction.riskCategory.trim(),
    confidence: confidence,
    explanation: prediction.advice.trim().isEmpty
        ? 'No additional advice was returned by the model.'
        : prediction.advice.trim(),
    score: score,
    classProbabilitiesPercent: prediction.probabilitiesPercent.isEmpty
        ? null
        : Map<String, double>.unmodifiable(
            Map<String, double>.from(prediction.probabilitiesPercent),
          ),
  );
}

String _fallbackLabel(RiskLevel level) {
  switch (level) {
    case RiskLevel.normal:
      return 'Normal';
    case RiskLevel.prediabetic:
      return 'Prediabetic';
    case RiskLevel.diabetic:
      return 'Diabetic';
  }
}

int _confidenceFromLabel(String label) {
  final t = label.trim();
  if (t.isEmpty) return 0;
  final without = t.endsWith('%') ? t.substring(0, t.length - 1).trim() : t;
  final v = double.tryParse(without);
  if (v == null) return 0;
  return v.round().clamp(0, 100);
}
