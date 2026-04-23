part of 'signup_bloc.dart';

enum SignupStatus { initial, submitting, success, failure }

final class SignupState extends Equatable {
  const SignupState({
    this.status = SignupStatus.initial,
    this.errorMessage,
    this.uid,
  });

  final SignupStatus status;

  /// User-facing error message, only populated when [status] is
  /// [SignupStatus.failure].
  final String? errorMessage;

  /// Firebase UID of the freshly created user. Populated once
  /// [status] becomes [SignupStatus.success].
  final String? uid;

  bool get isSubmitting => status == SignupStatus.submitting;

  SignupState copyWith({
    SignupStatus? status,
    String? errorMessage,
    String? uid,
    bool clearError = false,
    bool clearUid = false,
  }) {
    return SignupState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      uid: clearUid ? null : (uid ?? this.uid),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, uid];
}
