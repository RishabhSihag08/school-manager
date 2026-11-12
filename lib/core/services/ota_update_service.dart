import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

/// Information about an available OTA update release via GitHub
class OtaReleaseInfo {
  final String version;
  final String title;
  final String changelog;
  final String apkDownloadUrl;
  final int apkSizeBytes;
  final bool isForced;
  final DateTime publishedAt;

  const OtaReleaseInfo({
    required this.version,
    required this.title,
    required this.changelog,
    required this.apkDownloadUrl,
    required this.apkSizeBytes,
    this.isForced = false,
    required this.publishedAt,
  });

  String get formattedSize {
    if (apkSizeBytes <= 0) return 'Unknown size';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  factory OtaReleaseInfo.fromGitHubJson(Map<String, dynamic> json) {
    final rawTag = (json['tag_name'] as String? ?? '1.0.0').replaceAll('v', '').trim();
    final title = json['name'] as String? ?? 'Release v$rawTag';
    final body = json['body'] as String? ?? '';
    final publishedStr = json['published_at'] as String?;
    final publishedAt = publishedStr != null
        ? DateTime.tryParse(publishedStr) ?? DateTime.now()
        : DateTime.now();

    final isForced = body.toLowerCase().contains('[forced_update]') ||
        body.toLowerCase().contains('critical security update');

    String apkUrl = '';
    int apkSize = 0;
    final assets = json['assets'] as List<dynamic>? ?? [];
    for (final asset in assets) {
      if (asset is Map<String, dynamic>) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String? ?? '';
          apkSize = (asset['size'] as num?)?.toInt() ?? 0;
          break;
        }
      }
    }

    return OtaReleaseInfo(
      version: rawTag,
      title: title,
      changelog: body,
      apkDownloadUrl: apkUrl,
      apkSizeBytes: apkSize,
      isForced: isForced,
      publishedAt: publishedAt,
    );
  }
}

/// State of the OTA Update Engine (GitHub Releases)
class OtaUpdateState {
  final bool isChecking;
  final OtaReleaseInfo? availableRelease;
  final bool isDownloading;
  final double downloadProgress; // 0.0 to 1.0
  final int bytesDownloaded;
  final int totalBytes;
  final String? localApkPath;
  final String? errorMessage;

  const OtaUpdateState({
    this.isChecking = false,
    this.availableRelease,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.localApkPath,
    this.errorMessage,
  });

  OtaUpdateState copyWith({
    bool? isChecking,
    OtaReleaseInfo? availableRelease,
    bool clearRelease = false,
    bool? isDownloading,
    double? downloadProgress,
    int? bytesDownloaded,
    int? totalBytes,
    String? localApkPath,
    String? errorMessage,
  }) {
    return OtaUpdateState(
      isChecking: isChecking ?? this.isChecking,
      availableRelease:
          clearRelease ? null : (availableRelease ?? this.availableRelease),
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      localApkPath: localApkPath ?? this.localApkPath,
      errorMessage: errorMessage,
    );
  }
}

/// OTA Update Service (GitHub Releases)
class OtaUpdateService extends StateNotifier<OtaUpdateState> {
  final http.Client _httpClient;

  OtaUpdateService({http.Client? client})
      : _httpClient = client ?? http.Client(),
        super(const OtaUpdateState());

  /// Compare two semantic version strings (e.g. "1.0.1" > "1.0.0")
  static bool isNewerVersion(String latestVersion, String currentVersion) {
    try {
      final cleanLatest = latestVersion.replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanCurrent = currentVersion.replaceAll(RegExp(r'[^0-9.]'), '');

      final latestParts = cleanLatest.split('.').map(int.parse).toList();
      final currentParts = cleanCurrent.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return latestParts.length > currentParts.length;
    } catch (_) {
      return latestVersion != currentVersion;
    }
  }

  /// Check GitHub Releases for full APK releases
  Future<OtaReleaseInfo?> checkForUpdates({
    String? currentVersion,
    bool simulateMockIfNotFound = false,
  }) async {
    final effectiveVersion = currentVersion ?? AppConfig.currentVersion;
    state = state.copyWith(isChecking: true, errorMessage: null);

    try {
      final uri = Uri.parse(AppConfig.githubLatestReleaseApi);
      final response = await _httpClient.get(
        uri,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'SchoolManager-App',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final release = OtaReleaseInfo.fromGitHubJson(json);

        if (isNewerVersion(release.version, effectiveVersion)) {
          state = state.copyWith(
            isChecking: false,
            availableRelease: release,
          );
          return release;
        }
      }
    } catch (e) {
      debugPrint('OTA GitHub Releases Check network note: $e');
    }

    // Graceful offline / demo school fallback
    if (simulateMockIfNotFound && isNewerVersion('1.0.1', effectiveVersion)) {
      final mockRelease = OtaReleaseInfo(
        version: '1.0.1',
        title: 'School Manager v1.0.1: Smart Timetable & Instant Sync',
        changelog:
            '• In-app software update with progress tracker\n• Added instant 6-char Class Code join for students\n• Monthly attendance calendar with green/red markers\n• Unified in-app media viewer with 90° photo rotation\n• Admin 3-step Excel exam marks parser with CBSE A1-E grading',
        apkDownloadUrl:
            'https://github.com/${AppConfig.githubOwner}/${AppConfig.githubRepo}/releases/download/v1.0.1/school-manager-v1.0.1.apk',
        apkSizeBytes: 24 * 1024 * 1024,
        isForced: false,
        publishedAt: DateTime.now(),
      );

      state = state.copyWith(
        isChecking: false,
        availableRelease: mockRelease,
      );
      return mockRelease;
    }

    state = state.copyWith(isChecking: false, clearRelease: true);
    return null;
  }

  /// Download the APK with live stream progress and launch native installer
  Future<bool> downloadAndInstallUpdate({
    required OtaReleaseInfo release,
    void Function(double progress, int received, int total)? onProgress,
  }) async {
    if (kIsWeb) {
      debugPrint('OTA installation is only supported on Android/iOS.');
      return false;
    }

    state = state.copyWith(
      isDownloading: true,
      downloadProgress: 0.0,
      errorMessage: null,
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/school-manager-v${release.version}.apk');

      // Check if file is already completely downloaded
      if (await apkFile.exists()) {
        final existingSize = await apkFile.length();
        if (release.apkSizeBytes > 0 && (existingSize >= release.apkSizeBytes - 1024)) {
          debugPrint('OTA: APK already cached at ${apkFile.path} ($existingSize bytes). Launching installer.');
          state = state.copyWith(
            isDownloading: false,
            downloadProgress: 1.0,
            bytesDownloaded: existingSize,
            totalBytes: existingSize,
            localApkPath: apkFile.path,
          );
          onProgress?.call(1.0, existingSize, existingSize);
          await installApk(apkFile.path);
          return true;
        }
      }

      if (release.apkDownloadUrl.startsWith('http')) {
        final request = http.Request('GET', Uri.parse(release.apkDownloadUrl));
        final response = await _httpClient.send(request);

        final total = response.contentLength ?? release.apkSizeBytes;
        int received = 0;
        final sink = apkFile.openWrite();

        await response.stream.listen(
          (chunk) {
            received += chunk.length;
            sink.add(chunk);
            final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.5;
            state = state.copyWith(
              downloadProgress: progress,
              bytesDownloaded: received,
              totalBytes: total,
            );
            onProgress?.call(progress, received, total);
          },
        ).asFuture();

        await sink.flush();
        await sink.close();
      } else {
        for (int p = 1; p <= 10; p++) {
          await Future.delayed(const Duration(milliseconds: 150));
          final progress = p / 10.0;
          final received = (progress * release.apkSizeBytes).toInt();
          state = state.copyWith(
            downloadProgress: progress,
            bytesDownloaded: received,
            totalBytes: release.apkSizeBytes,
          );
          onProgress?.call(progress, received, release.apkSizeBytes);
        }
        await apkFile.writeAsString('DEMO_APK_CONTENT');
      }

      state = state.copyWith(
        isDownloading: false,
        downloadProgress: 1.0,
        localApkPath: apkFile.path,
      );

      // Launch native Android APK installer via OpenFilex with explicit MIME type
      if (Platform.isAndroid && await apkFile.exists()) {
        await installApk(apkFile.path);
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        errorMessage: 'Download failed: $e',
      );
      return false;
    }
  }

  /// Launch the Android native package installer for the downloaded APK
  static Future<OpenResult> installApk(String apkPath) async {
    try {
      final result = await OpenFilex.open(
        apkPath,
        type: 'application/vnd.android.package-archive',
      );
      debugPrint('OpenFilex launch installer result: ${result.type} - ${result.message}');
      return result;
    } catch (e) {
      debugPrint('OpenFilex error: $e');
      return OpenResult(type: ResultType.error, message: e.toString());
    }
  }

  /// Browser fallback for direct external package download & install
  static Future<void> launchBrowserDownload(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to open browser download: $e');
    }
  }

  void dismissUpdate() {
    state = state.copyWith(clearRelease: true, localApkPath: null);
  }
}
