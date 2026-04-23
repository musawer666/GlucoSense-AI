import 'package:equatable/equatable.dart';

import 'meal_photo_analysis.dart';

/// A persisted meal record.
///
/// Either a full meal-photo analysis that the user kept for reference,
/// or a [SmarterAlternative] they explicitly chose to save — the
/// presentational flag [isAlternative] distinguishes the two without
/// forcing separate collections in Firestore.
///
/// Pure domain — no Firestore / Equatable surface leaks into UI code.
class SavedMeal extends Equatable {
  const SavedMeal({
    required this.id,
    required this.savedAt,
    required this.analysis,
    this.currentGlucoseMgDl,
    this.isAlternative = false,
  });

  /// Firestore document id. Never empty for persisted entries.
  final String id;

  /// Client-side timestamp at the moment of save. Falls back to
  /// `DateTime.now()` when the Firestore server timestamp hasn't
  /// resolved yet (brief window during an optimistic write).
  final DateTime savedAt;

  /// The underlying rich analysis — verdict, factors, ingredients,
  /// recommendations, etc. Stored as nested JSON on Firestore.
  final MealPhotoAnalysis analysis;

  /// Glucose reading at save time, if the user had one. `null` renders
  /// as an em-dash in the UI — never a fabricated default.
  final int? currentGlucoseMgDl;

  /// True when this entry was saved from a `SmarterAlternative`
  /// rather than a full meal-photo analysis.
  final bool isAlternative;

  SavedMeal copyWith({
    String? id,
    DateTime? savedAt,
    MealPhotoAnalysis? analysis,
    int? currentGlucoseMgDl,
    bool clearGlucose = false,
    bool? isAlternative,
  }) {
    return SavedMeal(
      id: id ?? this.id,
      savedAt: savedAt ?? this.savedAt,
      analysis: analysis ?? this.analysis,
      currentGlucoseMgDl:
          clearGlucose ? null : (currentGlucoseMgDl ?? this.currentGlucoseMgDl),
      isAlternative: isAlternative ?? this.isAlternative,
    );
  }

  @override
  List<Object?> get props => [
        id,
        savedAt,
        analysis,
        currentGlucoseMgDl,
        isAlternative,
      ];
}
