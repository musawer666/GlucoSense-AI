import 'package:equatable/equatable.dart';

/// Payload from `GET /health` on the GlucoIQ ML API.
class InferenceApiHealth extends Equatable {
  const InferenceApiHealth({
    required this.status,
    required this.model,
    required this.version,
    required this.inputFeatures,
    required this.outputClasses,
  });

  final String status;
  final String model;
  final String version;
  final List<String> inputFeatures;
  final List<String> outputClasses;

  @override
  List<Object?> get props =>
      [status, model, version, inputFeatures, outputClasses];
}
