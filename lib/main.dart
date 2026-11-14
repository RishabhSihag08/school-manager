import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/providers/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/session_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/no_internet_screen.dart';
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

  // Determine initial navigation route and pre-restore session data before runApp
  final initialRoute = await SessionService.getSavedInitialRoute();
  final restoredStudent = await SessionService.getSavedStudent();
  final restoredStaff = await SessionService.getSavedStaff();
  final restoredRole = await SessionService.getSavedRole();

  runApp(
    ProviderScope(
      overrides: [
        initialRouteProvider.overrideWith((ref) => initialRoute),
        if (restoredStudent != null)
          currentStudentProvider.overrideWith((ref) => restoredStudent),
        if (restoredStaff != null)
          currentStaffProvider.overrideWith((ref) => restoredStaff),
        if (restoredRole != null)
          activeRoleProvider.overrideWith((ref) => restoredRole),
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

class _SchoolManagerAppState extends ConsumerState<SchoolManagerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial check for internet connectivity on app launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectivityStatusProvider.notifier).checkConnectivity();
      _runStartupOtaChecks();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Auto-refresh network status and trigger screen refresh when reopening the app
      ref.read(connectivityStatusProvider.notifier).checkConnectivity();
      ref.read(appRefreshTriggerProvider.notifier).state++;
    }
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
    final isOnline = ref.watch(connectivityStatusProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: reduceMotion,
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            if (!isOnline)
              const Positioned.fill(
                child: NoInternetScreen(),
              ),
          ],
        );
      },
    );
  }
}
