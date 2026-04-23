part of 'risk_prediction_bloc.dart';

sealed class RiskPredictionEvent extends Equatable {
  const RiskPredictionEvent();
  @override
  List<Object?> get props => const [];
}

/// Start listening to the live profile snapshot.
final class RiskSubscribed extends RiskPredictionEvent {
  const RiskSubscribed();
}

/// Persist one or more profile fields. Keys are canonical Firestore
/// keys (e.g. `age`, `bmi`, `latestFastingMgDl`). Pass `null` to
/// clear a stored value.
final class RiskProfileFieldsPatched extends RiskPredictionEvent {
  const RiskProfileFieldsPatched(this.fields);
  final Map<String, dynamic> fields;

  @override
  List<Object?> get props => [fields];
}

/// Run the local heuristic over the current state.
final class RiskAnalysisRequested extends RiskPredictionEvent {
  const RiskAnalysisRequested();
}

/// Drop any cached result — e.g. after the user edits an input.
final class RiskResultCleared extends RiskPredictionEvent {
  const RiskResultCleared();
}

/// Clear any one-shot success / failure message after the UI has
/// presented it.
final class RiskMutationAcknowledged extends RiskPredictionEvent {
  const RiskMutationAcknowledged();
}

// ── Internal events (private to the bloc) ─────────────────────────

final class _RiskSnapshotReceived extends RiskPredictionEvent {
  const _RiskSnapshotReceived(this.profile);
  final UserProfile? profile;

  @override
  List<Object?> get props => [profile];
}

final class _RiskSnapshotFailed extends RiskPredictionEvent {
  const _RiskSnapshotFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
