import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../log_reading/domain/glucose_log_entry.dart';
import '../../../log_reading/domain/repositories/glucose_log_repository.dart';

enum TrendsStatus { initial, loading, ready, failure }

class TrendsState extends Equatable {
  const TrendsState({
    this.status = TrendsStatus.initial,
    this.logs = const [],
    this.errorMessage,
  });

  final TrendsStatus status;
  final List<GlucoseLogEntry> logs;
  final String? errorMessage;

  bool get isLoading => status == TrendsStatus.loading;

  TrendsState copyWith({
    TrendsStatus? status,
    List<GlucoseLogEntry>? logs,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TrendsState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, logs, errorMessage];
}

/// Loads glucose history from Firestore for analytics and charts.
class TrendsCubit extends Cubit<TrendsState> {
  TrendsCubit({
    required this.logRepository,
    required this.authRepository,
  }) : super(const TrendsState());

  final GlucoseLogRepository logRepository;
  final AuthRepository authRepository;

  StreamSubscription<List<GlucoseLogEntry>>? _sub;

  void startListening() {
    final user = authRepository.getCurrentUser();
    if (user == null) {
      emit(state.copyWith(
        status: TrendsStatus.failure,
        errorMessage: 'You need to be signed in to view trends.',
      ));
      return;
    }

    emit(state.copyWith(status: TrendsStatus.loading, clearError: true));

    _sub?.cancel();
    _sub = logRepository.watchRecent(user.uid, limit: 2000).listen(
      (logs) => emit(state.copyWith(
        status: TrendsStatus.ready,
        logs: logs,
        clearError: true,
      )),
      onError: (Object e) {
        final message = e is Failure
            ? e.message
            : 'Could not load your glucose history.';
        emit(state.copyWith(
          status: TrendsStatus.failure,
          errorMessage: message,
        ));
      },
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }
}
