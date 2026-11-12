import 'package:flutter_test/flutter_test.dart';
import 'package:school_manager/core/models/exam_result.dart';

void main() {
  group('CBSE 8-Tier Grading System (A1 to E)', () {
    test('Grades percentage >= 91 as A1', () {
      expect(ExamResult.calculateCbseGrade(100.0, 100.0), equals('A1'));
      expect(ExamResult.calculateCbseGrade(95.5, 100.0), equals('A1'));
      expect(ExamResult.calculateCbseGrade(91.0, 100.0), equals('A1'));
      expect(ExamResult.calculateCbseGrade(45.5, 50.0), equals('A1')); // 91%
    });

    test('Grades percentage >= 81 and < 91 as A2', () {
      expect(ExamResult.calculateCbseGrade(90.9, 100.0), equals('A2'));
      expect(ExamResult.calculateCbseGrade(85.0, 100.0), equals('A2'));
      expect(ExamResult.calculateCbseGrade(81.0, 100.0), equals('A2'));
    });

    test('Grades percentage >= 71 and < 81 as B1', () {
      expect(ExamResult.calculateCbseGrade(80.5, 100.0), equals('B1'));
      expect(ExamResult.calculateCbseGrade(75.0, 100.0), equals('B1'));
      expect(ExamResult.calculateCbseGrade(71.0, 100.0), equals('B1'));
    });

    test('Grades percentage >= 61 and < 71 as B2', () {
      expect(ExamResult.calculateCbseGrade(70.0, 100.0), equals('B2'));
      expect(ExamResult.calculateCbseGrade(65.0, 100.0), equals('B2'));
      expect(ExamResult.calculateCbseGrade(61.0, 100.0), equals('B2'));
    });

    test('Grades percentage >= 51 and < 61 as C1', () {
      expect(ExamResult.calculateCbseGrade(60.0, 100.0), equals('C1'));
      expect(ExamResult.calculateCbseGrade(55.0, 100.0), equals('C1'));
      expect(ExamResult.calculateCbseGrade(51.0, 100.0), equals('C1'));
    });

    test('Grades percentage >= 41 and < 51 as C2', () {
      expect(ExamResult.calculateCbseGrade(50.0, 100.0), equals('C2'));
      expect(ExamResult.calculateCbseGrade(45.0, 100.0), equals('C2'));
      expect(ExamResult.calculateCbseGrade(41.0, 100.0), equals('C2'));
    });

    test('Grades percentage >= 33 and < 41 as D (Pass boundary)', () {
      expect(ExamResult.calculateCbseGrade(40.0, 100.0), equals('D'));
      expect(ExamResult.calculateCbseGrade(35.0, 100.0), equals('D'));
      expect(ExamResult.calculateCbseGrade(33.0, 100.0), equals('D'));
    });

    test('Grades percentage < 33 as E (Needs Improvement)', () {
      expect(ExamResult.calculateCbseGrade(32.9, 100.0), equals('E'));
      expect(ExamResult.calculateCbseGrade(15.0, 100.0), equals('E'));
      expect(ExamResult.calculateCbseGrade(0.0, 100.0), equals('E'));
      expect(ExamResult.calculateCbseGrade(null, 100.0), equals('E'));
    });
  });

  group('ExamResult Model serialization & status', () {
    test('correctly calculates grade on JSON deserialization when omitted', () {
      final json = {
        'id': 'res-1',
        'exam_id': 'exam-1',
        'student_id': 'stud-1',
        'class_section_id': 'sec-1',
        'subject_id': 'sub-1',
        'marks_obtained': 92.0,
        'max_marks': 100.0,
        'status': 'present',
      };

      final result = ExamResult.fromJson(json);
      expect(result.grade, equals('A1'));
      expect(result.status, equals('present'));
      expect(result.marksObtained, equals(92.0));
    });

    test('handles absent student with null marks and hyphen grade', () {
      final json = {
        'id': 'res-2',
        'exam_id': 'exam-1',
        'student_id': 'stud-2',
        'class_section_id': 'sec-1',
        'subject_id': 'sub-1',
        'marks_obtained': null,
        'max_marks': 100.0,
        'status': 'absent',
      };

      final result = ExamResult.fromJson(json);
      expect(result.grade, equals('-'));
      expect(result.status, equals('absent'));
      expect(result.marksObtained, isNull);
    });
  });
}
