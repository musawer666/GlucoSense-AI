import '../../../../core/errors/firebase_error_mapper.dart';
import '../../domain/entities/meal_photo_analysis.dart';
import '../../domain/entities/saved_meal.dart';
import '../../domain/repositories/saved_meal_repository.dart';
import '../datasources/saved_meal_remote_data_source.dart';

/// Thin bridge between the domain contract and the remote data source.
/// Its only job is to funnel every raised error through [mapAnyError]
/// so the Cubit / UI layers see typed `Failure`s exclusively.
class SavedMealRepositoryImpl implements SavedMealRepository {
  SavedMealRepositoryImpl({required this.remoteDataSource});

  final SavedMealRemoteDataSource remoteDataSource;

  @override
  Stream<List<SavedMeal>> watchSavedMeals(String userId) {
    return remoteDataSource
        .watchSavedMeals(userId)
        .handleError((Object error, StackTrace _) => throw mapAnyError(error));
  }

  @override
  Future<SavedMeal> save({
    required String userId,
    required MealPhotoAnalysis analysis,
    int? currentGlucoseMgDl,
    bool isAlternative = false,
  }) async {
    try {
      return await remoteDataSource.save(
        userId: userId,
        analysis: analysis,
        currentGlucoseMgDl: currentGlucoseMgDl,
        isAlternative: isAlternative,
      );
    } catch (error) {
      throw mapAnyError(error);
    }
  }

  @override
  Future<void> delete({required String userId, required String id}) async {
    try {
      await remoteDataSource.delete(userId: userId, id: id);
    } catch (error) {
      throw mapAnyError(error);
    }
  }
}
