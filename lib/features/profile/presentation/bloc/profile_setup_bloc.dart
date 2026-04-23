import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

part 'profile_setup_event.dart';
part 'profile_setup_state.dart';

/// Orchestrates the final save of the profile-setup flow.
///
/// UI code (both Profile Setup step 1 and Medical Details step 2)
/// only dispatches events — Firebase / Firestore stay strictly behind
/// [ProfileRepository].
class ProfileSetupBloc extends Bloc<ProfileSetupEvent, ProfileSetupState> {
  ProfileSetupBloc({required this.profileRepository})
      : super(const ProfileSetupState()) {
    on<ProfileSetupSubmitted>(_onSubmitted);
    on<ProfileSetupStatusReset>(_onReset);
  }

  final ProfileRepository profileRepository;

  Future<void> _onSubmitted(
    ProfileSetupSubmitted event,
    Emitter<ProfileSetupState> emit,
  ) async {
    if (state.status == ProfileSetupStatus.saving) return;

    emit(state.copyWith(
      status: ProfileSetupStatus.saving,
      clearError: true,
      clearProfile: true,
    ));

    try {
      // Upload the avatar FIRST so the resulting URL is persisted
      // atomically with the rest of the profile. Any failure here
      // surfaces as a typed [Failure] via the repository, so the UI
      // gets a real error instead of a silently missing photo.
      var profileToSave = event.profile;
      final bytes = event.avatarBytes;
      if (bytes != null && bytes.isNotEmpty) {
        final url = await profileRepository.uploadAvatar(
          uid: profileToSave.uid,
          bytes: bytes,
        );
        profileToSave = profileToSave.copyWith(avatarUrl: url);
      }

      final saved = await profileRepository.saveProfileSetup(profileToSave);

      emit(state.copyWith(
        status: ProfileSetupStatus.success,
        savedProfile: saved,
        clearError: true,
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: ProfileSetupStatus.failure,
        errorMessage: failure.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: ProfileSetupStatus.failure,
        errorMessage: 'Something went wrong. Please try again.',
      ));
    }
  }

  void _onReset(
    ProfileSetupStatusReset event,
    Emitter<ProfileSetupState> emit,
  ) {
    emit(const ProfileSetupState());
  }
}
