import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../cubit/shell_profile_cubit.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// Drives the Profile tab.
///
/// Profile data follows [ShellProfileCubit] (shared with other shell tabs).
/// Field edits and avatar uploads go through [ProfileRepository]; Firestore
/// echoes writes back through the same shell listener.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required this.profileRepository,
    required this.authRepository,
    required this.shellProfileCubit,
  }) : super(const ProfileState()) {
    on<ProfileSubscribed>(_onSubscribed);
    on<_ProfileShellProfileChanged>(_onShellProfileChanged);
    on<ProfileFieldsUpdated>(_onFieldsUpdated);
    on<ProfileAvatarChanged>(_onAvatarChanged);
    on<ProfileMutationAcknowledged>(_onMutationAck);
  }

  final ProfileRepository profileRepository;
  final AuthRepository authRepository;
  final ShellProfileCubit shellProfileCubit;

  StreamSubscription<ShellProfileState>? _shellSub;

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

    await _shellSub?.cancel();
    void forward(ShellProfileState shell) =>
        add(_ProfileShellProfileChanged(shell));
    forward(shellProfileCubit.state);
    _shellSub = shellProfileCubit.stream.listen(forward);
  }

  void _onShellProfileChanged(
    _ProfileShellProfileChanged event,
    Emitter<ProfileState> emit,
  ) {
    final shell = event.shell;
    switch (shell.status) {
      case ShellProfileStatus.signedOut:
        emit(state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: 'You need to be signed in to view your profile.',
          clearProfile: true,
        ));
        break;
      case ShellProfileStatus.initial:
      case ShellProfileStatus.loading:
        emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
        break;
      case ShellProfileStatus.failure:
        emit(state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: shell.errorMessage ??
              'Failed to load your profile.',
        ));
        break;
      case ShellProfileStatus.missingProfile:
        emit(state.copyWith(
          status: ProfileStatus.missing,
          clearProfile: true,
          clearError: true,
        ));
        break;
      case ShellProfileStatus.ready:
        final profile = shell.profile;
        if (profile == null) {
          emit(state.copyWith(
            status: ProfileStatus.missing,
            clearProfile: true,
            clearError: true,
          ));
        } else {
          emit(state.copyWith(
            status: ProfileStatus.ready,
            profile: profile,
            clearError: true,
          ));
        }
        break;
    }
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
    await _shellSub?.cancel();
    _shellSub = null;
    return super.close();
  }
}
