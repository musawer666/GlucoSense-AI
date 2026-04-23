import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// Drives the Profile tab.
///
/// Subscribes to a live Firestore snapshot so any remote mutation
/// (edits made on this device, on another device, or the initial
/// profile-setup write) is reflected in the UI immediately.
///
/// Field edits and avatar uploads are routed through
/// [ProfileRepository] and re-enter the UI via the snapshot stream
/// — there is no local mutation of [ProfileState.profile] to avoid
/// drift between the UI and Firestore.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required this.profileRepository,
    required this.authRepository,
  }) : super(const ProfileState()) {
    on<ProfileSubscribed>(_onSubscribed);
    on<_ProfileSnapshotReceived>(_onSnapshot);
    on<_ProfileSnapshotFailed>(_onSnapshotFailed);
    on<ProfileFieldsUpdated>(_onFieldsUpdated);
    on<ProfileAvatarChanged>(_onAvatarChanged);
    on<ProfileMutationAcknowledged>(_onMutationAck);
  }

  final ProfileRepository profileRepository;
  final AuthRepository authRepository;

  StreamSubscription<UserProfile?>? _sub;

  String? _uid;

  Future<void> _onSubscribed(
    ProfileSubscribed event,
    Emitter<ProfileState> emit,
  ) async {
    final user = authRepository.getCurrentUser();
    if (user == null) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: 'You need to be signed in to view your profile.',
      ));
      return;
    }
    _uid = user.uid;

    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));

    await _sub?.cancel();
    _sub = profileRepository.watchProfile(user.uid).listen(
      (profile) => add(_ProfileSnapshotReceived(profile)),
      onError: (Object error) {
        final message = error is Failure
            ? error.message
            : 'Failed to load your profile.';
        add(_ProfileSnapshotFailed(message));
      },
    );
  }

  void _onSnapshot(
    _ProfileSnapshotReceived event,
    Emitter<ProfileState> emit,
  ) {
    if (event.profile == null) {
      emit(state.copyWith(
        status: ProfileStatus.missing,
        clearProfile: true,
        clearError: true,
      ));
      return;
    }
    emit(state.copyWith(
      status: ProfileStatus.ready,
      profile: event.profile,
      clearError: true,
    ));
  }

  void _onSnapshotFailed(
    _ProfileSnapshotFailed event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(
      status: ProfileStatus.failure,
      errorMessage: event.message,
    ));
  }

  Future<void> _onFieldsUpdated(
    ProfileFieldsUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    final uid = _uid;
    if (uid == null || event.fields.isEmpty) return;

    emit(state.copyWith(status: ProfileStatus.updating, clearError: true));
    try {
      await profileRepository.updateProfileFields(uid, event.fields);
      // Snapshot stream will deliver the new values → back to ready.
      emit(state.copyWith(
        status: ProfileStatus.ready,
        lastMutation: 'Profile updated',
        clearError: true,
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: failure.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: 'Could not save your change. Please try again.',
      ));
    }
  }

  Future<void> _onAvatarChanged(
    ProfileAvatarChanged event,
    Emitter<ProfileState> emit,
  ) async {
    final uid = _uid;
    if (uid == null || event.bytes.isEmpty) return;

    emit(state.copyWith(status: ProfileStatus.updating, clearError: true));
    try {
      final url = await profileRepository.uploadAvatar(
        uid: uid,
        bytes: event.bytes,
      );
      await profileRepository.updateProfileFields(uid, {'avatarUrl': url});
      emit(state.copyWith(
        status: ProfileStatus.ready,
        lastMutation: 'Photo updated',
        clearError: true,
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: failure.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: 'Could not update your photo. Please try again.',
      ));
    }
  }

  void _onMutationAck(
    ProfileMutationAcknowledged event,
    Emitter<ProfileState> emit,
  ) {
    if (state.lastMutation == null && state.errorMessage == null) return;
    emit(state.copyWith(
      clearError: true,
      clearMutation: true,
      // Keep whichever status was set by the stream on success;
      // only reset when we're sitting on a failure.
      status: state.status == ProfileStatus.failure
          ? (state.profile == null
              ? ProfileStatus.loading
              : ProfileStatus.ready)
          : state.status,
    ));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }
}
