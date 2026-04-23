import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/risk_output.dart';
import '../../domain/usecases/compute_missing_risk_fields.dart';
import '../../domain/usecases/predict_risk.dart';

part 'risk_prediction_event.dart';
part 'risk_prediction_state.dart';

/// Drives the Risk Prediction screen.
///
/// * Subscribes to the realtime profile stream so every edit (made
///   here or anywhere else in the app) is reflected live.
/// * Every field edit is persisted through
///   [ProfileRepository.updateProfileFields] — the UI never touches
///   Firestore directly.
/// * Running the analysis is a pure, local computation — the stream
///   is the single source of truth for the inputs.
class RiskPredictionBloc
    extends Bloc<RiskPredictionEvent, RiskPredictionState> {
  RiskPredictionBloc({
    required this.profileRepository,
    required this.authRepository,
  }) : super(const RiskPredictionState()) {
    on<RiskSubscribed>(_onSubscribed);
    on<_RiskSnapshotReceived>(_onSnapshot);
    on<_RiskSnapshotFailed>(_onSnapshotFailed);
    on<RiskProfileFieldsPatched>(_onFieldsPatched);
    on<RiskAnalysisRequested>(_onAnalysisRequested);
    on<RiskResultCleared>(_onResultCleared);
    on<RiskMutationAcknowledged>(_onMutationAck);
  }

  final ProfileRepository profileRepository;
  final AuthRepository authRepository;

  StreamSubscription<UserProfile?>? _sub;
  String? _uid;

  Future<void> _onSubscribed(
    RiskSubscribed event,
    Emitter<RiskPredictionState> emit,
  ) async {
    final user = authRepository.getCurrentUser();
    if (user == null) {
      emit(state.copyWith(
        status: RiskStatus.failure,
        errorMessage: 'You need to be signed in to use risk prediction.',
      ));
      return;
    }
    _uid = user.uid;

    emit(state.copyWith(status: RiskStatus.loading, clearError: true));

    await _sub?.cancel();
    _sub = profileRepository.watchProfile(user.uid).listen(
      (profile) => add(_RiskSnapshotReceived(profile)),
      onError: (Object error) {
        final message = error is Failure
            ? error.message
            : 'Failed to load your profile.';
        add(_RiskSnapshotFailed(message));
      },
    );
  }

  void _onSnapshot(
    _RiskSnapshotReceived event,
    Emitter<RiskPredictionState> emit,
  ) {
    final profile = event.profile;
    final missing = computeMissingRiskFields(profile);

    // Keep any previously computed result only if every input that
    // fed it is still valid. Any edit makes the prior result stale.
    final keepResult =
        state.result != null && _samePredictionInputs(state.profile, profile);

    emit(state.copyWith(
      status: profile == null ? RiskStatus.missingProfile : RiskStatus.ready,
      profile: profile,
      clearProfile: profile == null,
      missingFields: missing,
      result: keepResult ? state.result : null,
      clearResult: !keepResult,
      clearError: true,
    ));
  }

  void _onSnapshotFailed(
    _RiskSnapshotFailed event,
    Emitter<RiskPredictionState> emit,
  ) {
    emit(state.copyWith(
      status: RiskStatus.failure,
      errorMessage: event.message,
    ));
  }

  Future<void> _onFieldsPatched(
    RiskProfileFieldsPatched event,
    Emitter<RiskPredictionState> emit,
  ) async {
    final uid = _uid;
    if (uid == null || event.fields.isEmpty) return;

    emit(state.copyWith(status: RiskStatus.updating, clearError: true));
    try {
      await profileRepository.updateProfileFields(uid, event.fields);
      // Live snapshot will flip status back to ready.
      emit(state.copyWith(lastMutation: 'Saved', clearError: true));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: RiskStatus.failure,
        errorMessage: failure.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: RiskStatus.failure,
        errorMessage: 'Could not save your change. Please try again.',
      ));
    }
  }

  void _onAnalysisRequested(
    RiskAnalysisRequested event,
    Emitter<RiskPredictionState> emit,
  ) {
    final profile = state.profile;
    if (profile == null) return;
    final missing = computeMissingRiskFields(profile);
    if (missing.isNotEmpty) {
      emit(state.copyWith(missingFields: missing));
      return;
    }
    final result = predictRisk(profile);
    emit(state.copyWith(result: result, clearError: true));
  }

  void _onResultCleared(
    RiskResultCleared event,
    Emitter<RiskPredictionState> emit,
  ) {
    if (state.result == null) return;
    emit(state.copyWith(clearResult: true));
  }

  void _onMutationAck(
    RiskMutationAcknowledged event,
    Emitter<RiskPredictionState> emit,
  ) {
    if (state.lastMutation == null && state.errorMessage == null) return;
    emit(state.copyWith(
      clearError: true,
      clearMutation: true,
      status: state.status == RiskStatus.failure
          ? (state.profile == null
              ? RiskStatus.missingProfile
              : RiskStatus.ready)
          : state.status,
    ));
  }

  /// True when every field used by [predictRisk] matches between
  /// [a] and [b]. Anything else invalidates the cached result.
  bool _samePredictionInputs(UserProfile? a, UserProfile? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.age == b.age &&
        a.biologicalSex == b.biologicalSex &&
        a.bmi == b.bmi &&
        a.hba1c == b.hba1c &&
        a.hypertension == b.hypertension &&
        a.heartDisease == b.heartDisease &&
        a.familyHistory == b.familyHistory &&
        a.latestFastingMgDl == b.latestFastingMgDl &&
        a.latestPreMealMgDl == b.latestPreMealMgDl &&
        a.latestPostMealMgDl == b.latestPostMealMgDl;
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }
}
