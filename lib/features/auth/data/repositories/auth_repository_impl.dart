import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/services/session_preferences.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Bridges domain ⇄ data source. Funnels every thrown error through
/// [mapAnyError] so upper layers only ever see typed [Failure]s, and
/// coordinates the local [SessionPreferences] for "remember me".
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remoteDataSource,
    SessionPreferences? sessionPreferences,
  }) : _session = sessionPreferences ?? const SessionPreferences();

  final AuthRemoteDataSource remoteDataSource;
  final SessionPreferences _session;

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
      );
      // A user who just signed up has no reason to be immediately
      // logged out on the next launch — default them to "remembered".
      await _session.setRememberMe(true);
      return user;
    } catch (error) {
      throw mapAnyError(error);
    }
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final user = await remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      await _session.setRememberMe(rememberMe);
      return user;
    } catch (error) {
      throw mapAnyError(error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email: email);
    } catch (error) {
      throw mapAnyError(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
      await _session.clear();
    } catch (error) {
      throw mapAnyError(error);
    }
  }

  @override
  AuthUser? getCurrentUser() {
    return remoteDataSource.getCurrentFirebaseUser();
  }

  @override
  Future<AuthSessionState> resolveSession() async {
    try {
      final current = remoteDataSource.getCurrentFirebaseUser();
      if (current == null) return AuthSessionState.unauthenticated;

      final remember = await _session.getRememberMe();
      if (!remember) {
        // User opted out of "remember me" in the previous session —
        // sign them out now and start fresh.
        await remoteDataSource.signOut();
        await _session.clear();
        return AuthSessionState.unauthenticated;
      }

      final profile = await remoteDataSource.getUserProfile(current.uid);
      if (profile == null || !profile.profileComplete) {
        return AuthSessionState.profileIncomplete;
      }
      return AuthSessionState.ready;
    } catch (_) {
      // On any resolution error (e.g. Firestore offline), fall back
      // to the safest path — send the user to login. The regular
      // [mapAnyError] flow is not needed here: the splash only needs
      // a bool-ish answer, not a user-facing message.
      return AuthSessionState.unauthenticated;
    }
  }
}
