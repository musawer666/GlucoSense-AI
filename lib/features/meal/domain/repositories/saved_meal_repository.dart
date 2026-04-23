import '../entities/meal_photo_analysis.dart';
import '../entities/saved_meal.dart';

/// Abstract contract for persisting and observing a user's saved
/// meals. Every call is scoped to a `userId` so the UI can trust that
/// data belongs to the currently-signed-in user.
///
/// Implementations MUST translate raised errors into typed `Failure`s
/// — the Cubit / UI never see raw SDK exceptions.
abstract class SavedMealRepository {
  /// Real-time stream of the user's saved meals, newest first.
  Stream<List<SavedMeal>> watchSavedMeals(String userId);

  /// Persists [analysis] to `users/{userId}/saved_meals/{autoId}` and
  /// returns the resolved [SavedMeal] (with its Firestore doc id).
  Future<SavedMeal> save({
    required String userId,
    required MealPhotoAnalysis analysis,
    int? currentGlucoseMgDl,
    bool isAlternative = false,
  });

  /// Removes a saved meal by doc id. No-ops if the document is
  /// already gone.
  Future<void> delete({required String userId, required String id});
}
