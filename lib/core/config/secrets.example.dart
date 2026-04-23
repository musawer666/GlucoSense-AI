/// Template for `secrets.dart`.
///
/// Copy this file to `secrets.dart` (which is gitignored) and fill
/// in your real keys for local development. CI / production should
/// inject the same values via `--dart-define=GEMINI_API_KEY=…`.
abstract final class Secrets {
  Secrets._();

  /// Google AI Studio (Gemini) API key.
  /// Get one at https://aistudio.google.com/apikey
  static const String geminiApiKey = '';
}
