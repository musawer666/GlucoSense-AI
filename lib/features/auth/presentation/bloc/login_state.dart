part of 'login_bloc.dart';

enum LoginStatus { initial, submitting, success, failure }

final class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.user,
  });

  final LoginStatus status;

  /// Populated only when [status] is [LoginStatus.failure].
  final String? errorMessage;

  /// Populated once the sign-in succeeds so the UI can decide
  /// between HomeShell (profile complete) and ProfileSetup.
  final AuthUser? user;

  bool get isSubmitting => status == LoginStatus.submitting;

  LoginState copyWith({
    LoginStatus? status,
    String? errorMessage,
    AuthUser? user,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: clearUser ? null : (user ?? this.user),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, user];
}
