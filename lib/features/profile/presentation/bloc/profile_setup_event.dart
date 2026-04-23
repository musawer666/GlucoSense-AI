part of 'profile_setup_bloc.dart';

sealed class ProfileSetupEvent extends Equatable {
  const ProfileSetupEvent();

  @override
  List<Object?> get props => const [];
}

/// Fired when the user taps "Save & Continue" on Medical Details
/// with a fully-assembled [UserProfile] (step 1 + step 2 merged).
///
/// [avatarBytes] is optional — when provided the bytes are uploaded
/// to Firebase Storage right after the profile write and the
/// resulting URL is patched back onto the user document.
final class ProfileSetupSubmitted extends ProfileSetupEvent {
  const ProfileSetupSubmitted({required this.profile, this.avatarBytes});

  final UserProfile profile;
  final List<int>? avatarBytes;

  @override
  List<Object?> get props => [profile, avatarBytes];
}

/// Returns the Bloc to [ProfileSetupStatus.initial] after a failure
/// dialog is dismissed so the CTA re-enables.
final class ProfileSetupStatusReset extends ProfileSetupEvent {
  const ProfileSetupStatusReset();
}
