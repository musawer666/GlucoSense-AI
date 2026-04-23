import 'secrets.dart';

/// Centralised, type-safe access to runtime configuration.
///
/// Resolution order for every value:
///   1. Compile-time `String.fromEnvironment(...)` — set via
///      `--dart-define=KEY=VALUE` for CI / release builds. Keeps
///      secrets out of source.
///   2. Local `Secrets` constant — convenient for local dev. The
///      `secrets.dart` file is gitignored, so the key never leaves
///      the developer's machine.
///
/// Feature code MUST import `AppConfig`, never `Secrets` directly,
/// so that swapping the source of a key requires no callsite
/// changes and is enforced by the import boundary.
abstract final class AppConfig {
  AppConfig._();

  static const String _envGeminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
  );

  /// Gemini API key. Empty string means "not configured" — the
  /// caller should surface a friendly error instead of failing the
  /// HTTP request blindly.
  static String get geminiApiKey {
    if (_envGeminiApiKey.isNotEmpty) return _envGeminiApiKey;
    return Secrets.geminiApiKey;
  }

  /// Convenience guard — call from any service that requires the
  /// key before making a network call. Throws an [AppConfigError]
  /// (a typed exception) so the repository layer can map it to a
  /// `Failure` and the UI shows a meaningful message.
  static void requireGeminiApiKey() {
    if (geminiApiKey.trim().isEmpty) {
      throw const AppConfigError(
        'Gemini API key is not configured. Add it to '
        'lib/core/config/secrets.dart or pass --dart-define=GEMINI_API_KEY=…',
      );
    }
  }

  /// Default Gemini model used for vision + text tasks. Centralised
  /// so we can upgrade across the app from a single place.
  ///
  /// NOTE: Google retired the `gemini-1.5-flash` alias from the
  /// `v1beta` endpoint in late 2025, which is the endpoint that the
  /// `google_generative_ai` Dart package hits. The current, actively
  /// served multimodal "flash" model is `gemini-2.5-flash`. If your
  /// key / region does not have 2.5 access yet, fall back to
  /// `gemini-2.0-flash` — it is also still served on v1beta.
  static const String geminiVisionModel = 'gemini-2.5-flash';
}

/// Thrown when a required configuration value is missing.
class AppConfigError implements Exception {
  const AppConfigError(this.message);

  final String message;

  @override
  String toString() => 'AppConfigError: $message';
}
