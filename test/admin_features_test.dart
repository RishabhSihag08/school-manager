import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_manager/core/providers/core_providers.dart';
import 'package:school_manager/core/repositories/mock_school_repository.dart';
import 'package:school_manager/features/admin/admin_shell.dart';

void main() {
  group('Admin Features & Management Tests', () {
    late MockSchoolRepository repository;

    setUp(() {
      repository = MockSchoolRepository();
    });

    test('Admin can create a new class section', () async {
      final initialClasses = await repository.getAllClassSections();
      final initialCount = initialClasses.length;

      final newClass = await repository.createClassSection(
        grade: 10,
        section: 'C',
        classCode: '10C-XYZ9',
        classTeacherName: 'Mrs. Kavita Sharma',
      );

      expect(newClass.grade, 10);
      expect(newClass.section, 'C');
      expect(newClass.classCode, '10C-XYZ9');
      expect(newClass.classTeacherName, 'Mrs. Kavita Sharma');

      final updatedClasses = await repository.getAllClassSections();
      expect(updatedClasses.length, initialCount + 1);
      expect(updatedClasses.any((c) => c.classCode == '10C-XYZ9'), isTrue);
    });

    test('Admin can update any student record and reset PIN', () async {
      // First ensure a class and student exist
      final cls = await repository.createClassSection(
        grade: 9,
        section: 'A',
        classCode: '9A-TEST',
      );

      final student = await repository.registerStudentWithCode(
        classCode: '9A-TEST',
        fullName: 'Original Student Name',
        rollNo: 5,
        parentName: 'Original Parent',
        parentPhone: '+919876543210',
        house: 'blue',
        pin: '1111',
      );

      expect(student.fullName, 'Original Student Name');
      expect(student.rollNo, 5);
      expect(student.pinHash, '1111');

      // Admin updates student data and resets PIN
      final modifiedStudent = student.copyWith(
        fullName: 'Updated Student Name',
        rollNo: 12,
        admissionNo: 'ADM2026999',
        parentName: 'New Parent Guardian',
        parentPhone: '+919999888877',
        pinHash: '4321', // Reset PIN
      );

      final result = await repository.updateStudent(modifiedStudent);

      expect(result.fullName, 'Updated Student Name');
      expect(result.rollNo, 12);
      expect(result.admissionNo, 'ADM2026999');
      expect(result.parentName, 'New Parent Guardian');
      expect(result.parentPhone, '+919999888877');
      expect(result.pinHash, '4321');

      // Verify persistence in repository
      final studentsInClass = await repository.getStudentsForClass(cls.id);
      final persisted = studentsInClass.firstWhere((s) => s.id == student.id);
      expect(persisted.fullName, 'Updated Student Name');
      expect(persisted.rollNo, 12);
      expect(persisted.pinHash, '4321');
    });

    testWidgets('AdminShell renders navigation and admin management views',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: AdminShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for Header branding and Nav items
      expect(find.text('Classes & Sections Management'), findsOneWidget);
      expect(find.text('+ Create New Class / Section'), findsOneWidget);
      expect(find.text('Classes & Sections'), findsOneWidget);
      expect(find.text('Student Directory'), findsOneWidget);
      expect(find.text('Subject Matrix'), findsOneWidget);
      expect(find.text('Excel Marks Wizard'), findsOneWidget);
      expect(find.text('Log Out'), findsWidgets);
    });
  });
}
