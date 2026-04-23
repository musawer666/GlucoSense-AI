/// How the reading was taken — drives Risk / Trends queries by type.
enum GlucoseReadingType { fasting, preMeal, postMeal }

/// Meal context for logging (not profile / medical history).
enum MealLogTag { breakfast, lunch, dinner, snack }

extension MealLogTagX on MealLogTag {
  String get label => switch (this) {
        MealLogTag.breakfast => 'Breakfast',
        MealLogTag.lunch => 'Lunch',
        MealLogTag.dinner => 'Dinner',
        MealLogTag.snack => 'Snack',
      };
}

/// Single glucose log row — domain entity used app-wide (Trends, Risk, Meal, etc.).
class GlucoseLogEntry {
  const GlucoseLogEntry({
    this.id,
    required this.readingType,
    required this.glucoseMgDl,
    required this.mealTag,
    required this.mealName,
    required this.timestamp,
    this.userId = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? timestamp;

  /// Optional stable id when you add remote sync later.
  final String? id;
  final GlucoseReadingType readingType;
  final int glucoseMgDl;
  final MealLogTag mealTag;
  final String mealName;
  final DateTime timestamp;
  final String userId;
  final DateTime createdAt;

  GlucoseLogEntry copyWith({
    String? id,
    GlucoseReadingType? readingType,
    int? glucoseMgDl,
    MealLogTag? mealTag,
    String? mealName,
    DateTime? timestamp,
    String? userId,
    DateTime? createdAt,
  }) {
    return GlucoseLogEntry(
      id: id ?? this.id,
      readingType: readingType ?? this.readingType,
      glucoseMgDl: glucoseMgDl ?? this.glucoseMgDl,
      mealTag: mealTag ?? this.mealTag,
      mealName: mealName ?? this.mealName,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
