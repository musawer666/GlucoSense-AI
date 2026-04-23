import '../domain/profile_display_data.dart';

/// In-memory profile snapshot until SharedPreferences / Supabase is wired.
/// Call [setProfile] when profile + medical setup completes.
abstract final class UserProfileStore {
  UserProfileStore._();

  static ProfileDisplayData? _data;
  static List<int>? _avatarBytes;

  static ProfileDisplayData get effective =>
      _data ?? ProfileDisplayData.sample();

  static ProfileDisplayData? get current => _data;

  static void setProfile(ProfileDisplayData data) {
    _data = data;
  }

  static List<int>? get avatarBytes => _avatarBytes;

  static void setAvatarBytes(List<int>? bytes) {
    _avatarBytes = bytes;
  }

  static void clear() {
    _data = null;
    _avatarBytes = null;
  }
}
