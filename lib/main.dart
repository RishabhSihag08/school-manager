import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/providers/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/ota_update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SchoolManagerApp(),
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
    // Dual-layer OTA startup check (Shorebird Quick Patch + GitHub Releases)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStartupOtaChecks();
    });
  }

  Future<void> _runStartupOtaChecks() async {
    final otaNotifier = ref.read(otaUpdateProvider.notifier);

    // 1. Shorebird in-app quick patch check & silent download
    final hasPatch = await otaNotifier.checkForShorebirdPatch();
    if (hasPatch && mounted) {
      await otaNotifier.downloadShorebirdPatch();
    }

    // 2. GitHub Releases full APK release check
    final release = await otaNotifier.checkForUpdates(simulateMockIfNotFound: false);
    if (release != null && mounted) {
      // If forced update, trigger the modal immediately
      if (release.isForced) {
        final router = ref.read(appRouterProvider);
        final navContext = router.routerDelegate.navigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
          OtaUpdateDialog.show(navContext, release: release);
        }
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
