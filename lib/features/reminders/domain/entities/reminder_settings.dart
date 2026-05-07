import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../log_reading/domain/glucose_log_entry.dart';
import 'meal_reminder_slot.dart';
import 'snack_reminder.dart';

/// Root settings object persisted at `users/{uid}/settings/reminders`.
///
/// Holds the master switch, fasting reminder, the three main meal
/// slots (breakfast / lunch / dinner) and a dynamic list of snacks.
class ReminderSettings extends Equatable {
  const ReminderSettings({
    required this.masterEnabled,
    required this.fastingEnabled,
    required this.fastingTime,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snacks,
    this.updatedAt,
  });

  /// Global kill-switch. When `false`, no notification is scheduled,
  /// regardless of per-slot flags.
  final bool masterEnabled;

  final bool fastingEnabled;
  final TimeOfDay fastingTime;

  final MealReminderSlot breakfast;
  final MealReminderSlot lunch;
  final MealReminderSlot dinner;

  final List<SnackReminder> snacks;

  final DateTime? updatedAt;

  /// Convenience accessor keyed by meal tag.
  /// Returns `null` for [MealLogTag.snack] (snacks live in [snacks]).
  MealReminderSlot? slotFor(MealLogTag tag) {
    switch (tag) {
      case MealLogTag.breakfast:
        return breakfast;
      case MealLogTag.lunch:
        return lunch;
      case MealLogTag.dinner:
        return dinner;
      case MealLogTag.snack:
        return null;
    }
  }

  ReminderSettings withSlot(MealReminderSlot slot) {
    switch (slot.mealTag) {
      case MealLogTag.breakfast:
        return copyWith(breakfast: slot);
      case MealLogTag.lunch:
        return copyWith(lunch: slot);
      case MealLogTag.dinner:
        return copyWith(dinner: slot);
      case MealLogTag.snack:
        return this;
    }
  }

  ReminderSettings copyWith({
    bool? masterEnabled,
    bool? fastingEnabled,
    TimeOfDay? fastingTime,
    MealReminderSlot? breakfast,
    MealReminderSlot? lunch,
    MealReminderSlot? dinner,
    List<SnackReminder>? snacks,
    DateTime? updatedAt,
  }) {
    return ReminderSettings(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      fastingEnabled: fastingEnabled ?? this.fastingEnabled,
      fastingTime: fastingTime ?? this.fastingTime,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      snacks: snacks ?? this.snacks,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Production-safe defaults. Used when a user opens reminders for
  /// the first time (no Firestore document yet).
  factory ReminderSettings.defaults() {
    return ReminderSettings(
      masterEnabled: true,
      fastingEnabled: true,
      fastingTime: const TimeOfDay(hour: 7, minute: 0),
      breakfast: MealReminderSlot.defaultFor(MealLogTag.breakfast),
      lunch: MealReminderSlot.defaultFor(MealLogTag.lunch),
      dinner: MealReminderSlot.defaultFor(MealLogTag.dinner),
      snacks: const <SnackReminder>[],
    );
  }

  @override
  List<Object?> get props => [
        masterEnabled,
        fastingEnabled,
        fastingTime.hour,
        fastingTime.minute,
        breakfast,
        lunch,
        dinner,
        snacks,
        updatedAt,
      ];
}
