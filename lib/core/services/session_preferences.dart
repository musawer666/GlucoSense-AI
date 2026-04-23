import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight wrapper around [SharedPreferences] for session flags.
///
/// Firebase Auth on mobile persists the signed-in user forever by
/// default, so "remember me" is implemented here by tracking whether
/// the user opted in. On app start we inspect the flag:
///
/// - flag == true  → keep the Firebase session alive (auto login).
/// - flag == false → sign the user out and send them to login again.
class SessionPreferences {
  const SessionPreferences();

  static const _rememberMeKey = 'auth.remember_me';

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
  }
}
