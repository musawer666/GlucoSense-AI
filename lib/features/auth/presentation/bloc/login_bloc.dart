import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

/// Drives the sign-in flow. The UI only ever dispatches events —
/// every Firebase call and every session-preferences write stays
/// behind [AuthRepository].
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required this.authRepository}) : super(const LoginState()) {
    on<LoginSubmitted>(_onSubmitted);
    on<LoginStatusReset>(_onReset);
  }

  final AuthRepository authRepository;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state.status == LoginStatus.submitting) return;

    emit(state.copyWith(
      status: LoginStatus.submitting,
      clearError: true,
      clearUser: true,
    ));

    try {
      final user = await authRepository.signInWithEmail(
        email: event.email.trim(),
        password: event.password,
        rememberMe: event.rememberMe,
      );
      emit(state.copyWith(
        status: LoginStatus.success,
        user: user,
        clearError: true,
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: failure.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Something went wrong. Please try again.',
      ));
    }
  }

  void _onReset(LoginStatusReset event, Emitter<LoginState> emit) {
    emit(const LoginState());
  }
}
