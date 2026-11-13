import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_manager/core/models/models.dart';
import 'package:school_manager/core/providers/core_providers.dart';
import 'package:school_manager/core/repositories/mock_school_repository.dart';
import 'package:school_manager/features/admin/admin_teachers_screen.dart';

void main() {
  group('Admin Teacher Management & Directory Tests', () {
    late MockSchoolRepository repository;
    late ClassSection cls6b;
    late ClassSection cls10a;

    setUp(() async {
      repository = MockSchoolRepository();

      cls6b = await repository.createClassSection(
        grade: 6,
        section: 'B',
        classCode: '6B-TEST',
      );

      cls10a = await repository.createClassSection(
        grade: 10,
        section: 'A',
        classCode: '10A-TEST',
      );

      await repository.registerStaff(
        fullName: 'Dr. R.K. Sharma',
        role: 'teacher',
        loginCode: 'T-101',
        pin: '2026',
        phone: '+91 98765 43210',
        homeroomClassId: cls6b.id,
        homeroomClassName: 'Class 6-B',
        subjectName: 'Mathematics',
        subjectCode: 'MATH',
        teachingClassIds: [cls6b.id],
      );
    });

    test('Repository returns all teachers with allocations and homeroom', () async {
      final teachers = await repository.getAllTeachers();
      expect(teachers.isNotEmpty, isTrue);

      final rkSharma = teachers.firstWhere((t) => t.loginCode == 't-101');
      expect(rkSharma.fullName, 'Dr. R.K. Sharma');
      expect(rkSharma.role, 'teacher');
      expect(rkSharma.pin, '2026');
      expect(rkSharma.phone, '+91 98765 43210');
      expect(rkSharma.subjectName, 'Mathematics');
      expect(rkSharma.isClassTeacher, isTrue);
      expect(rkSharma.teachingClassIds, contains(cls6b.id));
    });

    test('Repository updates all details of a teacher including homeroom sync', () async {
      final teachers = await repository.getAllTeachers();
      final original = teachers.firstWhere((t) => t.loginCode == 't-101');

      final saved = await repository.updateTeacher(
        teacherId: original.id,
        fullName: 'Dr. Rajesh Kumar Sharma',
        loginCode: 'T-999',
        pin: '9876',
        phone: '+91 91234 56789',
        email: 'rajesh.sharma@school.edu',
        subjectName: 'Advanced Physics',
        subjectCode: 'PHY',
        homeroomClassId: cls10a.id,
        homeroomClassName: 'Class 10-A',
        teachingClassIds: [cls10a.id, cls6b.id],
      );

      expect(saved.fullName, 'Dr. Rajesh Kumar Sharma');
      expect(saved.loginCode, 't-999');
      expect(saved.pin, '9876');
      expect(saved.phone, '+91 91234 56789');
      expect(saved.email, 'rajesh.sharma@school.edu');
      expect(saved.subjectName, 'Advanced Physics');
      expect(saved.subjectCode, 'PHY');
      expect(saved.homeroomClassId, cls10a.id);
      expect(saved.homeroomClassName, 'Class 10-A');
      expect(saved.teachingClassIds, containsAll([cls10a.id, cls6b.id]));

      // Verify homeroom class in-charge synchronization
      final classes = await repository.getAllClassSections();
      final updatedClass10A = classes.firstWhere((c) => c.id == cls10a.id);
      expect(updatedClass10A.classTeacherName, 'Dr. Rajesh Kumar Sharma');

      // Previous homeroom (cls6b) should be unassigned
      final updatedClass6B = classes.firstWhere((c) => c.id == cls6b.id);
      expect(updatedClass6B.classTeacherId, isNull);
    });

    test('Repository deletes a teacher and cleans up all class assignments', () async {
      final initialTeachers = await repository.getAllTeachers();
      final teacherToDelete = initialTeachers.firstWhere((t) => t.loginCode == 't-101');

      await repository.deleteTeacher(teacherToDelete.id);

      final remainingTeachers = await repository.getAllTeachers();
      expect(remainingTeachers.any((t) => t.id == teacherToDelete.id), isFalse);

      // Verify homeroom class teacher was cleared
      final classes = await repository.getAllClassSections();
      final updatedClass6B = classes.firstWhere((c) => c.id == cls6b.id);
      expect(updatedClass6B.classTeacherId, isNull);
      expect(updatedClass6B.classTeacherName, isNull);

      // Verify subject allocations were removed
      final allocations = await repository.getAllSubjectAllocations();
      expect(allocations.any((a) => a['teacher_id'] == teacherToDelete.id), isFalse);
    });

    testWidgets('AdminTeachersScreen displays teacher bento cards and stats',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
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
            home: Scaffold(
              body: AdminTeachersScreen(isEmbedded: true),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Faculty & Teachers Directory'), findsOneWidget);
      expect(find.text('Dr. R.K. Sharma'), findsOneWidget);
      expect(find.text('T-101'), findsOneWidget);
      expect(find.text('Add Teacher'), findsOneWidget);
      expect(find.text('Class 6-B In-Charge'), findsOneWidget);
    });

    testWidgets('Search and filter chips filter teacher roster dynamically',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
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
            home: Scaffold(
              body: AdminTeachersScreen(isEmbedded: true),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Filter by searching for "T-101"
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'T-101');
      await tester.pumpAndSettle();

      expect(find.text('Dr. R.K. Sharma'), findsOneWidget);

      // Search for non-existent teacher
      await tester.enterText(searchField, 'NonExistentTeacherNameXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No matching teachers found'), findsOneWidget);
    });
  });
}
