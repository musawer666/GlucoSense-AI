import 'package:equatable/equatable.dart';

/// Pure Dart representation of an authenticated user.
///
/// The domain layer stays free of Firebase / backend types so the
/// data source can be swapped later without rippling into Bloc / UI.
class AuthUser extends Equatable {
  const AuthUser({
    required this.uid,
    required this.email,
    this.createdAt,
    this.profileComplete = false,
  });

  final String uid;
  final String email;
  final DateTime? createdAt;

  /// True once the user has finished the post-signup profile setup
  /// flow. Drives app-start routing: home-shell vs profile-setup.
  final bool profileComplete;

  @override
  List<Object?> get props => [uid, email, createdAt, profileComplete];
}
