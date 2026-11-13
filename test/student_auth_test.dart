import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_manager/core/models/student.dart';
import 'package:school_manager/core/providers/core_providers.dart';
import 'package:school_manager/core/repositories/mock_school_repository.dart';
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
    testWidgets('WelcomeRoleScreen renders 2-step onboarding with 3 Bento role cards',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: WelcomeRoleScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: "What are you?" & 3 Bento role cards
      expect(find.text('School Manager'), findsWidgets);
      expect(find.text('What are you?'), findsOneWidget);
      expect(find.text('Student / Parent'), findsOneWidget);
      expect(find.text('Teacher / Faculty'), findsOneWidget);
      expect(find.text('Staff / Administration'), findsOneWidget);

      // Tap Student Bento card to enter Step 2
      await tester.tap(find.text('Student / Parent'));
      await tester.pumpAndSettle();

      // Step 2: "Change Role", Log in options, and Create Account
      expect(find.text('Change Role'), findsOneWidget);
      expect(find.text('Log In to Existing Account'), findsOneWidget);
      expect(find.text('Join with Class Code'), findsOneWidget);
      expect(find.text('Log In to Student Shell'), findsOneWidget);
      expect(find.text('Create New Account'), findsOneWidget);
    });

    testWidgets(
        'JoinClassCodeScreen renders ticket, verifies 8B-K9X2, with house shields removed',
        (tester) async {
      final mockRepo = MockSchoolRepository();
      await mockRepo.createClassSection(
        grade: 8,
        section: 'B',
        classCode: '8B-K9X2',
        classTeacherName: 'Dr. Radhakrishnan',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: JoinClassCodeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Join Class with Code'), findsOneWidget);
      expect(find.text('Enter 6-Char Class Code'), findsOneWidget);
      expect(find.text('Paste Class Code'), findsOneWidget);

      // Enter class code into TextField
      await tester.enterText(find.byType(TextField).first, '8B-K9X2');
      await tester.pumpAndSettle();

      // Class 8-B verification banner should appear
      expect(find.textContaining('Found Class 8-B'), findsOneWidget);
      expect(find.textContaining('Dr. Radhakrishnan'), findsOneWidget);

      // House shields should NOT be present
      expect(find.text('Select Student House'), findsNothing);
      expect(find.text('Red House'), findsNothing);

      // Submit CTA should be visible
      expect(find.text('Complete Registration & Enter Class'), findsOneWidget);
    });

    testWidgets('SiblingSwitcherSheet displays linked children and switch option',
        (tester) async {
      const testStudent = Student(
        id: 'test-student-1',
        rollNo: 1,
        fullName: 'Test Student',
        classSectionId: 'class-8b',
        parentName: 'Parent',
        parentPhone: '+91 98765 00000',
        pinHash: '1234',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            linkedSiblingsProvider.overrideWith((ref) => [testStudent]),
          ],
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
      expect(find.text('Test Student'), findsOneWidget);
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

    testWidgets('TimetableViewScreen renders dedicated timetable photo viewer',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: TimetableViewScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Timetable'), findsWidgets);
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

    testWidgets('StudentResultsScreen renders summary and exam selector',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: StudentResultsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Exam Results'), findsOneWidget);
      expect(find.text('Half Yearly Examination'), findsWidgets);
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
      expect(find.text('Software Update'), findsOneWidget);
      expect(find.text('Motion & Accessibility'), findsOneWidget);
      expect(find.text('Reduce Motion'), findsOneWidget);
      expect(find.text('System Information'), findsOneWidget);
      expect(find.text('Installed Version'), findsOneWidget);
    });
  });
}
