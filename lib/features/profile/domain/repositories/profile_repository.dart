import '../entities/user_profile.dart';

/// Abstract contract for reading / writing the user profile.
///
/// Implementations must funnel every thrown error through the shared
/// `mapAnyError` so the Bloc / UI layers only ever see typed
/// [Failure]s, never raw Firebase exceptions.
abstract class ProfileRepository {
  /// Writes the full profile (profile-setup + medical-details) to
  /// the current user's document and flips `profileComplete` to true.
  ///
  /// The returned [UserProfile] reflects the persisted state.
  Future<UserProfile> saveProfileSetup(UserProfile profile);

  /// One-off read of the profile for [uid]. Returns `null` when the
  /// document does not exist.
  Future<UserProfile?> getProfile(String uid);

  /// Live Firestore snapshot stream for the current user's document.
  /// Emits `null` when the doc is missing, a hydrated [UserProfile]
  /// otherwise. Every remote mutation re-emits automatically so the
  /// UI can stay reactive without manual refreshes.
  Stream<UserProfile?> watchProfile(String uid);

  /// Partial merge of arbitrary fields into `users/{uid}`. Used by
  /// the Profile screen when the user edits a single row.
  Future<void> updateProfileFields(String uid, Map<String, dynamic> fields);

  /// Writes last ML risk analysis fields on `users/{uid}` (merge).
  Future<void> saveMlRiskAnalysis(
    String uid, {
    required String category,
    required int confidencePercent,
    required String advice,
    required Map<String, double> probabilitiesPercent,
  });

  /// Uploads [bytes] as the user's avatar and returns a public
  /// download URL. Callers should follow up with
  /// [updateProfileFields] to persist the URL under `avatarUrl`.
  Future<String> uploadAvatar({
    required String uid,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  });
}
