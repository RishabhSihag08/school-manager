import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/providers/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/session_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/ota_update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();

  if (AppConfig.hasSupabaseCredentials) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization note: $e');
    }
  }

  // Determine initial navigation route based on saved session
  final initialRoute = await SessionService.getSavedInitialRoute();

  runApp(
    ProviderScope(
      overrides: [
        initialRouteProvider.overrideWith((ref) => initialRoute),
      ],
      child: const SchoolManagerApp(),
    ),
  );
}

/// Root School Manager Application
class SchoolManagerApp extends ConsumerStatefulWidget {
  const SchoolManagerApp({super.key});

  @override
  ConsumerState<SchoolManagerApp> createState() => _SchoolManagerAppState();
}

class _SchoolManagerAppState extends ConsumerState<SchoolManagerApp> {
  @override
  void initState() {
    super.initState();
    // Restore session state into Riverpod providers
    SessionService.restoreSession(ref);

    // OTA startup check (GitHub Releases)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStartupOtaChecks();
    });
  }

  Future<void> _runStartupOtaChecks() async {
    final otaNotifier = ref.read(otaUpdateProvider.notifier);

    // GitHub Releases full APK release check
    // If a new version exists, show mandatory update gate before using the app
    final release = await otaNotifier.checkForUpdates(simulateMockIfNotFound: false);
    if (release != null && mounted) {
      final router = ref.read(appRouterProvider);
      final navContext = router.routerDelegate.navigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        OtaUpdateDialog.show(
          navContext,
          release: release,
          isMandatory: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final reduceMotion = ref.watch(reduceMotionProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
