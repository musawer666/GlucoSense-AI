import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/glucose_log_entry.dart';

/// Firestore-aware mapping for `users/{uid}/glucose_logs/{logId}`.
///
/// Keeps serialization localized so the rest of the app can work with
/// the pure [GlucoseLogEntry] entity without touching Firestore.
class GlucoseLogModel extends GlucoseLogEntry {
  const GlucoseLogModel({
    super.id,
    required super.readingType,
    required super.glucoseMgDl,
    required super.mealTag,
    required super.mealName,
    required super.timestamp,
    super.userId,
    super.createdAt,
  });

  factory GlucoseLogModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap, {
    required String uid,
  }) {
    final data = snap.data() ?? const <String, dynamic>{};
    final ts = data['timestamp'];
    final created = data['createdAt'];
    return GlucoseLogModel(
      id: snap.id,
      userId: uid,
      glucoseMgDl: (data['glucoseMgDl'] as num?)?.toInt() ?? 0,
      readingType: _parseReadingType(data['readingType'] as String?),
      mealTag: _parseMealTag(data['mealTag'] as String?),
      mealName: (data['mealName'] as String?) ?? '',
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  /// Payload for a `set(merge: true)` / `add()` write. `createdAt`
  /// is assigned server-side for reliable ordering; `timestamp`
  /// stays client-picked so the user can back-date a reading.
  Map<String, dynamic> toCreateMap() => {
        'glucoseMgDl': glucoseMgDl,
        'readingType': readingTypeKey,
        'mealTag': mealTagKey,
        'mealName': mealName,
        'timestamp': Timestamp.fromDate(timestamp),
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Canonical string key for the reading type.
  String get readingTypeKey => _readingTypeKey(readingType);

  /// Canonical string key for the meal tag.
  String get mealTagKey => _mealTagKey(mealTag);

  static String _readingTypeKey(GlucoseReadingType t) {
    switch (t) {
      case GlucoseReadingType.fasting:
        return 'fasting';
      case GlucoseReadingType.preMeal:
        return 'preMeal';
      case GlucoseReadingType.postMeal:
        return 'postMeal';
    }
  }

  static String _mealTagKey(MealLogTag t) {
    switch (t) {
      case MealLogTag.breakfast:
        return 'breakfast';
      case MealLogTag.lunch:
        return 'lunch';
      case MealLogTag.dinner:
        return 'dinner';
      case MealLogTag.snack:
        return 'snack';
    }
  }

  static GlucoseReadingType _parseReadingType(String? raw) {
    switch (raw) {
      case 'fasting':
        return GlucoseReadingType.fasting;
      case 'preMeal':
        return GlucoseReadingType.preMeal;
      case 'postMeal':
        return GlucoseReadingType.postMeal;
      default:
        return GlucoseReadingType.fasting;
    }
  }

  static MealLogTag _parseMealTag(String? raw) {
    switch (raw) {
      case 'breakfast':
        return MealLogTag.breakfast;
      case 'lunch':
        return MealLogTag.lunch;
      case 'dinner':
        return MealLogTag.dinner;
      case 'snack':
        return MealLogTag.snack;
      default:
        return MealLogTag.snack;
    }
  }
}
