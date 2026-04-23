import 'dart:typed_data';

import '../../../profile/domain/entities/user_profile.dart';
import '../entities/meal_photo_analysis.dart';

/// Abstract contract for "analyse a meal photo" use-cases.
///
/// Implementations may live anywhere (Gemini today, on-device model
/// tomorrow, custom backend after that). Every implementation MUST
/// translate raised errors into typed `Failure`s so the cubit / UI
/// only ever sees domain-level exceptions.
abstract class MealAnalysisRepository {
  /// Analyses [imageBytes] using [mealName] as a hint and returns a
  /// fully-populated [MealPhotoAnalysis] tailored to the supplied
  /// [profile] + [currentGlucoseMgDl].
  ///
  /// [currentGlucoseMgDl] is optional — when null, the analyser
  /// should produce advice based on profile / image alone.
  /// [profile] is optional but strongly recommended.
  Future<MealPhotoAnalysis> analyzeMealPhoto({
    required String mealName,
    required Uint8List imageBytes,
    int? currentGlucoseMgDl,
    UserProfile? profile,
  });
}
