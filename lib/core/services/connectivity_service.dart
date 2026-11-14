import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Real-time internet connectivity checker and notifier
class ConnectivityService {
  ConnectivityService._();

  /// Check whether the device has true, reachable internet access.
  /// On mobile/desktop, it performs DNS lookups and HTTP fallback.
  /// On Web, it performs a quick HTTP GET/HEAD request.
  static Future<bool> hasInternetAccess({Duration timeout = const Duration(seconds: 4)}) async {
    // In test environment, bypass external socket/DNS probes to avoid hanging fake async timers
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }

    try {
      if (kIsWeb) {
        return await _checkHttpProbe(timeout);
      }

      // 1. Try DNS lookup on reliable host
      try {
        final result = await InternetAddress.lookup('google.com').timeout(timeout);
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        // DNS lookup failed, try secondary probe
      }

      // 2. Try secondary host DNS
      try {
        final result = await InternetAddress.lookup('one.one.one.one').timeout(timeout);
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        // Fallback to HTTP probe
      }

      // 3. Fallback to HTTP probe
      return await _checkHttpProbe(timeout);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _checkHttpProbe(Duration timeout) async {
    // If Supabase is configured, probe it or a standard generate_204 endpoint
    final probeUrls = [
      if (AppConfig.hasSupabaseCredentials)
        '${AppConfig.supabaseUrl}/rest/v1/',
      'https://www.google.com/generate_204',
      'https://1.1.1.1',
    ];

    for (final url in probeUrls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(timeout);
        if (res.statusCode >= 200 && res.statusCode < 500) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }
}

/// Manages and broadcasts reactive internet connectivity state
class ConnectivityNotifier extends StateNotifier<bool> {
  final Ref _ref;
  Timer? _pollingTimer;
  bool _isChecking = false;

  ConnectivityNotifier(this._ref) : super(true) {
    _startMonitoring();
  }

  void _startMonitoring() {
    // In test environment, skip periodic polling to allow tester.pumpAndSettle() to settle cleanly
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    // Run an immediate check on startup
    checkConnectivity();

    // Periodically poll every 6 seconds to detect network drops or restoration
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      checkConnectivity();
    });
  }

  /// Explicitly triggers an internet check (e.g. from Retry button or app resume)
  Future<bool> checkConnectivity() async {
    if (_isChecking) return state;
    _isChecking = true;

    try {
      final isOnline = await ConnectivityService.hasInternetAccess();
      if (mounted) {
        final wasOffline = !state;
        state = isOnline;

        // If connection was just restored, trigger auto-refresh across active screens
        if (wasOffline && isOnline) {
          debugPrint('ConnectivityNotifier: Internet connection restored! Triggering auto-refresh.');
          _ref.read(appRefreshTriggerProvider.notifier).state++;
        }
      }
      return isOnline;
    } finally {
      _isChecking = false;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

/// Global provider for internet connectivity status (true = connected, false = offline)
final connectivityStatusProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier(ref);
});

/// Global provider to notify active views to auto-refresh their data
final appRefreshTriggerProvider = StateProvider<int>((ref) => 0);
