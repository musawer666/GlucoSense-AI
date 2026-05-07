import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../log_reading/domain/glucose_log_entry.dart';
import '../../domain/entities/meal_reminder_slot.dart';
import '../../domain/entities/reminder_settings.dart';
import '../../domain/entities/snack_reminder.dart';

/// Firestore serialization for [ReminderSettings].
///
/// Stored at `users/{uid}/settings/reminders`.
/// Times are serialized as `"HH:mm"` strings so the Firebase console
/// stays readable. `daysOfWeek` is stored as a `List<int>`.
class ReminderSettingsModel {
  const ReminderSettingsModel._();

  static Map<String, dynamic> toMap(ReminderSettings settings) => {
        'masterEnabled': settings.masterEnabled,
        'fastingEnabled': settings.fastingEnabled,
        'fastingTime': _encodeTime(settings.fastingTime),
        'breakfast': _slotToMap(settings.breakfast),
        'lunch': _slotToMap(settings.lunch),
        'dinner': _slotToMap(settings.dinner),
        'snacks': settings.snacks.map(_snackToMap).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static ReminderSettings fromDocOrDefaults(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final raw = snap.data();
    if (raw == null) return ReminderSettings.defaults();
    return _fromMap(raw);
  }

  static ReminderSettings _fromMap(Map<String, dynamic> data) {
    final defaults = ReminderSettings.defaults();
    return ReminderSettings(
      masterEnabled: data['masterEnabled'] as bool? ?? defaults.masterEnabled,
      fastingEnabled:
          data['fastingEnabled'] as bool? ?? defaults.fastingEnabled,
      fastingTime:
          _decodeTime(data['fastingTime'] as String?) ?? defaults.fastingTime,
      breakfast: _slotFromMap(
        data['breakfast'],
        fallback: defaults.breakfast,
      ),
      lunch: _slotFromMap(data['lunch'], fallback: defaults.lunch),
      dinner: _slotFromMap(data['dinner'], fallback: defaults.dinner),
      snacks: _snacksFromList(data['snacks']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Slot ↔ Map
  // ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> _slotToMap(MealReminderSlot slot) => {
        'mealTag': _mealTagKey(slot.mealTag),
        'enabled': slot.enabled,
        'preMealEnabled': slot.preMealEnabled,
        'preMealTime': _encodeTime(slot.preMealTime),
        'postMealEnabled': slot.postMealEnabled,
        'postMealTime': _encodeTime(slot.postMealTime),
        'daysOfWeek': slot.daysOfWeek.toList()..sort(),
      };

  static MealReminderSlot _slotFromMap(
    dynamic raw, {
    required MealReminderSlot fallback,
  }) {
    if (raw is! Map<String, dynamic>) return fallback;
    final tag = _parseMealTag(raw['mealTag'] as String?) ?? fallback.mealTag;
    if (tag == MealLogTag.snack) return fallback;
    return MealReminderSlot(
      mealTag: tag,
      enabled: raw['enabled'] as bool? ?? fallback.enabled,
      preMealEnabled:
          raw['preMealEnabled'] as bool? ?? fallback.preMealEnabled,
      preMealTime: _decodeTime(raw['preMealTime'] as String?) ??
          fallback.preMealTime,
      postMealEnabled:
          raw['postMealEnabled'] as bool? ?? fallback.postMealEnabled,
      postMealTime: _decodeTime(raw['postMealTime'] as String?) ??
          fallback.postMealTime,
      daysOfWeek: _parseDays(raw['daysOfWeek']),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Snack ↔ Map
  // ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> _snackToMap(SnackReminder s) => {
        'id': s.id,
        'label': s.label,
        'time': _encodeTime(s.time),
        'enabled': s.enabled,
        'daysOfWeek': s.daysOfWeek.toList()..sort(),
      };

  static List<SnackReminder> _snacksFromList(dynamic raw) {
    if (raw is! List) return const <SnackReminder>[];
    return raw.whereType<Map<String, dynamic>>().map((m) {
      return SnackReminder(
        id: (m['id'] as String?) ?? '',
        label: (m['label'] as String?) ?? 'Snack',
        time: _decodeTime(m['time'] as String?) ??
            const TimeOfDay(hour: 16, minute: 0),
        enabled: m['enabled'] as bool? ?? true,
        daysOfWeek: _parseDays(m['daysOfWeek']),
      );
    }).where((s) => s.id.isNotEmpty).toList(growable: false);
  }

  // ──────────────────────────────────────────────────────────────
  // Primitives
  // ──────────────────────────────────────────────────────────────

  static String _encodeTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static TimeOfDay? _decodeTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static Set<int> _parseDays(dynamic raw) {
    if (raw is! List) return const <int>{};
    return raw
        .whereType<num>()
        .map((n) => n.toInt())
        .where((d) => d >= 1 && d <= 7)
        .toSet();
  }

  static DateTime? _parseTimestamp(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    return null;
  }

  static String _mealTagKey(MealLogTag t) => switch (t) {
        MealLogTag.breakfast => 'breakfast',
        MealLogTag.lunch => 'lunch',
        MealLogTag.dinner => 'dinner',
        MealLogTag.snack => 'snack',
      };

  static MealLogTag? _parseMealTag(String? raw) => switch (raw) {
        'breakfast' => MealLogTag.breakfast,
        'lunch' => MealLogTag.lunch,
        'dinner' => MealLogTag.dinner,
        'snack' => MealLogTag.snack,
        _ => null,
      };
}
