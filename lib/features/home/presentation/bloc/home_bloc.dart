import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../log_reading/domain/glucose_log_entry.dart';
import '../../../log_reading/domain/repositories/glucose_log_repository.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/cubit/shell_profile_cubit.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Drives the Home tab.
///
/// Profile data follows [ShellProfileCubit] (one Firestore listener for
/// the whole shell). Glucose logs still use [GlucoseLogRepository.watchRecent].
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required ShellProfileCubit shellProfileCubit,
    required AuthRepository authRepository,
    required GlucoseLogRepository logRepository,
  })  : _shell = shellProfileCubit,
        _authRepository = authRepository,
        _logRepository = logRepository,
        super(const HomeState()) {
    on<HomeSubscribed>(_onSubscribed);
    on<_HomeShellProfileChanged>(_onShellProfile);
    on<_HomeLogsReceived>(_onLogs);
  }

  final ShellProfileCubit _shell;
  final AuthRepository _authRepository;
  final GlucoseLogRepository _logRepository;

  StreamSubscription<ShellProfileState>? _shellSub;
  StreamSubscription<List<GlucoseLogEntry>>? _logsSub;

  Future<void> _onSubscribed(
    HomeSubscribed event,
    Emitter<HomeState> emit,
  ) async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      emit(state.copyWith(
        status: HomeStatus.failure,
        errorMessage: 'You need to be signed in to view your dashboard.',
      ));
      return;
    }

    emit(state.copyWith(status: HomeStatus.loading, clearError: true));

    await _shellSub?.cancel();
    await _logsSub?.cancel();

    _applyShellToState(_shell.state, emit);
    _shellSub = _shell.stream.listen(
      (shell) => add(_HomeShellProfileChanged(shell)),
    );

    _logsSub = _logRepository.watchRecent(user.uid, limit: 14).listen(
      (logs) => add(_HomeLogsReceived(logs)),
      onError: (_) {
        // Logs are supplementary; keep dashboard usable without them.
      },
    );
  }

  void _onShellProfile(
    _HomeShellProfileChanged event,
    Emitter<HomeState> emit,
  ) {
    _applyShellToState(event.shell, emit);
  }

  void _applyShellToState(
    ShellProfileState shell,
    Emitter<HomeState> emit,
  ) {
    switch (shell.status) {
      case ShellProfileStatus.initial:
      case ShellProfileStatus.loading:
        emit(state.copyWith(status: HomeStatus.loading, clearError: true));
        break;
      case ShellProfileStatus.signedOut:
        emit(state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'You need to be signed in to view your dashboard.',
          clearProfile: true,
        ));
        break;
      case ShellProfileStatus.missingProfile:
        emit(state.copyWith(
          status: HomeStatus.missingProfile,
          clearProfile: true,
          clearError: true,
        ));
        break;
      case ShellProfileStatus.ready:
        emit(state.copyWith(
          status: HomeStatus.ready,
          profile: shell.profile,
          clearError: true,
        ));
        break;
      case ShellProfileStatus.failure:
        emit(state.copyWith(
          status: HomeStatus.failure,
          errorMessage: shell.errorMessage ??
              'We could not load your dashboard. Please try again.',
        ));
        break;
    }
  }

  void _onLogs(
    _HomeLogsReceived event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(recentLogs: event.logs));
  }

  @override
  Future<void> close() async {
    await _shellSub?.cancel();
    await _logsSub?.cancel();
    _shellSub = null;
    _logsSub = null;
    return super.close();
  }
}
