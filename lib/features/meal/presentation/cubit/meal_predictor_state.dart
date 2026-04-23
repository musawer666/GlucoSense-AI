part of 'meal_predictor_cubit.dart';

/// Coarse status used by the view to decide between full-screen
/// loaders vs content. Finer-grained flags (e.g. `isAnalyzing`,
/// `analysisError`) live as individual fields so the UI can light
/// up specific widgets without an avalanche of statuses.
enum MealPredictorStatus { initial, loading, ready, failure }

class MealPredictorState extends Equatable {
  const MealPredictorState({
    this.status = MealPredictorStatus.initial,
    this.profile,
    this.errorMessage,
    this.manualGlucoseOverride,
    this.currentAnalysis,
    this.activeSavedId,
    this.isAnalyzing = false,
    this.analysisError,
  });

  final MealPredictorStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  /// When the user edits the "Current Glucose" field manually, this
  /// value wins over anything coming from the profile stream.
  final int? manualGlucoseOverride;

  /// Active analysis shown in the result card.
  final MealPhotoAnalysis? currentAnalysis;

  /// Non-null when [currentAnalysis] points at a saved-meal record —
  /// puts the card in read-only mode.
  final String? activeSavedId;

  final bool isAnalyzing;
  final String? analysisError;

  /// Resolves the effective "Current Glucose" shown on screen.
  ///
  /// Priority:
  ///   1. Manual override (user tapped the card to edit).
  ///   2. Latest overall reading from Firestore (`lastLogMgDl`).
  ///   3. Latest pre-meal reading (most relevant meal baseline).
  ///   4. Latest post-meal reading.
  ///   5. Latest fasting reading.
  ///   6. `null` — UI renders an em-dash; NO hardcoded default.
  int? get effectiveGlucoseMgDl {
    final override = manualGlucoseOverride;
    if (override != null && override > 0) return override;

    final p = profile;
    if (p == null) return null;
    return p.lastLogMgDl ??
        p.latestPreMealMgDl ??
        p.latestPostMealMgDl ??
        p.latestFastingMgDl;
  }

  /// True when we have at least one real reading — used by the UI
  /// to decide whether to show the "live" indicator.
  bool get hasRealGlucoseReading => effectiveGlucoseMgDl != null;

  MealPredictorState copyWith({
    MealPredictorStatus? status,
    UserProfile? profile,
    bool clearProfile = false,
    String? errorMessage,
    bool clearError = false,
    int? manualGlucoseOverride,
    bool clearManualGlucoseOverride = false,
    MealPhotoAnalysis? currentAnalysis,
    bool clearCurrentAnalysis = false,
    String? activeSavedId,
    bool clearActiveSavedId = false,
    bool? isAnalyzing,
    String? analysisError,
    bool clearAnalysisError = false,
  }) {
    return MealPredictorState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
      manualGlucoseOverride: clearManualGlucoseOverride
          ? null
          : (manualGlucoseOverride ?? this.manualGlucoseOverride),
      currentAnalysis: clearCurrentAnalysis
          ? null
          : (currentAnalysis ?? this.currentAnalysis),
      activeSavedId: clearActiveSavedId
          ? null
          : (activeSavedId ?? this.activeSavedId),
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      analysisError: clearAnalysisError
          ? null
          : (analysisError ?? this.analysisError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        profile,
        errorMessage,
        manualGlucoseOverride,
        currentAnalysis,
        activeSavedId,
        isAnalyzing,
        analysisError,
      ];
}
