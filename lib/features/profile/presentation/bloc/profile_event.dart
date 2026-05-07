part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => const [];
}

/// Opens the live snapshot subscription for the current user.
final class ProfileSubscribed extends ProfileEvent {
  const ProfileSubscribed();
}

/// Internal — shared shell profile stream.
final class _ProfileShellProfileChanged extends ProfileEvent {
  const _ProfileShellProfileChanged(this.shell);

  final ShellProfileState shell;

  @override
  List<Object?> get props => [shell];
}

/// Partial merge of a handful of fields onto the user's profile
/// document. Firestore will echo the write back through the
/// snapshot stream, which keeps the UI in sync without a manual
/// state-bump here.
final class ProfileFieldsUpdated extends ProfileEvent {
  const ProfileFieldsUpdated({required this.fields});

  final Map<String, dynamic> fields;

  @override
  List<Object?> get props => [fields];
}

/// Upload a new avatar (bytes) to Firebase Storage and persist the
/// resulting URL on the user's document.
final class ProfileAvatarChanged extends ProfileEvent {
  const ProfileAvatarChanged({required this.bytes});

  final List<int> bytes;

  @override
  List<Object?> get props => [bytes];
}

/// Returns the transient [ProfileStatus.updating] / `failure` state
/// back to `ready` after the UI has consumed the one-shot signal.
final class ProfileMutationAcknowledged extends ProfileEvent {
  const ProfileMutationAcknowledged();
}
