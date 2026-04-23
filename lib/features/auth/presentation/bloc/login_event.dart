part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => const [];
}

/// Fired when the user taps "Sign In" after local validation.
final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({
    required this.email,
    required this.password,
    required this.rememberMe,
  });

  final String email;
  final String password;
  final bool rememberMe;

  @override
  List<Object?> get props => [email, password, rememberMe];
}

/// Resets the Bloc back to [LoginStatus.initial] after a failure
/// dialog is dismissed so the button re-enables.
final class LoginStatusReset extends LoginEvent {
  const LoginStatusReset();
}
