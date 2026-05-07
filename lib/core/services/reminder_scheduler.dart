import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/log_reading/domain/glucose_log_entry.dart';
import '../../features/reminders/domain/entities/reminder_settings.dart';
import '../../features/reminders/domain/entities/reminder_tap_payload.dart';
import '../../features/reminders/domain/entities/snack_reminder.dart';
import 'notification_service.dart';

/// Copy bundle for a single reminder notification.
class _ReminderCopy {
  const _ReminderCopy(this.title, this.body);
  final String title;
  final String body;
}

/// Result of a single reschedule pass (mostly for debug visibility).
class RescheduleSummary {
  const RescheduleSummary({
    required this.scheduled,
    required this.suppressed,
  });

  final int scheduled;
  final int suppressed;

  @override
  String toString() => 'RescheduleSummary(scheduled=$scheduled, suppressed=$suppressed)';
}

/// Orchestrates meal / fasting / snack reminders on top of the low-
/// level [NotificationService].
///
/// Responsibilities:
///  * Compute the next fire time for each enabled slot.
///  * Apply smart suppression (skip a reminder when a matching log
///    was just saved).
///  * Cancel upcoming reminders immediately when the user logs,
///    so a just-saved reading doesn't trigger a redundant ping.
///  * Own the "last tapped" payload so `LogReadingScreen` can pre-
///    fill the form from a notification deeplink.
///
/// This class is **pure orchestration**. It does not talk to Firebase
/// and is free of UI imports.
class ReminderScheduler {
  ReminderScheduler._();
  static final ReminderScheduler instance = ReminderScheduler._();

  NotificationService get _notifications => NotificationService.instance;

  // ─────────────────────────────────────────────────────────
  // Notification ID map (stable, collision-free)
  // ─────────────────────────────────────────────────────────
  static const int fastingId = 1001;

  static const int breakfastPreId = 1010;
  static const int breakfastPostId = 1011;
  static const int lunchPreId = 1020;
  static const int lunchPostId = 1021;
  static const int dinnerPreId = 1030;
  static const int dinnerPostId = 1031;

  /// Snacks are addressed by a hash of their uuid → range 2000..2999.
  static const int _snackIdBase = 2000;
  static const int _snackIdRange = 1000;

  /// Full range of IDs owned by this scheduler. Anything inside this
  /// range may be cancelled by the scheduler; keep other services off
  /// of these numbers.
  static const int _ownedIdMin = 1000;
  static const int _ownedIdMax = 2999;

  /// Suppression window: if a reading of the same meal+type was saved
  /// within this window around the fire time, skip the notification.
  static const Duration _suppressionWindow = Duration(minutes: 75);

  // ─────────────────────────────────────────────────────────
  // Deeplink payload — last tapped reminder (consumed by UI)
  // ─────────────────────────────────────────────────────────
  final ValueNotifier<ReminderTapPayload?> pendingTap =
      ValueNotifier<ReminderTapPayload?>(null);

  /// Stash a payload that came in via the generic notification-tap
  /// handler. The UI reads + clears it via [consumePendingTap].
  void ingestTapPayload(String? raw) {
    final parsed = ReminderTapPayload.tryDecode(raw);
    if (parsed != null) {
      debugPrint('🔗 Reminder deeplink: ${parsed.toJson()}');
      pendingTap.value = parsed;
    }
  }

  /// Read the last tap payload and clear it in one atomic step, so the
  /// UI consumes it exactly once.
  ReminderTapPayload? consumePendingTap() {
    final v = pendingTap.value;
    pendingTap.value = null;
    return v;
  }

  // ─────────────────────────────────────────────────────────
  // Public API — rescheduling
  // ─────────────────────────────────────────────────────────

  /// Reschedules every enabled reminder in [settings] for its next
  /// future occurrence. Cancels any previously-owned pending alarm
  /// first, so this method is idempotent and safe to call on every
  /// app open.
  ///
  /// [recentLogs] is consulted for smart suppression; pass the most
  /// recent N logs (a few hours is enough) so we don't re-ping a user
  /// who already logged their reading.
  Future<RescheduleSummary> rescheduleAll({
    required ReminderSettings settings,
    List<GlucoseLogEntry> recentLogs = const [],
  }) async {
    if (!_notifications.isInitialized) {
      debugPrint('⚠️ Scheduler: NotificationService not initialized yet');
      return const RescheduleSummary(scheduled: 0, suppressed: 0);
    }

    // Clear all previously-scheduled reminders we own. Any non-owned
    // pending alarms (e.g. future features) are left untouched.
    await _cancelAllOwned();

    if (!settings.masterEnabled) {
      debugPrint('🔕 Reminders master switch OFF — nothing scheduled');
      return const RescheduleSummary(scheduled: 0, suppressed: 0);
    }

    final now = DateTime.now();
    var scheduled = 0;
    var suppressed = 0;

    Future<void> schedule({
      required int id,
      required DateTime when,
      required _ReminderCopy copy,
      required MealLogTag mealTag,
      required GlucoseReadingType readingType,
      String channelId = NotificationService.mealsChannelId,
      String? snackId,
    }) async {
      if (_isSuppressed(
        recentLogs: recentLogs,
        when: when,
        mealTag: mealTag,
        readingType: readingType,
      )) {
        suppressed++;
        debugPrint(
            '⏭️ Suppressed ${copy.title} @ $when — recent log within window');
        return;
      }

      final payload = ReminderTapPayload(
        mealTag: mealTag,
        readingType: readingType,
        snackId: snackId,
      );

      final ok = await _notifications.scheduleAt(
        id: id,
        title: copy.title,
        body: copy.body,
        when: when,
        channelId: channelId,
        payloadOverride: payload.encode(),
      );
      if (ok) scheduled++;
    }

    // ── Fasting (standalone morning reminder) ──────────────────
    if (settings.fastingEnabled) {
      final when = _nextOccurrence(
        now: now,
        time: settings.fastingTime,
        daysOfWeek: const <int>{},
      );
      await schedule(
        id: fastingId,
        when: when,
        copy: _copy.fasting,
        mealTag: MealLogTag.breakfast, // pragmatic default on tap
        readingType: GlucoseReadingType.fasting,
        channelId: NotificationService.remindersChannelId,
      );
    }

    // ── Main meals (breakfast / lunch / dinner) ────────────────
    for (final slot in [
      settings.breakfast,
      settings.lunch,
      settings.dinner,
    ]) {
      if (!slot.enabled) continue;

      if (slot.preMealEnabled) {
        final when = _nextOccurrence(
          now: now,
          time: slot.preMealTime,
          daysOfWeek: slot.daysOfWeek,
        );
        await schedule(
          id: _idForPre(slot.mealTag),
          when: when,
          copy: _copy.preFor(slot.mealTag),
          mealTag: slot.mealTag,
          readingType: GlucoseReadingType.preMeal,
        );
      }

      if (slot.postMealEnabled) {
        final when = _nextOccurrence(
          now: now,
          time: slot.postMealTime,
          daysOfWeek: slot.daysOfWeek,
        );
        await schedule(
          id: _idForPost(slot.mealTag),
          when: when,
          copy: _copy.postFor(slot.mealTag),
          mealTag: slot.mealTag,
          readingType: GlucoseReadingType.postMeal,
        );
      }
    }

    // ── Snacks ─────────────────────────────────────────────────
    for (final snack in settings.snacks) {
      if (!snack.enabled) continue;
      final when = _nextOccurrence(
        now: now,
        time: snack.time,
        daysOfWeek: snack.daysOfWeek,
      );
      await schedule(
        id: _idForSnack(snack.id),
        when: when,
        copy: _copy.snack(snack),
        mealTag: MealLogTag.snack,
        readingType: GlucoseReadingType.preMeal,
        snackId: snack.id,
      );
    }

    final summary =
        RescheduleSummary(scheduled: scheduled, suppressed: suppressed);
    debugPrint('✅ Reminder reschedule complete: $summary');
    return summary;
  }

  /// Cancel only the upcoming reminder that matches the just-saved
  /// log. Call from the Log cubit right after a successful save so
  /// the user isn't pinged for a reading they already recorded.
  Future<void> onLogSaved(GlucoseLogEntry entry) async {
    final id = _idForLoggedEntry(entry);
    if (id == null) return;
    await _notifications.cancel(id);
    debugPrint('🧹 Cancelled upcoming reminder id=$id after log save');
  }

  // ─────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────

  Future<void> _cancelAllOwned() async {
    final pending = await _notifications.getPendingNotifications();
    for (final p in pending) {
      if (p.id >= _ownedIdMin && p.id <= _ownedIdMax) {
        await _notifications.cancel(p.id);
      }
    }
  }

  /// Computes the next `DateTime` (strictly in the future) at which
  /// [time] occurs, restricted to [daysOfWeek] when it isn't empty.
  DateTime _nextOccurrence({
    required DateTime now,
    required TimeOfDay time,
    required Set<int> daysOfWeek,
  }) {
    var candidate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    // If the time already passed today, start checking from tomorrow.
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    // Honour day-of-week filter (ISO 1..7).
    for (var i = 0; i < 7; i++) {
      if (daysOfWeek.isEmpty || daysOfWeek.contains(candidate.weekday)) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }
    // All 7 days disabled → no valid future date; return something
    // far in the future so the scheduler just no-ops.
    return now.add(const Duration(days: 365));
  }

  bool _isSuppressed({
    required List<GlucoseLogEntry> recentLogs,
    required DateTime when,
    required MealLogTag mealTag,
    required GlucoseReadingType readingType,
  }) {
    for (final log in recentLogs) {
      if (log.readingType != readingType) continue;
      // Only match by meal tag for meal-bound reminders.
      if (readingType != GlucoseReadingType.fasting &&
          log.mealTag != mealTag) {
        continue;
      }
      final diff = log.timestamp.difference(when).abs();
      if (diff <= _suppressionWindow) return true;
    }
    return false;
  }

  int? _idForLoggedEntry(GlucoseLogEntry e) {
    switch (e.readingType) {
      case GlucoseReadingType.fasting:
        return fastingId;
      case GlucoseReadingType.preMeal:
        return _idForPre(e.mealTag);
      case GlucoseReadingType.postMeal:
        return _idForPost(e.mealTag);
    }
  }

  int _idForPre(MealLogTag tag) {
    switch (tag) {
      case MealLogTag.breakfast:
        return breakfastPreId;
      case MealLogTag.lunch:
        return lunchPreId;
      case MealLogTag.dinner:
        return dinnerPreId;
      case MealLogTag.snack:
        return breakfastPreId; // unreachable — guarded in UI
    }
  }

  int _idForPost(MealLogTag tag) {
    switch (tag) {
      case MealLogTag.breakfast:
        return breakfastPostId;
      case MealLogTag.lunch:
        return lunchPostId;
      case MealLogTag.dinner:
        return dinnerPostId;
      case MealLogTag.snack:
        return breakfastPostId;
    }
  }

  int _idForSnack(String uuid) {
    // Stable hash → always maps the same uuid to the same id within
    // the snack id range, so the scheduler can cancel/re-schedule it
    // deterministically on every reschedule pass.
    final h = uuid.hashCode & 0x7fffffff;
    return _snackIdBase + (h % _snackIdRange);
  }

  // ─────────────────────────────────────────────────────────
  // Copy bundle
  // ─────────────────────────────────────────────────────────
  static const _ReminderCopyBundle _copy = _ReminderCopyBundle();
}

class _ReminderCopyBundle {
  const _ReminderCopyBundle();

  _ReminderCopy get fasting => const _ReminderCopy(
        'Good morning ☀️',
        'Log your fasting glucose to start your day on track.',
      );

  _ReminderCopy preFor(MealLogTag tag) => switch (tag) {
        MealLogTag.breakfast => const _ReminderCopy(
            'Breakfast time 🍳',
            'Log your pre-breakfast glucose before you eat.',
          ),
        MealLogTag.lunch => const _ReminderCopy(
            'Lunch soon 🥗',
            'Log your pre-lunch glucose before you eat.',
          ),
        MealLogTag.dinner => const _ReminderCopy(
            'Dinner time 🍽️',
            'Log your pre-dinner glucose before you eat.',
          ),
        MealLogTag.snack => const _ReminderCopy(
            'Snack reminder 🍪',
            'Log your glucose before your snack.',
          ),
      };

  _ReminderCopy postFor(MealLogTag tag) => switch (tag) {
        MealLogTag.breakfast => const _ReminderCopy(
            'Post-breakfast check-in',
            'It\'s been 2 hours — log your post-breakfast reading.',
          ),
        MealLogTag.lunch => const _ReminderCopy(
            'Post-lunch check-in',
            'Time to log your post-lunch reading.',
          ),
        MealLogTag.dinner => const _ReminderCopy(
            'Post-dinner check-in',
            'Log your post-dinner reading now.',
          ),
        MealLogTag.snack => const _ReminderCopy(
            'Snack check-in',
            'Time to log your post-snack reading.',
          ),
      };

  _ReminderCopy snack(SnackReminder snack) => _ReminderCopy(
        snack.label.isEmpty ? 'Snack reminder 🍪' : '${snack.label} 🍪',
        'Time to log your glucose around your snack.',
      );
}
