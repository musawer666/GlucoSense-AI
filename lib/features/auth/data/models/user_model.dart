import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/auth_user.dart';

/// Firestore-aware mapping for the `users/{uid}` document.
///
/// Keeps serialization in one place so the rest of the app can work
/// with the pure [AuthUser] entity without ever touching Firestore.
class UserModel extends AuthUser {
  const UserModel({
    required super.uid,
    required super.email,
    super.createdAt,
    super.profileComplete,
  });

  /// Payload used when the account is first created. `createdAt` is
  /// assigned by the server to keep timestamps consistent across
  /// devices and time zones.
  Map<String, dynamic> toCreateMap() => {
        'uid': uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'profileComplete': profileComplete,
      };

  /// Safe factory — tolerates missing/null fields from older documents.
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    final ts = map['createdAt'];
    return UserModel(
      uid: (map['uid'] as String?) ?? id,
      email: (map['email'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
      profileComplete: (map['profileComplete'] as bool?) ?? false,
    );
  }
}
