import 'dart:convert';

import '../../../log_reading/domain/glucose_log_entry.dart';

/// JSON payload embedded in every scheduled meal/fasting/snack
/// notification. On tap, we parse this to deeplink the user into
/// [LogReadingScreen] with the correct meal tag & reading type pre-
/// selected.
class ReminderTapPayload {
  const ReminderTapPayload({
    required this.mealTag,
    required this.readingType,
    this.snackId,
  });

  final MealLogTag mealTag;
  final GlucoseReadingType readingType;

  /// Present only for user-defined snack reminders.
  final String? snackId;

  /// Marker inside the JSON so `NotificationService`'s generic payload
  /// handler can distinguish our reminders from future payload kinds.
  static const String kindKey = 'reminder.meal';

  Map<String, dynamic> toJson() => {
        'kind': kindKey,
        'mealTag': _mealTagKey(mealTag),
        'readingType': _readingTypeKey(readingType),
        if (snackId != null) 'snackId': snackId,
      };

  String encode() => jsonEncode(toJson());

  /// Returns `null` if the payload is not a reminder or is malformed,
  /// so callers can safely ignore unknown payload kinds.
  static ReminderTapPayload? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return null;
      if (data['kind'] != kindKey) return null;
      return ReminderTapPayload(
        mealTag: _parseMealTag(data['mealTag'] as String?),
        readingType: _parseReadingType(data['readingType'] as String?),
        snackId: data['snackId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static String _mealTagKey(MealLogTag t) => switch (t) {
        MealLogTag.breakfast => 'breakfast',
        MealLogTag.lunch => 'lunch',
        MealLogTag.dinner => 'dinner',
        MealLogTag.snack => 'snack',
      };

  static String _readingTypeKey(GlucoseReadingType t) => switch (t) {
        GlucoseReadingType.fasting => 'fasting',
        GlucoseReadingType.preMeal => 'preMeal',
        GlucoseReadingType.postMeal => 'postMeal',
      };

  static MealLogTag _parseMealTag(String? raw) => switch (raw) {
        'breakfast' => MealLogTag.breakfast,
        'lunch' => MealLogTag.lunch,
        'dinner' => MealLogTag.dinner,
        'snack' => MealLogTag.snack,
        _ => MealLogTag.breakfast,
      };

  static GlucoseReadingType _parseReadingType(String? raw) => switch (raw) {
        'fasting' => GlucoseReadingType.fasting,
        'preMeal' => GlucoseReadingType.preMeal,
        'postMeal' => GlucoseReadingType.postMeal,
        _ => GlucoseReadingType.preMeal,
      };
}
