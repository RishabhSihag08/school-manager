import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Global Application Configuration for School Manager
class AppConfig {
  AppConfig._();

  static const String appName = 'School Manager';
  static const String appTagline = 'Modern School Management System';
  static String get currentAcademicYear {
    final now = DateTime.now();
    return now.month >= 4
        ? '${now.year}-${now.year + 1}'
        : '${now.year - 1}-${now.year}';
  }

  // Supabase Backend Credentials loaded from .env
  static String get supabaseUrl =>
      dotenv.isInitialized ? (dotenv.env['SUPABASE_URL'] ?? '') : '';

  static String get supabaseAnonKey =>
      dotenv.isInitialized ? (dotenv.env['SUPABASE_ANON_KEY'] ?? '') : '';

  static bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project-id');

  // Master Administrative Security Key (Case-Sensitive)
  static String get masterKey =>
      dotenv.isInitialized ? (dotenv.env['MASTER_KEY'] ?? 'SirChotuRam') : 'SirChotuRam';

  // OTA Engine Configuration
  static const String otaEngineType = 'GitHub Releases';
  static const String githubOwner = 'RishabhSihag08';
  static const String githubRepo = 'school-manager';
  static const String otaChannel = 'github-releases';

  static String _version = '1.0.7';
  static int _buildNumber = 7;

  static String get currentVersion => _version;
  static int get currentBuildNumber => _buildNumber;

  static String get githubLatestReleaseApi =>
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  static String get githubAllReleasesApi =>
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases';

  /// Synchronize dynamic app version with platform package manager
  static Future<void> syncPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        _version = info.version;
        _buildNumber = int.tryParse(info.buildNumber) ?? _buildNumber;
      }
    } catch (_) {
      // Retain defaults gracefully in environments where platform channel is unavailable
    }
  }

  /// Safe initialization loading .env and platform package info
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Fallback gracefully if .env asset is absent in test environments
    }

    await syncPackageInfo();
  }
}
