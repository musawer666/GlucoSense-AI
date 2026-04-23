part of 'signup_bloc.dart';

sealed class SignupEvent extends Equatable {
  const SignupEvent();

  @override
  List<Object?> get props => const [];
}

/// Fired when the form passes local validation and the user taps the
/// "Create account" button.
final class SignupSubmitted extends SignupEvent {
  const SignupSubmitted({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Resets the status back to [SignupStatus.initial] — useful after a
/// failure dialog has been dismissed so the button becomes active again
/// and `BlocListener` won't re-fire on rebuild.
final class SignupStatusReset extends SignupEvent {
  const SignupStatusReset();
}
