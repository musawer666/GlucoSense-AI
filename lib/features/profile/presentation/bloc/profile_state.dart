part of 'profile_bloc.dart';

enum ProfileStatus { initial, loading, ready, updating, failure, missing }

final class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
    this.lastMutation,
  });

  final ProfileStatus status;

  /// Latest hydrated profile from Firestore (when available).
  final UserProfile? profile;

  /// Populated on [ProfileStatus.failure].
  final String? errorMessage;

  /// One-shot label describing the most recent successful mutation
  /// ("Profile updated", "Photo updated"). Cleared by
  /// [ProfileMutationAcknowledged] after the UI shows its dialog.
  final String? lastMutation;

  bool get isUpdating => status == ProfileStatus.updating;
  bool get isReady => status == ProfileStatus.ready && profile != null;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    String? errorMessage,
    String? lastMutation,
    bool clearError = false,
    bool clearProfile = false,
    bool clearMutation = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastMutation:
          clearMutation ? null : (lastMutation ?? this.lastMutation),
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage, lastMutation];
}
