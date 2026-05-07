import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

part 'shell_profile_state.dart';

/// One shared Firestore listener for `users/{uid}` used by every main-shell tab.
///
/// Keeps **name, age, gender, glucose denorm fields, saved ML risk**, etc. in
/// sync everywhere without N duplicate snapshot listeners.
class ShellProfileCubit extends Cubit<ShellProfileState> {
  ShellProfileCubit({
    required ProfileRepository profileRepository,
    required AuthRepository authRepository,
  })  : _profileRepository = profileRepository,
        _authRepository = authRepository,
        super(const ShellProfileState());

  final ProfileRepository _profileRepository;
  final AuthRepository _authRepository;

  StreamSubscription<UserProfile?>? _sub;

  /// Starts (or restarts) the live document subscription.
  void subscribe() {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      emit(const ShellProfileState(
        status: ShellProfileStatus.signedOut,
        profile: null,
      ));
      return;
    }

    emit(state.copyWith(
      status: ShellProfileStatus.loading,
      clearError: true,
    ));

    unawaited(_sub?.cancel());
    _sub = _profileRepository.watchProfile(user.uid).listen(
      (profile) {
        emit(ShellProfileState(
          status: profile == null
              ? ShellProfileStatus.missingProfile
              : ShellProfileStatus.ready,
          profile: profile,
        ));
      },
      onError: (Object error) {
        final message = error is Failure
            ? error.message
            : 'Failed to load profile.';
        emit(ShellProfileState(
          status: ShellProfileStatus.failure,
          profile: state.profile,
          errorMessage: message,
        ));
      },
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }
}
