import 'app_secrets.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'Church Hub';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3333',
  );

  static const String youtubeApiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: AppSecrets.youtubeApiKey,
  );

  static const String pexelsApiKey = String.fromEnvironment(
    'PEXELS_API_KEY',
    defaultValue: AppSecrets.pexelsApiKey,
  );

}
