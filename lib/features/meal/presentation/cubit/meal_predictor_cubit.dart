import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/cubit/shell_profile_cubit.dart';
import '../../domain/entities/meal_photo_analysis.dart';
import '../../domain/repositories/meal_analysis_repository.dart';

part 'meal_predictor_state.dart';

/// Cubit driving the Meal Predictor screen.
///
/// Responsibilities (and ONLY these):
///   • Subscribe to the live [UserProfile] so the screen can show
///     the user's most recent glucose reading in real time.
///   • Own the `analyze` flow (loading / success / error) so the UI
///     never has to juggle Gemini directly.
///   • Hold the currently-displayed [MealPhotoAnalysis] — either a
///     fresh analysis or a re-opened saved meal.
///
/// The *saved meals list* itself is owned by [SavedMealsCubit], which
/// streams from Firestore (`users/{uid}/saved_meals`). Splitting the
/// two cubits keeps responsibilities tight and lets saved meals be
/// reused from the Home tab without coupling to this predictor flow.
class MealPredictorCubit extends Cubit<MealPredictorState> {
  MealPredictorCubit({
    required ShellProfileCubit shellProfileCubit,
    required AuthRepository authRepository,
    required MealAnalysisRepository mealAnalysisRepository,
  })  : _shell = shellProfileCubit,
        _authRepository = authRepository,
        _mealAnalysisRepository = mealAnalysisRepository,
        super(const MealPredictorState());

  final ShellProfileCubit _shell;
  final AuthRepository _authRepository;
  final MealAnalysisRepository _mealAnalysisRepository;

  StreamSubscription<ShellProfileState>? _shellSub;

  /// Kicks off the profile stream. Safe to call multiple times —
  /// the previous subscription (if any) is cancelled first.
  Future<void> subscribe() async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      emit(state.copyWith(
        status: MealPredictorStatus.failure,
        errorMessage: 'You need to be signed in to analyse meals.',
      ));
      return;
    }

    emit(state.copyWith(
      status: MealPredictorStatus.loading,
      clearError: true,
    ));

    await _shellSub?.cancel();
    void applyShell(ShellProfileState shell) {
      switch (shell.status) {
        case ShellProfileStatus.signedOut:
          emit(state.copyWith(
            status: MealPredictorStatus.failure,
            errorMessage: 'You need to be signed in to analyse meals.',
          ));
          break;
        case ShellProfileStatus.initial:
        case ShellProfileStatus.loading:
          emit(state.copyWith(
            status: MealPredictorStatus.loading,
            clearError: true,
          ));
          break;
        case ShellProfileStatus.failure:
          emit(state.copyWith(
            status: MealPredictorStatus.failure,
            errorMessage: shell.errorMessage ??
                'Failed to load your latest glucose reading.',
          ));
          break;
        case ShellProfileStatus.missingProfile:
          emit(state.copyWith(
            status: MealPredictorStatus.ready,
            clearProfile: true,
            clearError: true,
          ));
          break;
        case ShellProfileStatus.ready:
          emit(state.copyWith(
            status: MealPredictorStatus.ready,
            profile: shell.profile,
            clearProfile: shell.profile == null,
            clearError: true,
          ));
          break;
      }
    }

    applyShell(_shell.state);
    _shellSub = _shell.stream.listen(applyShell);
  }

  /// Called when the user taps the edit icon on the glucose card.
  /// Pass `null` to clear the override.
  void setManualGlucose(int? mgDl) {
    if (mgDl == null) {
      emit(state.copyWith(clearManualGlucoseOverride: true));
      return;
    }
    emit(state.copyWith(manualGlucoseOverride: mgDl));
  }

  /// Gemini request. Emits `isAnalyzing: true` while in flight and
  /// either `currentAnalysis` on success or `analysisError` on
  /// failure. Never throws — the UI listens on state.
  Future<void> analyze({
    required String mealName,
    required Uint8List imageBytes,
  }) async {
    emit(state.copyWith(
      isAnalyzing: true,
      clearAnalysisError: true,
    ));

    try {
      final analysis = await _mealAnalysisRepository.analyzeMealPhoto(
        mealName: mealName,
        imageBytes: imageBytes,
        currentGlucoseMgDl: state.effectiveGlucoseMgDl,
        profile: state.profile,
      );

      if (isClosed) return;
      emit(state.copyWith(
        isAnalyzing: false,
        currentAnalysis: analysis,
        clearActiveSavedId: true,
        clearAnalysisError: true,
      ));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(
        isAnalyzing: false,
        analysisError: failure.message,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(
        isAnalyzing: false,
        analysisError: 'Could not analyse this meal. Please try again.',
      ));
    }
  }

  /// Shows a previously-saved meal in the result card (read-only).
  void openSavedAnalysis({
    required MealPhotoAnalysis analysis,
    required String savedId,
  }) {
    emit(state.copyWith(
      currentAnalysis: analysis,
      activeSavedId: savedId,
      clearAnalysisError: true,
    ));
  }

  /// Marks the currently-displayed analysis as saved (so the result
  /// card flips to the "Saved to your meals" badge).
  void markCurrentAsSaved(String savedId) {
    emit(state.copyWith(activeSavedId: savedId));
  }

  /// Resets the result card back to the empty picker.
  void clearAnalysis() {
    emit(state.copyWith(
      clearCurrentAnalysis: true,
      clearActiveSavedId: true,
      clearAnalysisError: true,
      isAnalyzing: false,
    ));
  }

  /// Clears only the non-fatal analyse error banner. Used by the
  /// view after showing the AppResultDialog.
  void dismissAnalysisError() {
    emit(state.copyWith(clearAnalysisError: true));
  }

  @override
  Future<void> close() async {
    await _shellSub?.cancel();
    _shellSub = null;
    return super.close();
  }
}
