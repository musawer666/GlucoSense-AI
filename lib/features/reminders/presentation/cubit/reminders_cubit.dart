import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/reminder_scheduler.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../log_reading/domain/glucose_log_entry.dart';
import '../../../log_reading/domain/repositories/glucose_log_repository.dart';
import '../../domain/entities/reminder_settings.dart';
import '../../domain/entities/snack_reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import 'reminders_state.dart';

/// Drives the Reminders settings screen.
///
/// * Subscribes to the user's Firestore settings doc so the UI stays
///   in sync across devices.
/// * Every mutation is applied optimistically to local state, then
///   persisted; on failure we surface the error but keep the optimistic
///   update so the user can retry without re-toggling.
/// * After every successful save, re-runs the [ReminderScheduler] so
///   alarms reflect the new schedule immediately.
class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit({
    required this.reminderRepository,
    required this.logRepository,
    required this.authRepository,
    ReminderScheduler? scheduler,
  })  : scheduler = scheduler ?? ReminderScheduler.instance,
        super(RemindersState.initial());

  final ReminderRepository reminderRepository;
  final GlucoseLogRepository logRepository;
  final AuthRepository authRepository;
  final ReminderScheduler scheduler;

  static const _uuid = Uuid();

  StreamSubscription<ReminderSettings>? _sub;
  StreamSubscription<List<GlucoseLogEntry>>? _logSub;
  List<GlucoseLogEntry> _recentLogs = const [];
  String? _uid;

  // ─────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────

  Future<void> subscribe() async {
    final user = authRepository.getCurrentUser();
    if (user == null) {
      emit(state.copyWith(
        status: RemindersStatus.error,
        errorMessage: 'You need to be signed in to manage reminders.',
      ));
      return;
    }
    _uid = user.uid;

    emit(state.copyWith(
      status: RemindersStatus.loading,
      clearError: true,
    ));

    await _sub?.cancel();
    _sub = reminderRepository.watch(user.uid).listen(
      (settings) {
        if (isClosed) return;
        emit(state.copyWith(
          status: RemindersStatus.ready,
          settings: settings,
          clearError: true,
        ));
      },
      onError: (Object error) {
        if (isClosed) return;
        emit(state.copyWith(
          status: RemindersStatus.error,
          errorMessage: error is Failure
              ? error.message
              : 'Could not load your reminders. Please try again.',
        ));
      },
    );

    // Log stream (last 12h) feeds smart suppression during reschedule.
    await _logSub?.cancel();
    _logSub = logRepository.watchRecent(user.uid, limit: 24).listen(
      (logs) {
        if (isClosed) return;
        _recentLogs = logs;
      },
      onError: (_) {
        // Non-fatal — suppression will simply be inactive.
        _recentLogs = const [];
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // Master + fasting mutations
  // ─────────────────────────────────────────────────────────

  Future<void> setMasterEnabled(bool v) {
    return _applyAndSave(state.settings.copyWith(masterEnabled: v));
  }

  Future<void> setFastingEnabled(bool v) {
    return _applyAndSave(state.settings.copyWith(fastingEnabled: v));
  }

  Future<void> setFastingTime(TimeOfDay v) {
    return _applyAndSave(state.settings.copyWith(fastingTime: v));
  }

  // ─────────────────────────────────────────────────────────
  // Meal slot mutations (breakfast / lunch / dinner)
  // ─────────────────────────────────────────────────────────

  Future<void> setSlotEnabled(MealLogTag tag, bool v) {
    final slot = state.settings.slotFor(tag);
    if (slot == null) return Future.value();
    return _applyAndSave(
      state.settings.withSlot(slot.copyWith(enabled: v)),
    );
  }

  Future<void> setPreMealEnabled(MealLogTag tag, bool v) {
    final slot = state.settings.slotFor(tag);
    if (slot == null) return Future.value();
    return _applyAndSave(
      state.settings.withSlot(slot.copyWith(preMealEnabled: v)),
    );
  }

  Future<void> setPostMealEnabled(MealLogTag tag, bool v) {
    final slot = state.settings.slotFor(tag);
    if (slot == null) return Future.value();
    return _applyAndSave(
      state.settings.withSlot(slot.copyWith(postMealEnabled: v)),
    );
  }

  Future<void> setPreMealTime(MealLogTag tag, TimeOfDay v) {
    final slot = state.settings.slotFor(tag);
    if (slot == null) return Future.value();
    return _applyAndSave(
      state.settings.withSlot(slot.copyWith(preMealTime: v)),
    );
  }

  Future<void> setPostMealTime(MealLogTag tag, TimeOfDay v) {
    final slot = state.settings.slotFor(tag);
    if (slot == null) return Future.value();
    return _applyAndSave(
      state.settings.withSlot(slot.copyWith(postMealTime: v)),
    );
  }

  Future<void> setSlotDays(MealLogTag tag, Set<int> days) {
    final slot = state.settings.slotFor(tag);
    if (slot == null) return Future.value();
    return _applyAndSave(
      state.settings.withSlot(slot.copyWith(daysOfWeek: days)),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Snacks
  // ─────────────────────────────────────────────────────────

  Future<void> addSnack({
    required String label,
    required TimeOfDay time,
    Set<int> daysOfWeek = const <int>{},
  }) {
    final next = SnackReminder(
      id: _uuid.v4(),
      label: label.trim().isEmpty ? 'Snack' : label.trim(),
      time: time,
      enabled: true,
      daysOfWeek: daysOfWeek,
    );
    final updated = List<SnackReminder>.of(state.settings.snacks)..add(next);
    return _applyAndSave(state.settings.copyWith(snacks: updated));
  }

  Future<void> updateSnack(SnackReminder snack) {
    final updated = state.settings.snacks
        .map((s) => s.id == snack.id ? snack : s)
        .toList(growable: false);
    return _applyAndSave(state.settings.copyWith(snacks: updated));
  }

  Future<void> removeSnack(String id) {
    final updated =
        state.settings.snacks.where((s) => s.id != id).toList(growable: false);
    return _applyAndSave(state.settings.copyWith(snacks: updated));
  }

  Future<void> setSnackEnabled(String id, bool enabled) {
    final snack = state.settings.snacks.firstWhere(
      (s) => s.id == id,
      orElse: () => const SnackReminder(
        id: '',
        label: '',
        time: TimeOfDay(hour: 0, minute: 0),
        enabled: false,
      ),
    );
    if (snack.id.isEmpty) return Future.value();
    return updateSnack(snack.copyWith(enabled: enabled));
  }

  // ─────────────────────────────────────────────────────────
  // Manual controls
  // ─────────────────────────────────────────────────────────

  /// Forces a full reschedule using the current settings + recent logs.
  /// Useful after returning from Android system settings (exact-alarm
  /// permission may have just been granted).
  Future<void> rescheduleNow() async {
    if (!state.settings.masterEnabled) return;
    await scheduler.rescheduleAll(
      settings: state.settings,
      recentLogs: _recentLogs,
    );
  }

  // ─────────────────────────────────────────────────────────
  // Private — shared apply+save+reschedule flow
  // ─────────────────────────────────────────────────────────

  Future<void> _applyAndSave(ReminderSettings next) async {
    final uid = _uid;
    if (uid == null) {
      emit(state.copyWith(
        status: RemindersStatus.error,
        errorMessage: 'You need to be signed in to update reminders.',
      ));
      return;
    }

    // Optimistic UI.
    emit(state.copyWith(
      status: RemindersStatus.saving,
      settings: next,
      clearError: true,
    ));

    try {
      await reminderRepository.save(uid, next);
      if (isClosed) return;

      // Run a fresh scheduling pass using the new config.
      await scheduler.rescheduleAll(
        settings: next,
        recentLogs: _recentLogs,
      );
      if (isClosed) return;

      emit(state.copyWith(
        status: RemindersStatus.ready,
        saveSuccessNonce: state.saveSuccessNonce + 1,
        clearError: true,
      ));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(
        status: RemindersStatus.error,
        errorMessage: f.message,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(
        status: RemindersStatus.error,
        errorMessage: 'Could not save your reminders. Please try again.',
      ));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _logSub?.cancel();
    return super.close();
  }
}
