import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/meal_photo_analysis.dart';
import '../../domain/entities/saved_meal.dart';
import '../models/saved_meal_model.dart';

/// Low-level contract for saved-meal persistence. Kept abstract so a
/// fake can replace it in unit tests without Firebase.
abstract class SavedMealRemoteDataSource {
  /// Real-time stream of `users/{userId}/saved_meals`, ordered by
  /// `savedAt` descending.
  Stream<List<SavedMeal>> watchSavedMeals(String userId);

  /// Creates a new document under `users/{userId}/saved_meals` and
  /// returns the resolved [SavedMeal] with its Firestore doc id.
  Future<SavedMeal> save({
    required String userId,
    required MealPhotoAnalysis analysis,
    int? currentGlucoseMgDl,
    bool isAlternative,
  });

  /// Deletes a saved meal by doc id. Swallows "not-found".
  Future<void> delete({required String userId, required String id});
}

/// Firebase-backed implementation.
class SavedMealRemoteDataSourceImpl implements SavedMealRemoteDataSource {
  SavedMealRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _usersCollection = 'users';
  static const _savedMealsSubcollection = 'saved_meals';

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    if (userId.isEmpty) {
      throw const ServerException('You must be signed in to use saved meals.');
    }
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_savedMealsSubcollection);
  }

  @override
  Stream<List<SavedMeal>> watchSavedMeals(String userId) {
    return _collection(userId)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => SavedMealModel.fromSnapshot(d))
              .toList(growable: false),
        );
  }

  @override
  Future<SavedMeal> save({
    required String userId,
    required MealPhotoAnalysis analysis,
    int? currentGlucoseMgDl,
    bool isAlternative = false,
  }) async {
    final ref = _collection(userId).doc();
    await ref.set(SavedMealModel.toCreateMap(
      analysis: analysis,
      currentGlucoseMgDl: currentGlucoseMgDl,
      isAlternative: isAlternative,
    ));

    // Optimistic local echo — the Firestore stream will reconcile with
    // the resolved server timestamp a moment later.
    return SavedMeal(
      id: ref.id,
      savedAt: DateTime.now(),
      analysis: analysis,
      currentGlucoseMgDl: currentGlucoseMgDl,
      isAlternative: isAlternative,
    );
  }

  @override
  Future<void> delete({required String userId, required String id}) async {
    await _collection(userId).doc(id).delete();
  }
}
