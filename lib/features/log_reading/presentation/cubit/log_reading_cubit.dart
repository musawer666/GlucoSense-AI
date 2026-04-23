import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/glucose_log_entry.dart';
import '../../domain/repositories/glucose_log_repository.dart';
import 'log_reading_state.dart';

/// Log Reading cubit — Firebase-backed.
///
/// * Subscribes to [GlucoseLogRepository.watchRecent] so the list
///   always reflects what's actually in Firestore (including logs
///   saved on other devices).
/// * `submit` persists the new log via the repository, which also
///   atomically updates the user doc's denormalized "latest" fields
///   so the Home + Risk screens refresh instantly.
/// * Form state (reading type, meal tag, glucose text, timestamp) is
///   kept locally — it only lives in the cubit, never in Firestore.
class LogReadingCubit extends Cubit<LogReadingState> {
  LogReadingCubit({
    required this.logRepository,
    required this.authRepository,
  }) : super(LogReadingState.initial());

  final GlucoseLogRepository logRepository;
  final AuthRepository authRepository;

  StreamSubscription<List<GlucoseLogEntry>>? _sub;
  String? _uid;

  /// Starts listening to the logged-in user's `glucose_logs`
  /// subcollection. Safe to call more than once — the previous
  /// subscription is cancelled first.
  Future<void> subscribe() async {
    final user = authRepository.getCurrentUser();
    if (user == null) {
      emit(state.copyWith(
        uiStatus: LogReadingUiStatus.error,
        userMessage: 'You need to be signed in to view your logs.',
      ));
      return;
    }
    _uid = user.uid;

    emit(state.copyWith(
      uiStatus: LogReadingUiStatus.loadingList,
      clearMessage: true,
      clearValidation: true,
    ));

    await _sub?.cancel();
    _sub = logRepository.watchRecent(user.uid).listen(
      (logs) {
        if (isClosed) return;
        // Preserve any transient "saving" / "saved" status; the
        // stream should only move us back to idle from loading.
        final next = state.uiStatus == LogReadingUiStatus.loadingList
            ? LogReadingUiStatus.idle
            : state.uiStatus;
        emit(state.copyWith(
          uiStatus: next,
          recentLogs: logs,
          clearMessage: true,
        ));
      },
      onError: (Object error) {
        if (isClosed) return;
        final message = error is Failure
            ? error.message
            : 'Could not load your logs. Please try again.';
        emit(state.copyWith(
          uiStatus: LogReadingUiStatus.error,
          userMessage: message,
        ));
      },
    );
  }

  // ── Form mutations ─────────────────────────────────────────────

  void setReadingType(GlucoseReadingType v) =>
      emit(state.copyWith(readingType: v, clearValidation: true));

  void setMealTag(MealLogTag v) =>
      emit(state.copyWith(mealTag: v, clearValidation: true));

  void setGlucoseText(String v) =>
      emit(state.copyWith(glucoseText: v, clearValidation: true));

  void setMealName(String v) =>
      emit(state.copyWith(mealName: v, clearValidation: true));

  void setTimestamp(DateTime v) =>
      emit(state.copyWith(timestamp: v, clearValidation: true));

  void clearTransientMessages() {
    emit(state.copyWith(
      uiStatus: LogReadingUiStatus.idle,
      clearMessage: true,
      clearValidation: true,
    ));
  }

  // ── Persistence ────────────────────────────────────────────────

  String? _validate() {
    final g = int.tryParse(state.glucoseText.trim());
    if (g == null || g < 40 || g > 500) {
      return 'Enter a glucose value between 40 and 500 mg/dL.';
    }
    return null;
  }

  Future<void> submit() async {
    final err = _validate();
    if (err != null) {
      emit(state.copyWith(validationMessage: err));
      return;
    }

    final uid = _uid;
    if (uid == null) {
      emit(state.copyWith(
        uiStatus: LogReadingUiStatus.error,
        userMessage: 'You need to be signed in to save a reading.',
      ));
      return;
    }

    final g = int.parse(state.glucoseText.trim());
    // Log Reading no longer collects a free-form meal name — derive
    // it from the reading type / meal tag so [mealName] stays
    // populated for Trends / Home without duplicating Meal Predictor.
    final mealName = state.readingType == GlucoseReadingType.fasting
        ? 'Fasting'
        : state.mealTag.label;

    final entry = GlucoseLogEntry(
      readingType: state.readingType,
      glucoseMgDl: g,
      mealTag: state.mealTag,
      mealName: mealName,
      timestamp: state.timestamp,
      userId: uid,
      createdAt: DateTime.now(),
    );

    emit(state.copyWith(
      uiStatus: LogReadingUiStatus.saving,
      clearMessage: true,
      clearValidation: true,
    ));

    try {
      await logRepository.save(uid, entry);
      if (isClosed) return;
      // The stream will re-emit the updated list; just flip UI to
      // "saved" + clear the form so the user can log another one.
      emit(state.copyWith(
        uiStatus: LogReadingUiStatus.saved,
        glucoseText: '',
        timestamp: DateTime.now(),
        clearMessage: true,
      ));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(
        uiStatus: LogReadingUiStatus.error,
        userMessage: failure.message,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(
        uiStatus: LogReadingUiStatus.error,
        userMessage: 'Could not save your reading. Please try again.',
      ));
    }
  }

  void resetAfterSaveFeedback() {
    emit(state.copyWith(uiStatus: LogReadingUiStatus.idle));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }
}
