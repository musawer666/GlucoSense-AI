import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../log_reading/domain/glucose_log_entry.dart';

/// Reminder config for a single main meal (breakfast / lunch / dinner).
///
/// Each meal can independently schedule a **pre-meal** reminder (to log
/// baseline glucose before eating) and a **post-meal** reminder (to log
/// post-prandial glucose ~2h later).
///
/// Snacks do not use this entity — see [SnackReminder].
class MealReminderSlot extends Equatable {
  const MealReminderSlot({
    required this.mealTag,
    required this.enabled,
    required this.preMealEnabled,
    required this.preMealTime,
    required this.postMealEnabled,
    required this.postMealTime,
    this.daysOfWeek = const <int>{},
  }) : assert(
          mealTag != MealLogTag.snack,
          'Use SnackReminder for snack reminders, not MealReminderSlot.',
        );

  /// Which main meal this slot configures. Never [MealLogTag.snack].
  final MealLogTag mealTag;

  /// Master toggle for this whole meal. When `false`, neither pre nor
  /// post reminder fires, regardless of their individual flags.
  final bool enabled;

  final bool preMealEnabled;
  final TimeOfDay preMealTime;

  final bool postMealEnabled;
  final TimeOfDay postMealTime;

  /// Days of the week on which this slot is active.
  /// ISO-8601: Monday = 1, Sunday = 7.
  /// Empty set means **every day** (default).
  final Set<int> daysOfWeek;

  bool isActiveOn(DateTime date) {
    if (daysOfWeek.isEmpty) return true;
    return daysOfWeek.contains(date.weekday);
  }

  MealReminderSlot copyWith({
    MealLogTag? mealTag,
    bool? enabled,
    bool? preMealEnabled,
    TimeOfDay? preMealTime,
    bool? postMealEnabled,
    TimeOfDay? postMealTime,
    Set<int>? daysOfWeek,
  }) {
    return MealReminderSlot(
      mealTag: mealTag ?? this.mealTag,
      enabled: enabled ?? this.enabled,
      preMealEnabled: preMealEnabled ?? this.preMealEnabled,
      preMealTime: preMealTime ?? this.preMealTime,
      postMealEnabled: postMealEnabled ?? this.postMealEnabled,
      postMealTime: postMealTime ?? this.postMealTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }

  /// Sensible clinical defaults for each meal.
  factory MealReminderSlot.defaultFor(MealLogTag tag) {
    switch (tag) {
      case MealLogTag.breakfast:
        return const MealReminderSlot(
          mealTag: MealLogTag.breakfast,
          enabled: true,
          preMealEnabled: true,
          preMealTime: TimeOfDay(hour: 8, minute: 0),
          postMealEnabled: true,
          postMealTime: TimeOfDay(hour: 10, minute: 0),
        );
      case MealLogTag.lunch:
        return const MealReminderSlot(
          mealTag: MealLogTag.lunch,
          enabled: true,
          preMealEnabled: true,
          preMealTime: TimeOfDay(hour: 13, minute: 0),
          postMealEnabled: true,
          postMealTime: TimeOfDay(hour: 15, minute: 0),
        );
      case MealLogTag.dinner:
        return const MealReminderSlot(
          mealTag: MealLogTag.dinner,
          enabled: true,
          preMealEnabled: true,
          preMealTime: TimeOfDay(hour: 19, minute: 0),
          postMealEnabled: true,
          postMealTime: TimeOfDay(hour: 21, minute: 0),
        );
      case MealLogTag.snack:
        throw ArgumentError('Snacks use SnackReminder, not MealReminderSlot.');
    }
  }

  @override
  List<Object?> get props => [
        mealTag,
        enabled,
        preMealEnabled,
        preMealTime.hour,
        preMealTime.minute,
        postMealEnabled,
        postMealTime.hour,
        postMealTime.minute,
        daysOfWeek,
      ];
}
