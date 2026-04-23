part of 'profile_setup_bloc.dart';

enum ProfileSetupStatus { initial, saving, success, failure }

final class ProfileSetupState extends Equatable {
  const ProfileSetupState({
    this.status = ProfileSetupStatus.initial,
    this.errorMessage,
    this.savedProfile,
  });

  final ProfileSetupStatus status;

  /// Populated only when [status] is [ProfileSetupStatus.failure].
  final String? errorMessage;

  /// Populated once the save succeeds so the UI (or future listeners)
  /// can route with the hydrated profile.
  final UserProfile? savedProfile;

  bool get isSaving => status == ProfileSetupStatus.saving;

  ProfileSetupState copyWith({
    ProfileSetupStatus? status,
    String? errorMessage,
    UserProfile? savedProfile,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return ProfileSetupState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedProfile:
          clearProfile ? null : (savedProfile ?? this.savedProfile),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, savedProfile];
}
