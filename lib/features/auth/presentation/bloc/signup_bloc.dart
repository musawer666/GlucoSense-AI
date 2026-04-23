import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';

part 'signup_event.dart';
part 'signup_state.dart';

/// Orchestrates the sign-up flow. All UI ever does is dispatch
/// [SignupSubmitted] / [SignupStatusReset]; Firebase and Firestore
/// are kept strictly behind [AuthRepository].
class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupBloc({required this.authRepository}) : super(const SignupState()) {
    on<SignupSubmitted>(_onSubmitted);
    on<SignupStatusReset>(_onReset);
  }

  final AuthRepository authRepository;

  Future<void> _onSubmitted(
    SignupSubmitted event,
    Emitter<SignupState> emit,
  ) async {
    // Guard against duplicate submissions if the button fires twice
    // or a stale event lands while a request is already in flight.
    if (state.status == SignupStatus.submitting) return;

    emit(state.copyWith(
      status: SignupStatus.submitting,
      clearError: true,
      clearUid: true,
    ));

    try {
      final user = await authRepository.signUpWithEmail(
        email: event.email.trim(),
        password: event.password,
      );

      emit(state.copyWith(
        status: SignupStatus.success,
        uid: user.uid,
        clearError: true,
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: SignupStatus.failure,
        errorMessage: failure.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: SignupStatus.failure,
        errorMessage: 'Something went wrong. Please try again.',
      ));
    }
  }

  void _onReset(SignupStatusReset event, Emitter<SignupState> emit) {
    emit(const SignupState());
  }
}
