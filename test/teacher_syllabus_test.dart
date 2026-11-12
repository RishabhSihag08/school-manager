import 'package:flutter_test/flutter_test.dart';
import 'package:school_manager/core/models/models.dart';
import 'package:school_manager/core/repositories/mock_school_repository.dart';

void main() {
  group('Teacher Subject Registration & Allocations (Problem 3 & 5)', () {
    late MockSchoolRepository repository;

    setUp(() {
      repository = MockSchoolRepository();
    });

    test('registerStaff stores teaching subject_name and subject_code', () async {
      final staff = await repository.registerStaff(
        fullName: 'Mrs. Sunita Verma',
        role: 'teacher',
        loginCode: 'sunita',
        pin: '1234',
        subjectName: 'Science',
        subjectCode: 'SCI',
      );

      expect(staff['full_name'], 'Mrs. Sunita Verma');
      expect(staff['role'], 'teacher');
      expect(staff['subject_name'], 'Science');
      expect(staff['subject_code'], 'SCI');
    });

    test('getTeacherSubjectAllocations returns allocated classes with teacher subject', () async {
      final staff = await repository.registerStaff(
        fullName: 'Mr. Arvind Rao',
        role: 'teacher',
        loginCode: 'arvind',
        pin: '5678',
        subjectName: 'English',
        subjectCode: 'ENG',
      );

      final allocations = await repository.getTeacherSubjectAllocations(staff['id'] as String);

      expect(allocations.isNotEmpty, true);
      for (final alloc in allocations) {
        expect(alloc['subject_name'], 'English');
        expect(alloc['subject_code'], 'ENG');
      }
    });

    test('Teacher saves and updates syllabus, reflecting immediately in class syllabi', () async {
      const classId = 'class-8b';
      const term = 'half_yearly';

      // 1. Initial syllabi is clean/empty
      final initial = await repository.getSyllabiForClass(classId, examTerm: term);
      expect(initial.isEmpty, true);

      // 2. Teacher publishes Mathematics syllabus with new chapters & weightages
      final updatedSyllabus = Syllabus(
        id: 'syl-math-half',
        classSectionId: classId,
        subjectId: 'sub-math',
        subjectName: 'Mathematics',
        subjectCode: 'MATH',
        examTerm: term,
        title: 'Half Yearly Examination Syllabus (Maths)',
        chaptersOverview:
            '• Chapter 1: Rational Numbers (10 Marks)\n• Chapter 2: Linear Equations (15 Marks)\n• Chapter 3: Practical Geometry (15 Marks)\n• Chapter 4: Data Handling (20 Marks)',
        attachments: const [],
        updatedAt: DateTime.now(),
      );

      await repository.saveSyllabus(updatedSyllabus);

      // 3. Verify changes reflect when retrieved
      final updatedList = await repository.getSyllabiForClass(classId, examTerm: term);
      final mathSyllabus = updatedList.firstWhere((s) => s.subjectCode == 'MATH');

      expect(mathSyllabus.title, 'Half Yearly Examination Syllabus (Maths)');
      expect(mathSyllabus.chaptersOverview, contains('Data Handling (20 Marks)'));
      expect(mathSyllabus.chaptersOverview, contains('Chapter 1: Rational Numbers (10 Marks)'));
    });

    test('Teacher creates a new syllabus for another term and retrieves it', () async {
      const classId = 'class-8b';
      const term = 'annual_finals';

      final finalsSyllabus = Syllabus(
        id: 'syl-math-finals',
        classSectionId: classId,
        subjectId: 'sub-math',
        subjectName: 'Mathematics',
        subjectCode: 'MATH',
        examTerm: term,
        title: 'Annual Finals Syllabus (Mathematics)',
        chaptersOverview:
            '• Chapter 8: Comparing Quantities (10 Marks)\n• Chapter 9: Algebraic Expressions (15 Marks)\n• Chapter 10: Visualising Solid Shapes (10 Marks)\n• Chapter 11: Mensuration (20 Marks)\n• Chapter 12: Exponents and Powers (15 Marks)',
        attachments: const [],
        updatedAt: DateTime.now(),
      );

      await repository.saveSyllabus(finalsSyllabus);

      final list = await repository.getSyllabiForClass(classId, examTerm: term);
      expect(list.any((s) => s.id == 'syl-math-finals'), true);
      final found = list.firstWhere((s) => s.id == 'syl-math-finals');
      expect(found.title, 'Annual Finals Syllabus (Mathematics)');
      expect(found.termDisplayName, 'Annual Finals');
    });
  });
}
