part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => const [];
}

/// Start listening to the live profile snapshot.
final class HomeSubscribed extends HomeEvent {
  const HomeSubscribed();
}

// ── Internal events ───────────────────────────────────────────────

final class _HomeSnapshotReceived extends HomeEvent {
  const _HomeSnapshotReceived(this.profile);
  final UserProfile? profile;

  @override
  List<Object?> get props => [profile];
}

final class _HomeSnapshotFailed extends HomeEvent {
  const _HomeSnapshotFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class _HomeLogsReceived extends HomeEvent {
  const _HomeLogsReceived(this.logs);
  final List<GlucoseLogEntry> logs;

  @override
  List<Object?> get props => [logs];
}
