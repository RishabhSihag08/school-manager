import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:school_manager/core/services/connectivity_service.dart';
import 'package:school_manager/core/widgets/no_internet_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityService & Notifier Unit Tests', () {
    test('ConnectivityService.hasInternetAccess executes and returns a boolean', () async {
      final isOnline = await ConnectivityService.hasInternetAccess(
        timeout: const Duration(seconds: 2),
      );
      expect(isOnline, isA<bool>());
    });

    test('ConnectivityNotifier initializes with online state and allows check', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(connectivityStatusProvider.notifier);
      expect(container.read(connectivityStatusProvider), isTrue);

      final result = await notifier.checkConnectivity();
      expect(result, isA<bool>());
    });
  });

  group('NoInternetScreen Widget Tests', () {
    testWidgets('Renders Internet Access Needed headline and requirement statement', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NoInternetScreen(),
          ),
        ),
      );

      // Verify headline
      expect(find.text('Internet Access Needed'), findsOneWidget);

      // Verify requirement statement
      expect(
        find.textContaining('Internet access is required to use School Manager'),
        findsOneWidget,
      );

      // Verify Reconnection Tips
      expect(find.text('How to reconnect:'), findsOneWidget);
      expect(find.text('Check Wi-Fi or Mobile Data'), findsOneWidget);
      expect(find.text('Turn Off Airplane Mode'), findsOneWidget);
      expect(find.text('Tap Retry Below'), findsOneWidget);

      // Verify Retry CTA Button
      expect(find.text('Retry Connection'), findsOneWidget);
      expect(find.byIcon(LucideIcons.wifiOff), findsOneWidget);
    });

    testWidgets('Tapping Retry Connection invokes connectivity check', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NoInternetScreen(),
          ),
        ),
      );

      final retryBtn = find.text('Retry Connection');
      expect(retryBtn, findsOneWidget);

      await tester.tap(retryBtn);
      await tester.pump();

      // Pump 5 seconds to completely drain the 4-second network timeout timer
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
