import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../models/user_model.dart';

/// Low-level contract for the remote auth source. Kept abstract so it
/// can be faked in unit tests without pulling Firebase into the test.
abstract class AuthRemoteDataSource {
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();

  /// Returns the currently signed-in user from [FirebaseAuth], or
  /// `null` if nobody is signed in. Does NOT touch Firestore.
  UserModel? getCurrentFirebaseUser();

  /// Reads the `users/{uid}` document from Firestore and returns the
  /// full [UserModel] (including `profileComplete`). Returns `null`
  /// if the document does not exist.
  Future<UserModel?> getUserProfile(String uid);
}

/// Firebase-backed implementation.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _usersCollection = 'users';

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw const ServerException('Sign-up succeeded but returned no user.');
    }

    final model = UserModel(
      uid: user.uid,
      email: user.email ?? email,
    );

    await _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .set(model.toCreateMap());

    return model;
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw const ServerException('Sign-in succeeded but returned no user.');
    }

    // Hydrate the remote profile so the caller knows whether the user
    // has finished `ProfileSetup`. Falls back to a minimal model if
    // the document is missing (e.g. legacy account without `users/{uid}`).
    final profile = await getUserProfile(user.uid);
    return profile ??
        UserModel(
          uid: user.uid,
          email: user.email ?? email,
        );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  UserModel? getCurrentFirebaseUser() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
    );
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    final snap =
        await _firestore.collection(_usersCollection).doc(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return UserModel.fromMap(data, snap.id);
  }
}
