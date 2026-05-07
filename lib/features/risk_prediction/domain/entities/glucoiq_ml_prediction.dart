import 'package:equatable/equatable.dart';

/// Result of the remote GlucoIQ XGBoost `/predict` endpoint.
///
/// Not to be confused with [RiskOutput], which is the local heuristic.
class GlucoiqMlPrediction extends Equatable {
  const GlucoiqMlPrediction({
    required this.riskCategory,
    required this.confidencePercentLabel,
    required this.confidencePercent,
    required this.probabilitiesPercent,
    required this.advice,
  });

  /// One of `Normal`, `Prediabetic`, `Diabetic` per API contract.
  final String riskCategory;

  /// Raw string from API, e.g. `85.3%`.
  final String confidencePercentLabel;

  /// Parsed `0..100` when the API returns a percentage; `null` if unparsable.
  final double? confidencePercent;

  /// Class name → percentage `0..100` as returned by the API.
  final Map<String, double> probabilitiesPercent;

  final String advice;

  @override
  List<Object?> get props => [
        riskCategory,
        confidencePercentLabel,
        confidencePercent,
        probabilitiesPercent,
        advice,
      ];
}
