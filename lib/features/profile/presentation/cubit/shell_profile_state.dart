part of 'shell_profile_cubit.dart';

enum ShellProfileStatus {
  initial,
  loading,
  ready,
  missingProfile,
  failure,
  signedOut,
}

class ShellProfileState extends Equatable {
  const ShellProfileState({
    this.status = ShellProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  final ShellProfileStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  bool get hasProfile => profile != null;

  ShellProfileState copyWith({
    ShellProfileStatus? status,
    UserProfile? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ShellProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
