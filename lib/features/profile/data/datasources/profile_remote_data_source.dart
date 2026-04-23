import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../models/user_profile_model.dart';

/// Low-level contract for profile persistence. Kept abstract so it
/// can be faked in unit tests without Firebase.
abstract class ProfileRemoteDataSource {
  /// Merges the profile-setup fields into `users/{uid}` and flips
  /// `profileComplete` to true.
  Future<UserProfileModel> saveProfileSetup(UserProfileModel profile);

  /// Reads the profile doc for [uid]. Returns `null` if it does not
  /// exist.
  Future<UserProfileModel?> getProfile(String uid);

  /// Realtime snapshots for the profile doc. Emits `null` when the
  /// doc is missing, a hydrated model otherwise.
  Stream<UserProfileModel?> watchProfile(String uid);

  /// Partial merge for a single field or a small group of fields.
  Future<void> updateProfileFields(String uid, Map<String, dynamic> fields);

  /// Uploads [bytes] to `avatars/{uid}.jpg` and returns a public
  /// download URL.
  Future<String> uploadAvatar({
    required String uid,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  });
}

/// Firebase-backed implementation. Resolves the current uid from
/// [FirebaseAuth] where relevant so callers never have to juggle
/// authentication state.
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const _usersCollection = 'users';

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(_usersCollection).doc(uid);

  @override
  Future<UserProfileModel> saveProfileSetup(UserProfileModel profile) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ServerException('You must be signed in to save your profile.');
    }

    final docRef = _userDoc(user.uid);

    // Merge so signup-time fields (uid, email, createdAt, profileComplete=false)
    // are preserved and only the setup payload is overwritten.
    await docRef.set(profile.toSetupMap(), SetOptions(merge: true));

    // Re-read so we have the server timestamp resolved.
    final snap = await docRef.get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      throw const ServerException('Profile was saved but could not be re-read.');
    }
    return UserProfileModel.fromMap(data, snap.id);
  }

  @override
  Future<UserProfileModel?> getProfile(String uid) async {
    final snap = await _userDoc(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return UserProfileModel.fromMap(data, snap.id);
  }

  @override
  Stream<UserProfileModel?> watchProfile(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return UserProfileModel.fromMap(data, snap.id);
    });
  }

  @override
  Future<void> updateProfileFields(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    if (fields.isEmpty) return;
    await _userDoc(uid).set(fields, SetOptions(merge: true));
  }

  @override
  Future<String> uploadAvatar({
    required String uid,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    final ref = _storage.ref().child('avatars').child('$uid.jpg');
    final task = await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(
        contentType: contentType,
        cacheControl: 'public, max-age=3600',
      ),
    );
    return task.ref.getDownloadURL();
  }
}
