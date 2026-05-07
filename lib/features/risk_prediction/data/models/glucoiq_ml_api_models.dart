import '../../domain/entities/glucoiq_ml_prediction.dart';
import '../../domain/entities/inference_api_health.dart';

class InferenceApiHealthModel extends InferenceApiHealth {
  const InferenceApiHealthModel({
    required super.status,
    required super.model,
    required super.version,
    required super.inputFeatures,
    required super.outputClasses,
  });

  factory InferenceApiHealthModel.fromJson(Map<String, dynamic> json) {
    final rawInputs = json['input_features'];
    final rawOutputs = json['output_classes'];
    return InferenceApiHealthModel(
      status: json['status'] as String? ?? '',
      model: json['model'] as String? ?? '',
      version: json['version'] as String? ?? '',
      inputFeatures: rawInputs is List
          ? rawInputs.map((e) => e.toString()).toList(growable: false)
          : const [],
      outputClasses: rawOutputs is List
          ? rawOutputs.map((e) => e.toString()).toList(growable: false)
          : const [],
    );
  }
}

class GlucoiqMlPredictionModel extends GlucoiqMlPrediction {
  const GlucoiqMlPredictionModel({
    required super.riskCategory,
    required super.confidencePercentLabel,
    required super.confidencePercent,
    required super.probabilitiesPercent,
    required super.advice,
  });

  factory GlucoiqMlPredictionModel.fromJson(Map<String, dynamic> json) {
    final probsRaw = json['Probabilities'];
    final probs = <String, double>{};
    if (probsRaw is Map) {
      for (final e in probsRaw.entries) {
        final v = e.value;
        if (v is num) {
          probs[e.key.toString()] = v.toDouble();
        }
      }
    }

    final confLabel = json['Confidence']?.toString() ?? '';
    final parsedConf = _parsePercentString(confLabel);

    return GlucoiqMlPredictionModel(
      riskCategory: json['Risk_Category']?.toString() ?? '',
      confidencePercentLabel: confLabel,
      confidencePercent: parsedConf,
      probabilitiesPercent: Map<String, double>.unmodifiable(probs),
      advice: json['Advice']?.toString() ?? '',
    );
  }

  static double? _parsePercentString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final withoutPct = trimmed.endsWith('%')
        ? trimmed.substring(0, trimmed.length - 1).trim()
        : trimmed;
    return double.tryParse(withoutPct);
  }
}
