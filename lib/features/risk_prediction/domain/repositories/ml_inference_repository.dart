import '../../../profile/domain/entities/user_profile.dart';
import '../entities/glucoiq_ml_prediction.dart';
import '../entities/inference_api_health.dart';

/// Remote GlucoIQ ML inference (Firestore config + HTTP).
abstract class MlInferenceRepository {
  /// Loads `api_config/inference_api` and calls `GET /health`.
  Future<InferenceApiHealth> fetchApiHealth();

  /// Builds the 12-feature JSON body from [profile] and calls `POST /predict`.
  Future<GlucoiqMlPrediction> predictDiabetesRisk(UserProfile profile);
}
