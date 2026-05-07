import 'package:equatable/equatable.dart';

/// Coarse risk bucket produced by the local heuristic model.
enum RiskLevel { normal, prediabetic, diabetic }

/// Pure domain result of a diabetes-risk evaluation. UI-level
/// presentation concerns (colours, icons) live in the presentation
/// layer and are derived from [level].
class RiskOutput extends Equatable {
  const RiskOutput({
    required this.level,
    required this.label,
    required this.confidence,
    required this.explanation,
    required this.score,
    this.classProbabilitiesPercent,
  });

  final RiskLevel level;
  final String label;

  /// Integer percentage, `0..100`.
  final int confidence;
  final String explanation;

  /// Raw heuristic score, useful for debugging and future analytics.
  final double score;

  /// XGBoost class probabilities (`0..100`) when the remote model returns them.
  final Map<String, double>? classProbabilitiesPercent;

  @override
  List<Object?> get props =>
      [level, label, confidence, explanation, score, classProbabilitiesPercent];
}
