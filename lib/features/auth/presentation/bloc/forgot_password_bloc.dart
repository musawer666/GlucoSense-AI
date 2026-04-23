import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

/// Handles the "forgot password" flow. The UI only ever dispatches
/// events; all Firebase calls stay inside [AuthRepository].
class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc({required this.authRepository})
      : super(const ForgotPasswordState()) {
    on<ForgotPasswordSubmitted>(_onSubmitted);
    on<ForgotPasswordStatusReset>(_onReset);
  }

  final AuthRepository authRepository;

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    // Ignore duplicate taps while a request is in flight.
    if (state.status == ForgotPasswordStatus.sending) return;

    final email = event.email.trim();

    emit(state.copyWith(
      status: ForgotPasswordStatus.sending,
      clearError: true,
      clearEmail: true,
    ));

    try {
      await authRepository.sendPasswordResetEmail(email: email);
      emit(state.copyWith(
        status: ForgotPasswordStatus.sent,
        email: email,
        clearError: true,
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: failure.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: 'Something went wrong. Please try again.',
      ));
    }
  }

  void _onReset(
    ForgotPasswordStatusReset event,
    Emitter<ForgotPasswordState> emit,
  ) {
    emit(const ForgotPasswordState());
  }
}
