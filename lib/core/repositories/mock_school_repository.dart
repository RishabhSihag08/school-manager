import 'dart:math';
import '../config/app_config.dart';
import '../models/models.dart';
import 'school_repository.dart';

/// Clean in-memory Mock Implementation of SchoolRepository.
/// Stores records created at runtime with clean empty initial states.
class MockSchoolRepository implements SchoolRepository {
  // Class Sections
  final List<ClassSection> _classes = [
    const ClassSection(
      id: 'class-8b',
      grade: 8,
      section: 'B',
      classCode: '8B-K9X2',
      isCodeLocked: false,
      academicYear: '2026-2027',
    ),
    const ClassSection(
      id: 'class-6a',
      grade: 6,
      section: 'A',
      classCode: '6A-M4P1',
      isCodeLocked: false,
      academicYear: '2026-2027',
    ),
    const ClassSection(
      id: 'class-7c',
      grade: 7,
      section: 'C',
      classCode: '7C-Q8W9',
      isCodeLocked: false,
      academicYear: '2026-2027',
    ),
  ];

  // Clean empty state: No hardcoded dummy students
  final List<Student> _students = [];

  // Clean empty state: No fake attendance records
  final List<Attendance> _attendanceRecords = [];

  // Timetable
  final List<TimetablePeriod> _timetable = [];

  // Clean empty state: No fake homeworks
  final List<Homework> _homeworks = [];

  // Clean empty state: No fake syllabi
  final List<Syllabus> _syllabi = [];

  // Clean empty state: No fake exam results
  final List<ExamResult> _examResults = [];

  // Clean empty state: No fake circulars
  final List<Announcement> _announcements = [];

  // Clean staff store
  final List<Map<String, dynamic>> _staffList = [];

  MockSchoolRepository() {
    _bootstrapDefaultAdmin();
  }

  void _bootstrapDefaultAdmin() {
    if (!_staffList.any((s) => s['role'] == 'admin')) {
      _staffList.add({
        'id': 'staff-admin-01',
        'role': 'admin',
        'login_code': 'admin-01',
        'full_name': 'School Administrator',
        'phone': '',
        'homeroom_class_id': null,
        'homeroom_class_name': null,
        'homeroom_class_code': null,
        'subject_name': null,
        'subject_code': null,
        'pin': '1234',
      });
    }
  }

  // Implementation of SchoolRepository methods

  @override
  Future<ClassSection?> findClassByCode(String code) async {
    final clean = code.trim().toUpperCase();
    for (final cls in _classes) {
      if (cls.classCode.toUpperCase() == clean) {
        return cls;
      }
    }
    return null;
  }

  @override
  Future<Student> registerStudentWithCode({
    required String classCode,
    required String fullName,
    required int rollNo,
    String? admissionNo,
    required String parentName,
    required String parentPhone,
    required String house,
    required String pin,
  }) async {
    final cls = await findClassByCode(classCode);
    if (cls == null) {
      throw Exception('Class with code "$classCode" not found.');
    }
    if (cls.isCodeLocked) {
      throw Exception('This class has been locked by the Class Teacher.');
    }

    final newStudent = Student(
      id: 'student-${DateTime.now().millisecondsSinceEpoch}',
      rollNo: rollNo,
      fullName: fullName,
      admissionNo: admissionNo ?? 'ADM${DateTime.now().year}${100 + rollNo}',
      classSectionId: cls.id,
      parentName: parentName,
      parentPhone: parentPhone,
      house: house.toLowerCase(),
      pinHash: pin,
      homeworkStreak: 0,
      joinedAt: DateTime.now(),
    );

    _students.removeWhere(
      (s) => s.classSectionId == cls.id && s.rollNo == rollNo,
    );
    _students.add(newStudent);
    return newStudent;
  }

  @override
  Future<Student?> loginStudent({
    required String classSectionId,
    required int rollNo,
    required String pin,
  }) async {
    for (final s in _students) {
      if (s.classSectionId == classSectionId &&
          s.rollNo == rollNo &&
          s.pinHash == pin) {
        return s;
      }
    }
    return null;
  }

  @override
  Future<List<Student>> getSiblings(List<String> studentIds) async {
    return _students.where((s) => studentIds.contains(s.id)).toList();
  }

  @override
  Future<Student?> getStudentById(String studentId) async {
    for (final s in _students) {
      if (s.id == studentId) return s;
    }
    return null;
  }

  @override
  Future<Student> updateStudent(Student student) async {
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      _students[index] = student;
      return student;
    }
    _students.add(student);
    return student;
  }

  @override
  Future<ClassSection?> getClassSectionById(String classSectionId) async {
    for (final cls in _classes) {
      if (cls.id == classSectionId) return cls;
    }
    return null;
  }

  @override
  Future<List<ClassSection>> getAllClassSections() async {
    return List.unmodifiable(_classes);
  }

  @override
  Future<ClassSection> createClassSection({
    required int grade,
    required String section,
    required String classCode,
    String? classTeacherId,
    String? classTeacherName,
    String? customName,
  }) async {
    final newClass = ClassSection(
      id: 'class-${DateTime.now().millisecondsSinceEpoch}',
      grade: grade,
      section: section.toUpperCase().trim(),
      classCode: classCode.toUpperCase().trim(),
      classTeacherId: classTeacherId,
      classTeacherName: classTeacherName,
      customName: customName,
      isCodeLocked: false,
      academicYear: '2026-2027',
    );
    _classes.add(newClass);
    return newClass;
  }

  @override
  Future<List<Student>> getStudentsForClass(String classSectionId) async {
    final list = _students.where((s) => s.classSectionId == classSectionId).toList();
    list.sort((a, b) => a.rollNo.compareTo(b.rollNo));
    return list;
  }

  @override
  Future<void> updateStudentRollNo(String studentId, int newRollNo) async {
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      final s = _students[index];
      _students[index] = s.copyWith(rollNo: newRollNo);
    }
  }

  @override
  Future<void> setClassCodeLocked(String classSectionId, bool isLocked) async {
    final index = _classes.indexWhere((c) => c.id == classSectionId);
    if (index != -1) {
      final c = _classes[index];
      _classes[index] = c.copyWith(isCodeLocked: isLocked);
    }
  }

  @override
  Future<String> regenerateClassCode(String classSectionId) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final newSuffix = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    final index = _classes.indexWhere((c) => c.id == classSectionId);
    if (index != -1) {
      final c = _classes[index];
      final newCode = '${c.grade}${c.section}-$newSuffix';
      _classes[index] = c.copyWith(classCode: newCode);
      return newCode;
    }
    return '8B-NEW1';
  }

  @override
  Future<List<Attendance>> getAttendanceForDate(
    String classSectionId,
    DateTime date,
  ) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return _attendanceRecords
        .where((a) =>
            a.classSectionId == classSectionId &&
            a.date.toIso8601String().split('T')[0] == dateStr)
        .toList();
  }

  @override
  Future<List<Attendance>> getAttendanceForStudent(
    String studentId, {
    int? month,
    int? year,
  }) async {
    return _attendanceRecords.where((a) {
      if (a.studentId != studentId) return false;
      if (month != null && a.date.month != month) return false;
      if (year != null && a.date.year != year) return false;
      return true;
    }).toList();
  }

  @override
  Future<double> getStudentAttendancePercentage(String studentId) async {
    final records = _attendanceRecords.where((a) => a.studentId == studentId).toList();
    if (records.isEmpty) return 0.0;
    final presentCount = records.where((a) => a.status == AttendanceStatus.present).length;
    return (presentCount / records.length) * 100.0;
  }

  @override
  Future<void> submitClassAttendance({
    required String classSectionId,
    required DateTime date,
    required Map<String, AttendanceStatus> attendanceMap,
    required String markedBy,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    _attendanceRecords.removeWhere((a) =>
        a.classSectionId == classSectionId &&
        a.date.toIso8601String().split('T')[0] == dateStr);

    attendanceMap.forEach((studentId, status) {
      _attendanceRecords.add(
        Attendance(
          id: 'att-$studentId-$dateStr',
          classSectionId: classSectionId,
          studentId: studentId,
          date: date,
          status: status,
          markedBy: markedBy,
        ),
      );
    });
  }

  @override
  Future<void> updateClassTimetableUrl(String classSectionId, String url) async {
    final idx = _classes.indexWhere((c) => c.id == classSectionId);
    if (idx != -1) {
      _classes[idx] = _classes[idx].copyWith(timetableFileUrl: url);
    }
  }

  @override
  Future<List<TimetablePeriod>> getTimetableForDay(
    String classSectionId,
    int dayOfWeek,
  ) async {
    return _timetable
        .where((t) => t.classSectionId == classSectionId && t.dayOfWeek == dayOfWeek)
        .toList();
  }

  @override
  Future<List<TimetablePeriod>> getFullTimetable(String classSectionId) async {
    return _timetable.where((t) => t.classSectionId == classSectionId).toList();
  }

  @override
  Future<void> saveTimetable(
    String classSectionId,
    List<TimetablePeriod> periods,
  ) async {
    _timetable.removeWhere((t) => t.classSectionId == classSectionId);
    _timetable.addAll(periods);
  }

  @override
  Future<List<Syllabus>> getSyllabiForClass(
    String classSectionId, {
    String? examTerm,
  }) async {
    return _syllabi.where((s) {
      if (s.classSectionId != classSectionId) return false;
      if (examTerm != null && examTerm != 'all' && s.examTerm != examTerm) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> saveSyllabus(Syllabus syllabus) async {
    _syllabi.removeWhere((s) => s.id == syllabus.id);
    _syllabi.add(syllabus);
  }

  @override
  Future<List<Homework>> getHomeworksForClass(
    String classSectionId, {
    String? studentId,
  }) async {
    return _homeworks.where((h) => h.classSectionId == classSectionId).toList();
  }

  @override
  Future<void> toggleHomeworkCompletion({
    required String homeworkId,
    required String studentId,
    required bool isCompleted,
  }) async {
    final index = _homeworks.indexWhere((h) => h.id == homeworkId);
    if (index != -1) {
      final hw = _homeworks[index];
      _homeworks[index] = hw.copyWith(isCompleted: isCompleted);
    }
  }

  @override
  Future<void> createHomework(Homework homework) async {
    _homeworks.insert(0, homework);
  }

  @override
  Future<List<String>> getAvailableExams() async {
    return const [
      'Unit Test 1',
      'Half Yearly Examination',
      'Unit Test 2',
      'Annual Finals',
    ];
  }

  @override
  Future<List<ExamResult>> getStudentExamResults(
    String studentId,
    String examName,
  ) async {
    return _examResults.where((r) => r.studentId == studentId && r.examName == examName).toList();
  }

  @override
  Future<ExamStudentSummary?> getStudentExamSummary(
    String studentId,
    String examName,
  ) async {
    final results = await getStudentExamResults(studentId, examName);
    if (results.isEmpty) return null;

    double obtained = 0;
    double maxTotal = 0;
    for (final r in results) {
      if (r.status == 'present' && r.marksObtained != null) {
        obtained += r.marksObtained!;
      }
      maxTotal += r.maxMarks;
    }

    final percentage = maxTotal > 0 ? (obtained / maxTotal) * 100.0 : 0.0;
    final grade = ExamResult.calculateCbseGrade(obtained, maxTotal);

    return ExamStudentSummary(
      examId: 'exam-$examName',
      examName: examName,
      studentId: studentId,
      totalObtained: obtained,
      totalMax: maxTotal,
      percentage: double.parse(percentage.toStringAsFixed(1)),
      overallGrade: grade,
      rankInClass: 1,
    );
  }

  @override
  Future<List<ExamResult>> getClassExamResults(
    String classSectionId,
    String examName,
  ) async {
    return _examResults
        .where((r) => r.classSectionId == classSectionId && r.examName == examName)
        .toList();
  }

  @override
  Future<void> publishExamResults({
    required String examName,
    required String classSectionId,
    required List<ExamResult> results,
  }) async {
    _examResults.removeWhere(
      (r) => r.classSectionId == classSectionId && r.examName == examName,
    );
    _examResults.addAll(results);
  }

  @override
  Future<List<Announcement>> getAnnouncements({
    int? grade,
    String? classSectionId,
  }) async {
    return _announcements.where((a) {
      if (a.targetGrade != null && grade != null && a.targetGrade != grade) {
        return false;
      }
      if (a.targetClassSectionId != null &&
          classSectionId != null &&
          a.targetClassSectionId != classSectionId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Announcement?> getPinnedAnnouncement({
    int? grade,
    String? classSectionId,
  }) async {
    final list = await getAnnouncements(
      grade: grade,
      classSectionId: classSectionId,
    );
    for (final a in list) {
      if (a.isPinned) return a;
    }
    return null;
  }

  @override
  Future<void> createAnnouncement(Announcement announcement) async {
    _announcements.insert(0, announcement);
  }

  @override
  Future<Map<String, dynamic>?> loginStaff({
    required String loginCode,
    required String pin,
  }) async {
    _bootstrapDefaultAdmin();
    final cleanCode = loginCode.trim().toLowerCase();
    final cleanPin = pin.trim();
    final masterKey = AppConfig.masterKey;

    final isMasterKeyPin = cleanPin == masterKey || cleanPin == 'SirChotuRam';
    final isAdminCode = cleanCode == 'admin' || cleanCode == 'admin-01';

    // Support Master Key ('SirChotuRam') fallback: If credentials match masterKey or code is 'admin' with masterKey or PIN '1234', or if code is 'ADMIN-01' / 'admin', authenticate successfully as admin.
    if ((isAdminCode && (cleanPin == '1234' || isMasterKeyPin)) ||
        (cleanCode == masterKey.toLowerCase() || cleanCode == 'sirchoturam') ||
        (isMasterKeyPin && (cleanCode.isEmpty || isAdminCode))) {
      final admin = _staffList.firstWhere(
        (s) => s['role'] == 'admin',
        orElse: () => {
          'id': 'staff-admin-01',
          'role': 'admin',
          'login_code': 'admin-01',
          'full_name': 'School Administrator',
          'phone': '',
          'homeroom_class_id': null,
          'homeroom_class_name': null,
          'homeroom_class_code': null,
          'subject_name': null,
          'subject_code': null,
          'pin': '1234',
        },
      );
      return Map<String, dynamic>.from(admin);
    }

    for (final s in _staffList) {
      final code = (s['login_code'] as String? ?? '').toLowerCase();
      final userPin = (s['pin'] as String? ?? '').trim();
      if (code == cleanCode && (userPin == cleanPin || isMasterKeyPin)) {
        return Map<String, dynamic>.from(s);
      }
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> registerStaff({
    required String fullName,
    required String role,
    required String loginCode,
    required String pin,
    String? phone,
    String? homeroomClassId,
    String? homeroomClassName,
    String? subjectName,
    String? subjectCode,
  }) async {
    final cleanCode = loginCode.trim().toLowerCase();
    final newStaff = {
      'id': 'staff-${DateTime.now().millisecondsSinceEpoch}',
      'role': role,
      'login_code': cleanCode,
      'full_name': fullName.trim(),
      'phone': phone?.trim() ?? '',
      'homeroom_class_id': homeroomClassId,
      'homeroom_class_name': homeroomClassName,
      'homeroom_class_code': homeroomClassId != null ? '8B-K9X2' : null,
      'subject_name': subjectName,
      'subject_code': subjectCode,
      'pin': pin.trim(),
    };
    _staffList.add(newStaff);
    return Map<String, dynamic>.from(newStaff);
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherSubjectAllocations(
    String teacherId,
  ) async {
    final staff = _staffList.firstWhere(
      (s) => s['id'] == teacherId,
      orElse: () => <String, dynamic>{},
    );
    if (staff.isNotEmpty && staff['subject_name'] != null) {
      return [
        {
          'class_section_id': staff['homeroom_class_id'] ?? 'class-8b',
          'class_name': staff['homeroom_class_name'] ?? 'Class 8-B',
          'subject_name': staff['subject_name'],
          'subject_code': staff['subject_code'] ?? 'SUB',
          'is_homeroom': true,
        }
      ];
    }
    return [];
  }
}
