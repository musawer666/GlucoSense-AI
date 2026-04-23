import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../log_reading/domain/glucose_log_entry.dart';
import '../../../log_reading/domain/repositories/glucose_log_repository.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Drives the Home tab.
///
/// Subscribes to the live profile **and** the latest `glucose_logs`
/// rows so the dashboard chart reflects every saved reading, not only
/// denormalized per-type fields on the user document.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required this.profileRepository,
    required this.authRepository,
    required this.logRepository,
  }) : super(const HomeState()) {
    on<HomeSubscribed>(_onSubscribed);
    on<_HomeSnapshotReceived>(_onSnapshot);
    on<_HomeSnapshotFailed>(_onSnapshotFailed);
    on<_HomeLogsReceived>(_onLogs);
  }

  final ProfileRepository profileRepository;
  final AuthRepository authRepository;
  final GlucoseLogRepository logRepository;

  StreamSubscription<UserProfile?>? _sub;
  StreamSubscription<List<GlucoseLogEntry>>? _logsSub;

  Future<void> _onSubscribed(
    HomeSubscribed event,
    Emitter<HomeState> emit,
  ) async {
    final user = authRepository.getCurrentUser();
    if (user == null) {
      emit(state.copyWith(
        status: HomeStatus.failure,
        errorMessage: 'You need to be signed in to view your dashboard.',
      ));
      return;
    }

    emit(state.copyWith(status: HomeStatus.loading, clearError: true));

    await _sub?.cancel();
    await _logsSub?.cancel();

    _sub = profileRepository.watchProfile(user.uid).listen(
      (profile) => add(_HomeSnapshotReceived(profile)),
      onError: (Object error) {
        final message = error is Failure
            ? error.message
            : 'Failed to load your dashboard.';
        add(_HomeSnapshotFailed(message));
      },
    );

    _logsSub = logRepository.watchRecent(user.uid, limit: 14).listen(
      (logs) => add(_HomeLogsReceived(logs)),
      onError: (_) {
        // Logs are supplementary; keep dashboard usable without them.
      },
    );
  }

  void _onLogs(
    _HomeLogsReceived event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(recentLogs: event.logs));
  }

  void _onSnapshot(
    _HomeSnapshotReceived event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(
      status: event.profile == null ? HomeStatus.missingProfile : HomeStatus.ready,
      profile: event.profile,
      clearProfile: event.profile == null,
      clearError: true,
    ));
  }

  void _onSnapshotFailed(
    _HomeSnapshotFailed event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(
      status: HomeStatus.failure,
      errorMessage: event.message,
    ));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _logsSub?.cancel();
    _sub = null;
    _logsSub = null;
    return super.close();
  }
}
