part of 'forgot_password_bloc.dart';

enum ForgotPasswordStatus { initial, sending, sent, failure }

final class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.errorMessage,
    this.email,
  });

  final ForgotPasswordStatus status;

  /// User-facing error message, only populated when [status] is
  /// [ForgotPasswordStatus.failure].
  final String? errorMessage;

  /// Email we just successfully sent the reset link to (for the dialog).
  final String? email;

  bool get isSending => status == ForgotPasswordStatus.sending;

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? errorMessage,
    String? email,
    bool clearError = false,
    bool clearEmail = false,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      email: clearEmail ? null : (email ?? this.email),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, email];
}
