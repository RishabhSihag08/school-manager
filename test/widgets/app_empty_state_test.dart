import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:school_manager/core/widgets/app_empty_state.dart';

void main() {
  group('AppEmptyState Widget Tests', () {
    testWidgets('renders title, subtitle, icon and triggers primary CTA', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: LucideIcons.bookOpen,
              title: 'No Homework Yet',
              subtitle: 'Your teachers have not posted any homework assignments.',
              ctaLabel: '+ Create Homework',
              onCtaPressed: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Homework Yet'), findsOneWidget);
      expect(find.text('Your teachers have not posted any homework assignments.'), findsOneWidget);
      expect(find.text('+ Create Homework'), findsOneWidget);

      await tester.tap(find.text('+ Create Homework'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('AppEmptyState.action factory renders correctly and handles secondary CTA', (tester) async {
      bool secondaryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState.action(
              title: 'Empty State Action',
              subtitle: 'Testing secondary action functionality.',
              actionLabel: 'Primary',
              onAction: () {},
              secondaryActionLabel: 'Learn More',
              onSecondaryAction: () => secondaryTapped = true,
              isCard: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Empty State Action'), findsOneWidget);
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Learn More'), findsOneWidget);

      await tester.tap(find.text('Learn More'));
      await tester.pumpAndSettle();

      expect(secondaryTapped, isTrue);
    });
  });
}
