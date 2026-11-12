import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:school_manager/core/services/ota_update_service.dart';

/// Lightweight custom test HTTP client for unit tests
class MockHttpClient extends http.BaseClient {
  final http.Response Function(http.BaseRequest request) responseBuilder;

  MockHttpClient(this.responseBuilder);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = responseBuilder(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  group('OtaReleaseInfo GitHub JSON parsing', () {
    test('parses standard release JSON with v-prefix in tag', () {
      final json = {
        'tag_name': 'v1.2.0',
        'name': 'CampusVibe v1.2.0 - Attendance & Marks',
        'body': '• Smart attendance roll call\n• Excel import support',
        'published_at': '2026-11-12T10:00:00Z',
        'assets': [
          {
            'name': 'source-code.zip',
            'browser_download_url': 'https://github.com/owner/repo/archive.zip',
            'size': 1024,
          },
          {
            'name': 'campusvibe-v1.2.0.apk',
            'browser_download_url':
                'https://github.com/owner/repo/releases/download/v1.2.0/campusvibe.apk',
            'size': 26214400, // 25 MB
          },
        ],
      };

      final release = OtaReleaseInfo.fromGitHubJson(json);

      expect(release.version, equals('1.2.0'));
      expect(release.title, equals('CampusVibe v1.2.0 - Attendance & Marks'));
      expect(release.changelog, contains('Smart attendance roll call'));
      expect(release.apkDownloadUrl,
          equals('https://github.com/owner/repo/releases/download/v1.2.0/campusvibe.apk'));
      expect(release.apkSizeBytes, equals(26214400));
      expect(release.formattedSize, equals('25.0 MB'));
      expect(release.isForced, isFalse);
    });

    test('detects forced update with [forced_update] tag in body', () {
      final json = {
        'tag_name': 'v2.0.0',
        'name': 'Critical Migration',
        'body': '[forced_update]\nMandatory database upgrade required.',
        'published_at': '2026-11-12T10:00:00Z',
        'assets': [
          {
            'name': 'app-release.apk',
            'browser_download_url': 'https://example.com/app.apk',
            'size': 10485760,
          }
        ],
      };

      final release = OtaReleaseInfo.fromGitHubJson(json);
      expect(release.isForced, isTrue);
    });

    test('detects forced update with "critical security update" phrase', () {
      final json = {
        'tag_name': '1.0.5',
        'name': 'Hotfix',
        'body': 'Notice: This is a critical security update for all users.',
        'assets': <Map<String, dynamic>>[],
      };

      final release = OtaReleaseInfo.fromGitHubJson(json);
      expect(release.isForced, isTrue);
      expect(release.version, equals('1.0.5'));
      expect(release.apkDownloadUrl, isEmpty);
      expect(release.formattedSize, equals('Unknown size'));
    });
  });

  group('OtaUpdateService version comparison', () {
    test('identifies newer major, minor, and patch versions', () {
      expect(OtaUpdateService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
      expect(OtaUpdateService.isNewerVersion('1.1.0', '1.0.9'), isTrue);
      expect(OtaUpdateService.isNewerVersion('2.0.0', '1.99.99'), isTrue);
      expect(OtaUpdateService.isNewerVersion('1.0.0.1', '1.0.0'), isTrue);
    });

    test('rejects older or identical versions', () {
      expect(OtaUpdateService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
      expect(OtaUpdateService.isNewerVersion('1.0.0', '1.0.1'), isFalse);
      expect(OtaUpdateService.isNewerVersion('1.2.0', '1.3.0'), isFalse);
      expect(OtaUpdateService.isNewerVersion('0.9.9', '1.0.0'), isFalse);
    });

    test('strips leading "v" or non-numeric prefixes cleanly', () {
      expect(OtaUpdateService.isNewerVersion('v1.0.2', 'v1.0.1'), isTrue);
      expect(OtaUpdateService.isNewerVersion('v1.0.0', '1.0.0'), isFalse);
    });
  });

  group('OtaUpdateService API check lifecycle', () {
    test('returns OtaReleaseInfo when GitHub returns newer version', () async {
      final mockJson = jsonEncode({
        'tag_name': 'v1.5.0',
        'name': 'Release 1.5.0',
        'body': 'Changelog details',
        'published_at': '2026-11-12T12:00:00Z',
        'assets': [
          {
            'name': 'campusvibe.apk',
            'browser_download_url': 'https://github.com/school/app/v1.5.0.apk',
            'size': 15728640,
          }
        ],
      });

      final client = MockHttpClient((request) {
        return http.Response(
          mockJson,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = OtaUpdateService(client: client);
      final release = await service.checkForUpdates(
        currentVersion: '1.0.0',
        simulateMockIfNotFound: false,
      );

      expect(release, isNotNull);
      expect(release!.version, equals('1.5.0'));
      expect(service.state.availableRelease, equals(release));
      expect(service.state.isChecking, isFalse);

      service.dismissUpdate();
      expect(service.state.availableRelease, isNull);
    });

    test('returns null when GitHub version is not newer', () async {
      final mockJson = jsonEncode({
        'tag_name': 'v1.0.0',
        'name': 'Release 1.0.0',
        'body': 'Already on this version',
        'assets': <Map<String, dynamic>>[],
      });

      final client = MockHttpClient((request) {
        return http.Response(mockJson, 200);
      });

      final service = OtaUpdateService(client: client);
      final release = await service.checkForUpdates(
        currentVersion: '1.0.0',
        simulateMockIfNotFound: false,
      );

      expect(release, isNull);
      expect(service.state.availableRelease, isNull);
      expect(service.state.isChecking, isFalse);
    });
  });

  group('Dual-Layer OTA Shorebird Quick Patch Engine', () {
    test('initializes Shorebird state safely in non-engine environments', () {
      final service = OtaUpdateService();
      expect(service.state.isCheckingShorebird, isFalse);
      expect(service.state.isShorebirdPatchDownloading, isFalse);
      expect(service.state.isShorebirdPatchReadyToInstall, isFalse);
    });

    test('checkForShorebirdPatch returns false when engine is not active', () async {
      final service = OtaUpdateService();
      final hasPatch = await service.checkForShorebirdPatch();
      expect(hasPatch, isFalse);
      expect(service.state.isCheckingShorebird, isFalse);
    });
  });
}
