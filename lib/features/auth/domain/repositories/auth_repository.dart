import '../entities/auth_user.dart';

/// The three start-up states the app can be in.
enum AuthSessionState {
  /// No Firebase user, or the user opted out of "remember me" and has
  /// been signed out during session resolution.
  unauthenticated,

  /// Signed in but has not finished the post-signup profile setup.
  profileIncomplete,

  /// Signed in and fully onboarded — go to home.
  ready,
}

/// Abstract contract for all authentication operations.
///
/// Implementations live in `data/repositories/` and must convert any
/// underlying error into a typed [Failure] before rethrowing, so the
/// Bloc/UI layers never see Firebase-specific exceptions.
abstract class AuthRepository {
  /// Creates a new account with email/password and provisions the
  /// `users/{uid}` document. Persists "remember me" as true by default
  /// since the user just created an account in this session.
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Signs the user in and, when [rememberMe] is true, persists a
  /// local flag so the session survives app restarts.
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
    required bool rememberMe,
  });

  /// Sends a password-reset email. Throws a typed [Failure] on error.
  Future<void> sendPasswordResetEmail({required String email});

  /// Signs out of Firebase Auth and clears the "remember me" flag.
  Future<void> signOut();

  /// Synchronous snapshot of the currently-signed-in user, or `null`
  /// if nobody is signed in. Does not hit Firestore.
  AuthUser? getCurrentUser();

  /// Resolves the app's start-up state:
  ///
  /// - `unauthenticated` if no user, or the user is signed in but
  ///   `rememberMe` is false (they opted out → they are signed out
  ///   here and sent back to login).
  /// - `profileIncomplete` if the Firestore profile doc exists and
  ///   `profileComplete == false`, or the doc is missing entirely.
  /// - `ready` if signed in and `profileComplete == true`.
  Future<AuthSessionState> resolveSession();
}
