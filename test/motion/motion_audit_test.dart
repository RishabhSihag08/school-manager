import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_manager/core/theme/app_motion.dart';
import 'package:school_manager/core/widgets/tactile_feedback.dart';

void main() {
  group('AppMotion Emil Kowalski Token Integrity Audit', () {
    test('Curves follow Emil Kowalski specifications', () {
      expect(AppMotion.easeOut, equals(const Cubic(0.23, 1.0, 0.32, 1.0)));
      expect(AppMotion.easeInOut, equals(const Cubic(0.77, 0.0, 0.175, 1.0)));
      expect(AppMotion.easeDrawer, equals(const Cubic(0.32, 0.72, 0.0, 1.0)));
    });

    test('UI animation durations are strictly <= 300ms', () {
      expect(AppMotion.durationPress.inMilliseconds, lessThanOrEqualTo(300));
      expect(AppMotion.durationFast.inMilliseconds, lessThanOrEqualTo(300));
      expect(AppMotion.durationStandard.inMilliseconds, lessThanOrEqualTo(300));
      expect(AppMotion.durationModal.inMilliseconds, lessThanOrEqualTo(300));

      expect(AppMotion.durationPress.inMilliseconds, equals(140));
    });

    test('Physicality scales: press scale is 0.97 and no scale(0)', () {
      expect(AppMotion.pressScale, equals(0.97));
      expect(AppMotion.entryInitialScale, equals(0.95));
      expect(AppMotion.entryInitialScale, greaterThan(0.0));
    });
  });

  group('TactileFeedback Widget Audit', () {
    testWidgets('scales down to 0.97 on press when animations are enabled',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TactileFeedback(
                onTap: () => tapped = true,
                child: const SizedBox(
                  key: Key('button-box'),
                  width: 100,
                  height: 100,
                ),
              ),
            ),
          ),
        ),
      );

      // Verify AnimatedScale initial scale is 1.0
      final initialScaleFinder = find.byType(AnimatedScale);
      expect(initialScaleFinder, findsOneWidget);
      AnimatedScale initialScale = tester.widget(initialScaleFinder);
      expect(initialScale.scale, equals(1.0));

      // Press down
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('button-box'))));
      await tester.pump();

      AnimatedScale pressedScale = tester.widget(initialScaleFinder);
      expect(pressedScale.scale, equals(0.97));

      // Release
      await gesture.up();
      await tester.pump();
      await tester.pumpAndSettle();

      AnimatedScale releasedScale = tester.widget(initialScaleFinder);
      expect(releasedScale.scale, equals(1.0));
      expect(tapped, isTrue);
    });

    testWidgets('gates animation duration to zero when reduced-motion is requested',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: TactileFeedback(
                  onTap: () {},
                  child: const Text('Accessible Button'),
                ),
              ),
            ),
          ),
        ),
      );

      final animatedScaleFinder = find.byType(AnimatedScale);
      final AnimatedScale scaleWidget = tester.widget(animatedScaleFinder);

      // When disableAnimations is true, duration should be Duration.zero
      expect(scaleWidget.duration, equals(Duration.zero));
    });
  });
}
