class AppConfig {
  /// Gemini API key provided securely via `--dart-define=GEMINI_API_KEY=your_key`.
  /// Keeping this empty by default ensures your public GitHub repository never leaks your secret key!
  static const String defaultGeminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}
