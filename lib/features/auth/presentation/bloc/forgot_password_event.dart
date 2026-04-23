part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => const [];
}

/// Fired when the user taps "Send reset link" after local validation.
final class ForgotPasswordSubmitted extends ForgotPasswordEvent {
  const ForgotPasswordSubmitted({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Returns the Bloc to [ForgotPasswordStatus.initial] after a failure
/// dialog is dismissed so the button re-enables and listeners don't
/// re-fire on rebuild.
final class ForgotPasswordStatusReset extends ForgotPasswordEvent {
  const ForgotPasswordStatusReset();
}
