import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/cubit/shell_profile_cubit.dart';
import '../../domain/entities/risk_output.dart';
import '../../domain/repositories/ml_inference_repository.dart';
import '../../domain/services/glucoiq_ml_inference_input_builder.dart';
import '../../domain/services/glucoiq_ml_prediction_mapper.dart';

part 'risk_prediction_event.dart';
part 'risk_prediction_state.dart';

/// Drives the Risk Prediction screen.
///
/// * Profile data follows [ShellProfileCubit] (shared with other shell tabs).
/// * Every field edit is persisted through
///   [ProfileRepository.updateProfileFields] — the UI never touches
///   Firestore directly.
/// * [RiskAnalysisRequested] calls the remote GlucoIQ Flask API with the
///   signed-in user's profile data.
class RiskPredictionBloc
    extends Bloc<RiskPredictionEvent, RiskPredictionState> {
  /// Glucose "latest" fields are written only via Log Reading / backend
  /// denormalization — never patched from this screen.
  static const _denormalizedGlucoseFieldKeys = {
    'latestFastingMgDl',
    'latestPreMealMgDl',
    'latestPostMealMgDl',
    'lastLogMgDl',
    'lastLogType',
  };

  RiskPredictionBloc({
    required this.profileRepository,
    required this.authRepository,
    required this.mlInferenceRepository,
    required this.shellProfileCubit,
  }) : super(const RiskPredictionState()) {
    on<RiskSubscribed>(_onSubscribed);
    on<_RiskShellProfileChanged>(_onShellProfileChanged);
    on<_RiskSnapshotReceived>(_onSnapshot);
    on<RiskProfileFieldsPatched>(_onFieldsPatched);
    on<RiskAnalysisRequested>(_onAnalysisRequested);
    on<RiskResultCleared>(_onResultCleared);
    on<RiskMutationAcknowledged>(_onMutationAcknowledged);
    on<RiskToastAcknowledged>(_onToastAcknowledged);
  }

  final ProfileRepository profileRepository;
  final AuthRepository authRepository;
  final MlInferenceRepository mlInferenceRepository;
  final ShellProfileCubit shellProfileCubit;

  StreamSubscription<ShellProfileState>? _shellSub;
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

    await _shellSub?.cancel();
    void forward(ShellProfileState shell) =>
        add(_RiskShellProfileChanged(shell));
    forward(shellProfileCubit.state);
    _shellSub = shellProfileCubit.stream.listen(forward);
  }

  void _onShellProfileChanged(
    _RiskShellProfileChanged event,
    Emitter<RiskPredictionState> emit,
  ) {
    final shell = event.shell;
    switch (shell.status) {
      case ShellProfileStatus.signedOut:
        emit(state.copyWith(
          status: RiskStatus.failure,
          errorMessage: 'You need to be signed in to use risk prediction.',
        ));
        break;
      case ShellProfileStatus.initial:
      case ShellProfileStatus.loading:
        emit(state.copyWith(status: RiskStatus.loading, clearError: true));
        break;
      case ShellProfileStatus.failure:
        emit(state.copyWith(
          status: RiskStatus.failure,
          errorMessage: shell.errorMessage ??
              'Failed to load your profile.',
        ));
        break;
      case ShellProfileStatus.missingProfile:
        _onSnapshot(const _RiskSnapshotReceived(null), emit);
        break;
      case ShellProfileStatus.ready:
        _onSnapshot(_RiskSnapshotReceived(shell.profile), emit);
        break;
    }
  }

  void _onSnapshot(
    _RiskSnapshotReceived event,
    Emitter<RiskPredictionState> emit,
  ) {
    final profile = event.profile;
    final missing = GlucoiqMlInferenceInputBuilder.missingFieldsForMl(profile);

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

  Future<void> _onFieldsPatched(
    RiskProfileFieldsPatched event,
    Emitter<RiskPredictionState> emit,
  ) async {
    final uid = _uid;
    if (uid == null || event.fields.isEmpty) return;

    final filtered = Map<String, dynamic>.from(event.fields)
      ..removeWhere((k, _) => _denormalizedGlucoseFieldKeys.contains(k));
    if (filtered.isEmpty) return;

    emit(state.copyWith(status: RiskStatus.updating, clearError: true));
    try {
      await profileRepository.updateProfileFields(uid, filtered);
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

  Future<void> _onAnalysisRequested(
    RiskAnalysisRequested event,
    Emitter<RiskPredictionState> emit,
  ) async {
    final profile = state.profile;
    if (profile == null) return;

    final missing = GlucoiqMlInferenceInputBuilder.missingFieldsForMl(profile);
    if (missing.isNotEmpty) {
      emit(
        state.copyWith(
          missingFields: missing,
          toastMessage:
              'Please fill the following first: ${missing.join(', ')}',
          toastIsError: true,
          clearToast: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isPredictionLoading: true,
        clearError: true,
        clearToast: true,
      ),
    );

    try {
      final ml = await mlInferenceRepository.predictDiabetesRisk(profile);
      final result = mapGlucoiqMlPredictionToRiskOutput(ml);
      emit(
        state.copyWith(
          isPredictionLoading: false,
          result: result,
          status: RiskStatus.ready,
        ),
      );
      final uid = _uid;
      if (uid != null) {
        try {
          await profileRepository.saveMlRiskAnalysis(
            uid,
            category: ml.riskCategory,
            confidencePercent: result.confidence,
            advice: ml.advice.trim().isEmpty ? result.explanation : ml.advice,
            probabilitiesPercent: ml.probabilitiesPercent,
          );
        } on Failure catch (failure) {
          if (!isClosed) {
            emit(
              state.copyWith(
                toastMessage:
                    'Analysis completed but could not save to your profile: '
                    '${failure.message}',
                toastIsError: true,
              ),
            );
          }
        }
      }
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          isPredictionLoading: false,
          status: RiskStatus.ready,
          toastMessage: failure.message,
          toastIsError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isPredictionLoading: false,
          status: RiskStatus.ready,
          toastMessage: 'Something went wrong. Please try again.',
          toastIsError: true,
        ),
      );
    }
  }

  void _onResultCleared(
    RiskResultCleared event,
    Emitter<RiskPredictionState> emit,
  ) {
    if (state.result == null) return;
    emit(state.copyWith(clearResult: true));
  }

  void _onMutationAcknowledged(
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

  void _onToastAcknowledged(
    RiskToastAcknowledged event,
    Emitter<RiskPredictionState> emit,
  ) {
    if (state.toastMessage == null) return;
    emit(state.copyWith(clearToast: true));
  }

  /// True when every field that affects the ML payload matches between
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
        a.smokingLabel == b.smokingLabel &&
        a.activityLabel == b.activityLabel &&
        a.latestFastingMgDl == b.latestFastingMgDl &&
        a.latestPreMealMgDl == b.latestPreMealMgDl &&
        a.latestPostMealMgDl == b.latestPostMealMgDl;
  }

  @override
  Future<void> close() async {
    await _shellSub?.cancel();
    _shellSub = null;
    return super.close();
  }
}
