import 'package:flutter_test/flutter_test.dart';
import 'package:school_manager/core/models/models.dart';
import 'package:school_manager/core/repositories/mock_school_repository.dart';
import 'package:school_manager/core/repositories/supabase_school_repository.dart';

void main() {
  group('SchoolRepository & Problem 1/8/9 Unit Tests', () {
    late MockSchoolRepository mockRepo;
    late SupabaseSchoolRepository supabaseRepo;

    setUp(() {
      mockRepo = MockSchoolRepository();
      supabaseRepo = SupabaseSchoolRepository();
    });

    test('Clean state: initial students and announcements are empty (Problem 9)', () async {
      final students = await mockRepo.getStudentsForClass('class-8b');
      expect(students, isEmpty, reason: 'Must not have hardcoded dummy students (Aarav, Diya)');

      final announcements = await mockRepo.getAnnouncements();
      expect(announcements, isEmpty, reason: 'Must not have hardcoded fake circulars');

      final attPct = await mockRepo.getStudentAttendancePercentage('non-existent');
      expect(attPct, 0.0);
    });

    test('Class creation works for Admin (Problem 7)', () async {
      final newClass = await mockRepo.createClassSection(
        grade: 10,
        section: 'A',
        classCode: '10A-T9X1',
        classTeacherName: 'Dr. APJ Kalam',
      );

      expect(newClass.grade, 10);
      expect(newClass.section, 'A');
      expect(newClass.classCode, '10A-T9X1');
      expect(newClass.displayName, 'Class 10-A');

      final found = await mockRepo.findClassByCode('10a-t9x1');
      expect(found, isNotNull);
      expect(found!.id, newClass.id);
    });

    test('Student registration and Admin student editing (Problem 8)', () async {
      final student = await mockRepo.registerStudentWithCode(
        classCode: '8B-K9X2',
        fullName: 'Real Student Name',
        rollNo: 15,
        parentName: 'Parent Real',
        parentPhone: '+919999988888',
        house: 'blue',
        pin: '5678',
      );

      expect(student.fullName, 'Real Student Name');
      expect(student.rollNo, 15);

      // Verify retrieval by ID
      final fetched = await mockRepo.getStudentById(student.id);
      expect(fetched, isNotNull);
      expect(fetched!.fullName, 'Real Student Name');

      // Update student as Admin
      final updated = await mockRepo.updateStudent(
        student.copyWith(
          fullName: 'Updated Student Name',
          rollNo: 16,
          parentName: 'Updated Parent',
        ),
      );

      expect(updated.fullName, 'Updated Student Name');
      expect(updated.rollNo, 16);

      final reFetched = await mockRepo.getStudentById(student.id);
      expect(reFetched!.fullName, 'Updated Student Name');
      expect(reFetched.rollNo, 16);
    });

    test('Teacher registration with subject selection (Problem 3)', () async {
      final staff = await mockRepo.registerStaff(
        fullName: 'Prof. Sharma',
        role: 'teacher',
        loginCode: 'prof_sharma',
        pin: '4321',
        subjectName: 'Physics',
        subjectCode: 'PHY',
        homeroomClassId: 'class-8b',
        homeroomClassName: 'Class 8-B',
      );

      expect(staff['full_name'], 'Prof. Sharma');
      expect(staff['subject_name'], 'Physics');
      expect(staff['subject_code'], 'PHY');

      final allocations = await mockRepo.getTeacherSubjectAllocations(staff['id'] as String);
      expect(allocations, isNotEmpty);
      expect(allocations.first['subject_name'], 'Physics');
    });

    test('Attendance recording and percentage calculation', () async {
      final today = DateTime.now();
      await mockRepo.submitClassAttendance(
        classSectionId: 'class-8b',
        date: today,
        attendanceMap: {
          'stu-1': AttendanceStatus.present,
          'stu-2': AttendanceStatus.absent,
        },
        markedBy: 'teacher-1',
      );

      final dateRecords = await mockRepo.getAttendanceForDate('class-8b', today);
      expect(dateRecords.length, 2);

      final stu1Pct = await mockRepo.getStudentAttendancePercentage('stu-1');
      expect(stu1Pct, 100.0);

      final stu2Pct = await mockRepo.getStudentAttendancePercentage('stu-2');
      expect(stu2Pct, 0.0);
    });

    test('Syllabus and Homework lifecycle (Problem 5)', () async {
      const syllabus = Syllabus(
        id: 'syl-phy-1',
        classSectionId: 'class-8b',
        subjectId: 'sub-phy',
        subjectName: 'Physics',
        subjectCode: 'PHY',
        examTerm: 'unit_test_1',
        title: 'Force and Pressure',
        chaptersOverview: '• Chapter 11: Force and Pressure',
      );

      await mockRepo.saveSyllabus(syllabus);
      final syllabi = await mockRepo.getSyllabiForClass('class-8b', examTerm: 'unit_test_1');
      expect(syllabi.length, 1);
      expect(syllabi.first.title, 'Force and Pressure');

      final hw = Homework(
        id: 'hw-phy-1',
        classSectionId: 'class-8b',
        subjectId: 'sub-phy',
        subjectName: 'Physics',
        subjectCode: 'PHY',
        title: 'Numerical Problems on Pressure',
        dueDate: DateTime.now().add(const Duration(days: 2)),
      );

      await mockRepo.createHomework(hw);
      final list = await mockRepo.getHomeworksForClass('class-8b');
      expect(list.length, 1);
      expect(list.first.title, 'Numerical Problems on Pressure');
    });

    test('SupabaseSchoolRepository graceful fallback works without crashing', () async {
      // Supabase is uninitialized in unit test environment
      final classes = await supabaseRepo.getAllClassSections();
      expect(classes, isNotEmpty);

      final student = await supabaseRepo.registerStudentWithCode(
        classCode: '8B-K9X2',
        fullName: 'Offline Test Student',
        rollNo: 99,
        parentName: 'Test Parent',
        parentPhone: '+919000000000',
        house: 'green',
        pin: '1111',
      );
      expect(student.fullName, 'Offline Test Student');

      final found = await supabaseRepo.getStudentById(student.id);
      expect(found, isNotNull);
      expect(found!.fullName, 'Offline Test Student');
    });
  });
}
