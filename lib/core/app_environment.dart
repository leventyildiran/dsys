class AppEnvironment {
  AppEnvironment._();

  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const bool crashlyticsEnabled =
      bool.fromEnvironment('CRASHLYTICS_ENABLED', defaultValue: true);

  static bool get hasGeminiApiKey => geminiApiKey.trim().isNotEmpty;
}
