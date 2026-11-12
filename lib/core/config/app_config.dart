/// Global Application Configuration for School Manager
class AppConfig {
  AppConfig._();

  static const String appName = 'School Manager';
  static const String appTagline = 'Modern Indian School System';
  static const String schoolName = 'Delhi Public Heritage School';
  static const String currentAcademicYear = '2026-2027';

  // Dual-OTA Engine Configuration
  static const String otaEngineType = 'Dual-Layer (Shorebird + GitHub Releases)';
  static const String shorebirdAppId = 'school-manager-app';
  static const String githubOwner = 'school-org';
  static const String githubRepo = 'school-manager';
  static const String otaChannel = 'github-releases';
  static const String currentVersion = '1.0.0';
  static const int currentBuildNumber = 1;

  static String get githubLatestReleaseApi =>
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  static String get githubAllReleasesApi =>
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases';
}
