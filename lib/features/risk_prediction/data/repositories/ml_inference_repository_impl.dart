import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../domain/entities/glucoiq_ml_prediction.dart';
import '../../domain/entities/inference_api_health.dart';
import '../../domain/repositories/ml_inference_repository.dart';
import '../../domain/services/glucoiq_ml_inference_input_builder.dart';
import '../datasources/glucoiq_ml_remote_data_source.dart';
import '../datasources/inference_api_config_remote_data_source.dart';
import '../models/glucoiq_ml_api_models.dart';

class MlInferenceRepositoryImpl implements MlInferenceRepository {
  MlInferenceRepositoryImpl({
    required InferenceApiConfigRemoteDataSource configDataSource,
    required GlucoiqMlRemoteDataSource mlRemoteDataSource,
  })  : _configDataSource = configDataSource,
        _mlRemoteDataSource = mlRemoteDataSource;

  final InferenceApiConfigRemoteDataSource _configDataSource;
  final GlucoiqMlRemoteDataSource _mlRemoteDataSource;

  @override
  Future<InferenceApiHealth> fetchApiHealth() async {
    try {
      final base = await _configDataSource.fetchBaseUrl();
      final json = await _mlRemoteDataSource.getHealth(base);
      return InferenceApiHealthModel.fromJson(json);
    } catch (error) {
      throw mapAnyError(error);
    }
  }

  @override
  Future<GlucoiqMlPrediction> predictDiabetesRisk(UserProfile profile) async {
    try {
      final body = GlucoiqMlInferenceInputBuilder.buildPredictBody(profile);
      final base = await _configDataSource.fetchBaseUrl();
      final json = await _mlRemoteDataSource.postPredict(base, body);
      return GlucoiqMlPredictionModel.fromJson(json);
    } catch (error) {
      throw mapAnyError(error);
    }
  }
}
