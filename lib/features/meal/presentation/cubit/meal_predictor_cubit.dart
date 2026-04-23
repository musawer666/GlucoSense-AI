import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
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
    required ProfileRepository profileRepository,
    required AuthRepository authRepository,
    required MealAnalysisRepository mealAnalysisRepository,
  })  : _profileRepository = profileRepository,
        _authRepository = authRepository,
        _mealAnalysisRepository = mealAnalysisRepository,
        super(const MealPredictorState());

  final ProfileRepository _profileRepository;
  final AuthRepository _authRepository;
  final MealAnalysisRepository _mealAnalysisRepository;

  StreamSubscription<UserProfile?>? _profileSub;

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

    await _profileSub?.cancel();
    _profileSub = _profileRepository.watchProfile(user.uid).listen(
      (profile) {
        emit(state.copyWith(
          status: MealPredictorStatus.ready,
          profile: profile,
          clearProfile: profile == null,
          clearError: true,
        ));
      },
      onError: (Object error) {
        final message = error is Failure
            ? error.message
            : 'Failed to load your latest glucose reading.';
        emit(state.copyWith(
          status: MealPredictorStatus.failure,
          errorMessage: message,
        ));
      },
    );
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
    await _profileSub?.cancel();
    _profileSub = null;
    return super.close();
  }
}
