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

final class _HomeShellProfileChanged extends HomeEvent {
  const _HomeShellProfileChanged(this.shell);
  final ShellProfileState shell;

  @override
  List<Object?> get props => [shell];
}

final class _HomeLogsReceived extends HomeEvent {
  const _HomeLogsReceived(this.logs);
  final List<GlucoseLogEntry> logs;

  @override
  List<Object?> get props => [logs];
}
