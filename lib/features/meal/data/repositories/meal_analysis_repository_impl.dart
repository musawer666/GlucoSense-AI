import 'dart:typed_data';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../domain/entities/meal_photo_analysis.dart';
import '../../domain/repositories/meal_analysis_repository.dart';
import '../datasources/gemini_meal_data_source.dart';

/// Bridges the domain contract to [GeminiMealDataSource] and funnels
/// every raised error through [mapAnyError] so the cubit / UI only
/// ever sees typed `Failure`s.
class MealAnalysisRepositoryImpl implements MealAnalysisRepository {
  MealAnalysisRepositoryImpl({GeminiMealDataSource? dataSource})
      : _dataSource = dataSource ?? GeminiMealDataSourceImpl();

  final GeminiMealDataSource _dataSource;

  @override
  Future<MealPhotoAnalysis> analyzeMealPhoto({
    required String mealName,
    required Uint8List imageBytes,
    int? currentGlucoseMgDl,
    UserProfile? profile,
  }) async {
    try {
      return await _dataSource.analyze(
        mealName: mealName,
        imageBytes: imageBytes,
        currentGlucoseMgDl: currentGlucoseMgDl,
        profile: profile,
      );
    } on AppConfigError catch (e) {
      throw ServerFailure(e.message);
    } catch (error) {
      throw mapAnyError(error);
    }
  }
}
