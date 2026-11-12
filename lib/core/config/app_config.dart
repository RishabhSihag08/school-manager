import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Global Application Configuration for School Manager
class AppConfig {
  AppConfig._();

  static const String appName = 'School Manager';
  static const String appTagline = 'Modern School Management System';
  static const String currentAcademicYear = '2026-2027';

  // Supabase Backend Credentials loaded from .env
  static String get supabaseUrl =>
      dotenv.isInitialized ? (dotenv.env['SUPABASE_URL'] ?? '') : '';

  static String get supabaseAnonKey =>
      dotenv.isInitialized ? (dotenv.env['SUPABASE_ANON_KEY'] ?? '') : '';

  static bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project-id');

  // Dual-OTA Engine Configuration
  static const String otaEngineType = 'Dual-Layer (Shorebird + GitHub Releases)';
  static const String shorebirdAppId = 'school-manager-app';
  static const String githubOwner = 'RishabhSihag08';
  static const String githubRepo = 'school-manager';
  static const String otaChannel = 'github-releases';
  static const String currentVersion = '1.0.1';
  static const int currentBuildNumber = 2;

  static String get githubLatestReleaseApi =>
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  static String get githubAllReleasesApi =>
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases';

  /// Safe initialization loading .env
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Fallback gracefully if .env asset is absent in test environments
    }
  }
}
