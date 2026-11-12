import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_manager/features/auth/join_class_code_screen.dart';
import 'package:school_manager/features/auth/sibling_switcher_sheet.dart';
import 'package:school_manager/features/auth/welcome_role_screen.dart';
import 'package:school_manager/features/settings/settings_screen.dart';
import 'package:school_manager/features/student/student_attendance_calendar_screen.dart';
import 'package:school_manager/features/student/student_bento_home.dart';
import 'package:school_manager/features/student/student_results_screen.dart';
import 'package:school_manager/features/student/syllabus_vault_screen.dart';
import 'package:school_manager/features/student/timetable_view_screen.dart';

void main() {
  group('CampusVibe Student, Auth & Settings Feature Tests', () {
    testWidgets('WelcomeRoleScreen renders brand and primary join ticket',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: WelcomeRoleScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('School Manager'), findsWidgets);
      expect(find.text('Delhi Public Academy'), findsOneWidget);
      expect(find.text('Join Class with Code'), findsOneWidget);
      expect(find.text('Student Login'), findsOneWidget);
      expect(find.text('Staff Portal'), findsOneWidget);
      expect(find.text('Student Aarav'), findsOneWidget);
    });

    testWidgets(
        'JoinClassCodeScreen renders ticket, verifies 8B-K9X2, and exposes house shields',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: JoinClassCodeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Join Class with Code'), findsOneWidget);
      expect(find.text('Enter 6-Char Class Code'), findsOneWidget);
      expect(find.text('Paste Class Code'), findsOneWidget);

      // Tap demo autofill button
      final demoButton = find.text('Demo 8B-K9X2');
      expect(demoButton, findsOneWidget);
      await tester.tap(demoButton);
      await tester.pumpAndSettle();

      // Class 8-B verification banner should appear
      expect(find.textContaining('Found Class 8-B'), findsOneWidget);
      expect(find.textContaining('Ramesh Sharma'), findsOneWidget);

      // House shields should be present
      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
      expect(find.text('Yellow'), findsOneWidget);

      // Submit CTA should be visible
      expect(find.text('Complete Registration & Enter Class'), findsOneWidget);
    });

    testWidgets('SiblingSwitcherSheet displays linked children and switch option',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => SiblingSwitcherSheet.show(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Linked Children'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Kabir Verma'), findsOneWidget);
      expect(find.text('+ Add Another Child (Class Code)'), findsOneWidget);
    });

    testWidgets('StudentBentoHome renders Bento grid and streak mission',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: StudentBentoHome()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today\'s Homework Mission'), findsOneWidget);
      expect(find.textContaining('Streak'), findsWidgets);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Exam Hub'), findsOneWidget);
      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('Syllabus'), findsOneWidget);
      expect(find.text('Notices'), findsOneWidget);
      expect(find.text('Due Homework & Tasks'), findsOneWidget);
    });

    testWidgets('StudentAttendanceCalendarScreen renders calendar and stats',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: StudentAttendanceCalendarScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Monthly Attendance'), findsOneWidget);
      expect(find.text('Overall Attendance'), findsOneWidget);
      expect(find.text('Present'), findsWidgets);
      expect(find.text('Absent'), findsWidgets);
      expect(find.text('Leave'), findsWidgets);
    });

    testWidgets('TimetableViewScreen renders day pills and recess break',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: TimetableViewScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Class Timetable'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Master Chart'), findsOneWidget);
    });

    testWidgets('SyllabusVaultScreen renders exam term filters',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SyllabusVaultScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Syllabus Vault'), findsOneWidget);
      expect(find.text('All Terms'), findsOneWidget);
      expect(find.text('UT 1'), findsOneWidget);
      expect(find.text('Half Yearly'), findsWidgets);
      expect(find.text('UT 2'), findsOneWidget);
      expect(find.text('Finals'), findsOneWidget);
    });

    testWidgets('StudentResultsScreen renders summary and CBSE report card trigger',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: StudentResultsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Exam Results'), findsOneWidget);
      expect(find.text('Half Yearly Examination'), findsWidgets);
      expect(find.text('Download Official CBSE Report Card (PDF)'), findsOneWidget);
      expect(find.text('Subject Scores vs 100 Max'), findsOneWidget);
      expect(find.text('Subject Breakdown'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders OTA update hub and reduce motion toggle',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings & Updates'), findsOneWidget);
      expect(find.text('Quick Patch Channel (Shorebird)'), findsOneWidget);
      expect(find.text('Full Version Channel (GitHub)'), findsOneWidget);
      expect(find.text('Motion & Accessibility'), findsOneWidget);
      expect(find.text('Reduce Motion'), findsOneWidget);
      expect(find.text('System Information'), findsOneWidget);
      expect(find.text('Installed Version'), findsOneWidget);
    });
  });
}
