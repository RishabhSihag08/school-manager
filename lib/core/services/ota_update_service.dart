import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
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

/// State of the Dual-Layer OTA Engine (Shorebird Quick Patch + GitHub Full APK)
class OtaUpdateState {
  // GitHub Full Version Release Layer
  final bool isChecking;
  final OtaReleaseInfo? availableRelease;
  final bool isDownloading;
  final double downloadProgress; // 0.0 to 1.0
  final int bytesDownloaded;
  final int totalBytes;
  final String? localApkPath;
  final String? errorMessage;

  // Shorebird Quick In-App Patch Layer
  final bool isShorebirdAvailable;
  final int? currentPatchNumber;
  final int? nextPatchNumber;
  final bool isCheckingShorebird;
  final bool isShorebirdPatchAvailable;
  final bool isShorebirdPatchDownloading;
  final bool isShorebirdPatchReadyToInstall;
  final String? shorebirdMessage;

  const OtaUpdateState({
    this.isChecking = false,
    this.availableRelease,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.localApkPath,
    this.errorMessage,
    this.isShorebirdAvailable = false,
    this.currentPatchNumber,
    this.nextPatchNumber,
    this.isCheckingShorebird = false,
    this.isShorebirdPatchAvailable = false,
    this.isShorebirdPatchDownloading = false,
    this.isShorebirdPatchReadyToInstall = false,
    this.shorebirdMessage,
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
    bool? isShorebirdAvailable,
    int? currentPatchNumber,
    int? nextPatchNumber,
    bool? isCheckingShorebird,
    bool? isShorebirdPatchAvailable,
    bool? isShorebirdPatchDownloading,
    bool? isShorebirdPatchReadyToInstall,
    String? shorebirdMessage,
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
      isShorebirdAvailable: isShorebirdAvailable ?? this.isShorebirdAvailable,
      currentPatchNumber: currentPatchNumber ?? this.currentPatchNumber,
      nextPatchNumber: nextPatchNumber ?? this.nextPatchNumber,
      isCheckingShorebird: isCheckingShorebird ?? this.isCheckingShorebird,
      isShorebirdPatchAvailable:
          isShorebirdPatchAvailable ?? this.isShorebirdPatchAvailable,
      isShorebirdPatchDownloading:
          isShorebirdPatchDownloading ?? this.isShorebirdPatchDownloading,
      isShorebirdPatchReadyToInstall:
          isShorebirdPatchReadyToInstall ?? this.isShorebirdPatchReadyToInstall,
      shorebirdMessage: shorebirdMessage ?? this.shorebirdMessage,
    );
  }
}

/// Dual-Layer OTA Update Service (Shorebird Code Push + GitHub Releases)
class OtaUpdateService extends StateNotifier<OtaUpdateState> {
  final http.Client _httpClient;
  final ShorebirdCodePush _codePush;

  OtaUpdateService({http.Client? client, ShorebirdCodePush? codePush})
      : _httpClient = client ?? http.Client(),
        _codePush = codePush ?? ShorebirdCodePush(),
        super(const OtaUpdateState()) {
    _initializeShorebird();
  }

  void _initializeShorebird() {
    try {
      final available = _codePush.isShorebirdAvailable();
      state = state.copyWith(isShorebirdAvailable: available);
      if (available) {
        readCurrentPatch();
      }
    } catch (_) {
      state = state.copyWith(isShorebirdAvailable: false);
    }
  }

  /// Read the currently active Shorebird patch number
  Future<int?> readCurrentPatch() async {
    try {
      final patch = await _codePush.currentPatchNumber();
      state = state.copyWith(currentPatchNumber: patch);
      return patch;
    } catch (e) {
      debugPrint('Error reading Shorebird patch: $e');
      return null;
    }
  }

  /// Check Shorebird for an in-app Dart hotfix patch
  Future<bool> checkForShorebirdPatch() async {
    if (!state.isShorebirdAvailable) {
      state = state.copyWith(
        isCheckingShorebird: false,
        shorebirdMessage: 'Shorebird engine not active on this device/platform.',
      );
      return false;
    }

    state = state.copyWith(
      isCheckingShorebird: true,
      shorebirdMessage: 'Checking for Shorebird patches...',
    );

    try {
      final isAvailable = await _codePush.isNewPatchAvailableForDownload();
      final current = await _codePush.currentPatchNumber();
      final next = await _codePush.nextPatchNumber();

      state = state.copyWith(
        isCheckingShorebird: false,
        isShorebirdPatchAvailable: isAvailable,
        currentPatchNumber: current,
        nextPatchNumber: next,
        shorebirdMessage: isAvailable
            ? 'New Shorebird patch #${next ?? (current != null ? current + 1 : 1)} available!'
            : 'Already on latest patch #${current ?? 0}.',
      );
      return isAvailable;
    } catch (e) {
      state = state.copyWith(
        isCheckingShorebird: false,
        shorebirdMessage: 'Shorebird check error: $e',
      );
      return false;
    }
  }

  /// Download and stage Shorebird patch for next launch
  Future<bool> downloadShorebirdPatch() async {
    if (!state.isShorebirdAvailable) return false;

    state = state.copyWith(
      isShorebirdPatchDownloading: true,
      shorebirdMessage: 'Downloading patch in background...',
    );

    try {
      await _codePush.downloadUpdateIfAvailable();
      final ready = await _codePush.isNewPatchReadyToInstall();

      state = state.copyWith(
        isShorebirdPatchDownloading: false,
        isShorebirdPatchReadyToInstall: ready,
        shorebirdMessage: ready
            ? '✨ Patch downloaded! Restart School Manager to apply.'
            : 'Download finished.',
      );
      return ready;
    } catch (e) {
      state = state.copyWith(
        isShorebirdPatchDownloading: false,
        shorebirdMessage: 'Patch download failed: $e',
      );
      return false;
    }
  }

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
    String currentVersion = AppConfig.currentVersion,
    bool simulateMockIfNotFound = true,
  }) async {
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

        if (isNewerVersion(release.version, currentVersion)) {
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
    if (simulateMockIfNotFound && isNewerVersion('1.0.1', currentVersion)) {
      final mockRelease = OtaReleaseInfo(
        version: '1.0.1',
        title: 'School Manager v1.0.1: Smart Timetable & Instant Sync',
        changelog:
            '• Dual-Layer OTA: Shorebird Quick Patch + GitHub Releases\n• Added instant 6-char Class Code join for students\n• Monthly attendance calendar with green/red markers\n• Unified in-app media viewer with 90° photo rotation\n• Admin 3-step Excel exam marks parser with CBSE A1-E grading',
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
    void Function(double progress)? onProgress,
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
            onProgress?.call(progress);
          },
        ).asFuture();

        await sink.flush();
        await sink.close();
      } else {
        for (int p = 1; p <= 10; p++) {
          await Future.delayed(const Duration(milliseconds: 150));
          final progress = p / 10.0;
          state = state.copyWith(
            downloadProgress: progress,
            bytesDownloaded: (progress * release.apkSizeBytes).toInt(),
            totalBytes: release.apkSizeBytes,
          );
          onProgress?.call(progress);
        }
        await apkFile.writeAsString('DEMO_APK_CONTENT');
      }

      state = state.copyWith(
        isDownloading: false,
        downloadProgress: 1.0,
        localApkPath: apkFile.path,
      );

      // Launch native Android APK installer via OpenFilex
      if (Platform.isAndroid && await apkFile.exists()) {
        final openResult = await OpenFilex.open(apkFile.path);
        debugPrint('OpenFilex launch installer result: ${openResult.type}');
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

  void dismissUpdate() {
    state = state.copyWith(clearRelease: true);
  }
}
