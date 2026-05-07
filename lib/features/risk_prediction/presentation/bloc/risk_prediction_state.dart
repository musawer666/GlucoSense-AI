part of 'risk_prediction_bloc.dart';

enum RiskStatus {
  /// Bloc has not started yet (pre-subscription).
  initial,

  /// First snapshot is being resolved.
  loading,

  /// Live snapshot received; ready for interactions.
  ready,

  /// Profile doc does not exist — user must complete setup first.
  missingProfile,

  /// A mutation is in flight.
  updating,

  /// Subscription or mutation failed.
  failure,
}

/// State for the risk-prediction feature.
class RiskPredictionState extends Equatable {
  const RiskPredictionState({
    this.status = RiskStatus.initial,
    this.profile,
    this.missingFields = const [],
    this.result,
    this.errorMessage,
    this.lastMutation,
    this.isPredictionLoading = false,
    this.toastMessage,
    this.toastIsError = false,
  });

  final RiskStatus status;
  final UserProfile? profile;

  /// Human-readable labels of fields still required before an
  /// analysis can be run. Computed on every snapshot (ML contract).
  final List<String> missingFields;

  /// Last computed risk output, or `null` when no analysis has run
  /// (or its inputs have since changed).
  final RiskOutput? result;

  final String? errorMessage;

  /// Transient success message surfaced once to the UI and then
  /// cleared via [RiskMutationAcknowledged].
  final String? lastMutation;

  /// True while `POST /predict` is in flight.
  final bool isPredictionLoading;

  /// One-shot toast — shown in the UI then cleared via [RiskToastAcknowledged].
  final String? toastMessage;

  /// When true, the UI shows [toastMessage] as an error-styled toast.
  final bool toastIsError;

  bool get hasProfile => profile != null;

  /// All fields required by the Flask model are present on the profile.
  bool get isMlInputComplete => hasProfile && missingFields.isEmpty;

  /// Primary action enabled (does not require complete inputs — bloc shows toast if incomplete).
  bool get canTapRunAnalysis =>
      hasProfile && !isUpdating && !isPredictionLoading && !isLoading;

  bool get isUpdating => status == RiskStatus.updating;
  bool get isLoading => status == RiskStatus.loading;
  bool get hasFailure => status == RiskStatus.failure;

  RiskPredictionState copyWith({
    RiskStatus? status,
    UserProfile? profile,
    List<String>? missingFields,
    RiskOutput? result,
    String? errorMessage,
    String? lastMutation,
    bool? isPredictionLoading,
    String? toastMessage,
    bool? toastIsError,
    bool clearProfile = false,
    bool clearResult = false,
    bool clearError = false,
    bool clearMutation = false,
    bool clearToast = false,
  }) {
    return RiskPredictionState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      missingFields: missingFields ?? this.missingFields,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastMutation: clearMutation ? null : (lastMutation ?? this.lastMutation),
      isPredictionLoading: isPredictionLoading ?? this.isPredictionLoading,
      toastMessage: clearToast ? null : (toastMessage ?? this.toastMessage),
      toastIsError: clearToast
          ? false
          : (toastIsError ?? this.toastIsError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        profile,
        missingFields,
        result,
        errorMessage,
        lastMutation,
        isPredictionLoading,
        toastMessage,
        toastIsError,
      ];
}
