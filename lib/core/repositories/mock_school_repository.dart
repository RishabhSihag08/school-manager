import 'dart:math';
import '../models/models.dart';
import '../widgets/unified_media_viewer.dart';
import 'school_repository.dart';

/// In-memory Mock Implementation of SchoolRepository with rich Indian school demo data.
class MockSchoolRepository implements SchoolRepository {
  // Demo Class Section 8-B
  final List<ClassSection> _classes = [
    const ClassSection(
      id: 'class-8b',
      grade: 8,
      section: 'B',
      classTeacherId: 'teacher-ramesh',
      classTeacherName: 'Mr. Ramesh Sharma',
      classCode: '8B-K9X2',
      isCodeLocked: false,
      academicYear: '2026-2027',
      timetableFileUrl:
          'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=1200',
    ),
    const ClassSection(
      id: 'class-6a',
      grade: 6,
      section: 'A',
      classTeacherId: 'teacher-sunita',
      classTeacherName: 'Mrs. Sunita Rao',
      classCode: '6A-M4P1',
      isCodeLocked: false,
      academicYear: '2026-2027',
    ),
    const ClassSection(
      id: 'class-7c',
      grade: 7,
      section: 'C',
      classTeacherId: 'teacher-vikram',
      classTeacherName: 'Mr. Vikram Singh',
      classCode: '7C-Q8W9',
      isCodeLocked: false,
      academicYear: '2026-2027',
    ),
  ];

  // Demo Students in 8-B
  late final List<Student> _students = [
    Student(
      id: 'student-aarav',
      rollNo: 1,
      fullName: 'Aarav Sharma',
      admissionNo: 'ADM2026101',
      classSectionId: 'class-8b',
      parentName: 'Rajesh Sharma',
      parentPhone: '+919876540001',
      house: 'red',
      pinHash: '1234',
      homeworkStreak: 5,
      joinedAt: DateTime(2026, 4, 1),
    ),
    Student(
      id: 'student-kabir',
      rollNo: 2,
      fullName: 'Kabir Verma',
      admissionNo: 'ADM2026102',
      classSectionId: 'class-8b',
      parentName: 'Sanjay Verma',
      parentPhone: '+919876540002',
      house: 'blue',
      pinHash: '1234',
      homeworkStreak: 3,
      joinedAt: DateTime(2026, 4, 2),
    ),
    Student(
      id: 'student-ananya',
      rollNo: 3,
      fullName: 'Ananya Gupta',
      admissionNo: 'ADM2026103',
      classSectionId: 'class-8b',
      parentName: 'Meera Gupta',
      parentPhone: '+919876540003',
      house: 'green',
      pinHash: '1234',
      homeworkStreak: 7,
      joinedAt: DateTime(2026, 4, 3),
    ),
    Student(
      id: 'student-rohan',
      rollNo: 4,
      fullName: 'Rohan Mehta',
      admissionNo: 'ADM2026104',
      classSectionId: 'class-8b',
      parentName: 'Nitin Mehta',
      parentPhone: '+919876540004',
      house: 'yellow',
      pinHash: '1234',
      homeworkStreak: 4,
      joinedAt: DateTime(2026, 4, 4),
    ),
  ];

  // Demo Attendance records
  late final List<Attendance> _attendanceRecords = _generateInitialAttendance();

  List<Attendance> _generateInitialAttendance() {
    final list = <Attendance>[];
    final today = DateTime.now();

    for (int dayOffset = 0; dayOffset < 30; dayOffset++) {
      final date = today.subtract(Duration(days: dayOffset));
      if (date.weekday == DateTime.sunday) continue;

      for (final student in _students) {
        AttendanceStatus status = AttendanceStatus.present;
        if (student.id == 'student-kabir' && (dayOffset == 2 || dayOffset == 3)) {
          status = AttendanceStatus.absent;
        } else if (student.id == 'student-rohan' && dayOffset == 7) {
          status = AttendanceStatus.leave;
        } else if (student.id == 'student-aarav' && dayOffset == 14) {
          status = AttendanceStatus.absent;
        }

        list.add(
          Attendance(
            id: 'att-${student.id}-$dayOffset',
            classSectionId: 'class-8b',
            studentId: student.id,
            date: date,
            status: status,
            markedBy: 'teacher-ramesh',
          ),
        );
      }
    }
    return list;
  }

  // Demo Timetable for 8-B
  final List<TimetablePeriod> _timetable = [
    const TimetablePeriod(
      id: 'p1',
      classSectionId: 'class-8b',
      dayOfWeek: 1, // Mon
      periodNo: 1,
      startTime: '08:00 AM',
      endTime: '08:45 AM',
      subjectName: 'Mathematics',
      subjectCode: 'MATH',
      teacherName: 'Mr. Ramesh Sharma',
    ),
    const TimetablePeriod(
      id: 'p2',
      classSectionId: 'class-8b',
      dayOfWeek: 1,
      periodNo: 2,
      startTime: '08:45 AM',
      endTime: '09:30 AM',
      subjectName: 'Science',
      subjectCode: 'SCI',
      teacherName: 'Mrs. Sunita Rao',
    ),
    const TimetablePeriod(
      id: 'p3',
      classSectionId: 'class-8b',
      dayOfWeek: 1,
      periodNo: 3,
      startTime: '09:30 AM',
      endTime: '10:15 AM',
      subjectName: 'English',
      subjectCode: 'ENG',
      teacherName: 'Mr. Vikram Singh',
    ),
    const TimetablePeriod(
      id: 'p4',
      classSectionId: 'class-8b',
      dayOfWeek: 1,
      periodNo: 4,
      startTime: '10:15 AM',
      endTime: '11:00 AM',
      subjectName: 'Hindi',
      subjectCode: 'HIN',
      teacherName: 'Mrs. Priya Joshi',
    ),
    const TimetablePeriod(
      id: 'p5',
      classSectionId: 'class-8b',
      dayOfWeek: 1,
      periodNo: 5,
      startTime: '11:00 AM',
      endTime: '11:30 AM',
      isBreak: true,
      breakLabel: '🍱 Recess / Lunch Break',
    ),
    const TimetablePeriod(
      id: 'p6',
      classSectionId: 'class-8b',
      dayOfWeek: 1,
      periodNo: 6,
      startTime: '11:30 AM',
      endTime: '12:15 PM',
      subjectName: 'Social Science',
      subjectCode: 'SST',
      teacherName: 'Mr. Amit Patel',
    ),
    const TimetablePeriod(
      id: 'p7',
      classSectionId: 'class-8b',
      dayOfWeek: 1,
      periodNo: 7,
      startTime: '12:15 PM',
      endTime: '01:00 PM',
      subjectName: 'Mathematics',
      subjectCode: 'MATH',
      teacherName: 'Mr. Ramesh Sharma',
    ),
    const TimetablePeriod(
      id: 'p8',
      classSectionId: 'class-8b',
      dayOfWeek: 1,
      periodNo: 8,
      startTime: '01:00 PM',
      endTime: '01:45 PM',
      subjectName: 'Computer Science',
      subjectCode: 'COMP',
      teacherName: 'Ms. Neha Kapoor',
    ),
  ];

  // Demo Homeworks
  late final List<Homework> _homeworks = [
    Homework(
      id: 'hw-1',
      classSectionId: 'class-8b',
      subjectId: 'sub-math',
      subjectName: 'Mathematics',
      subjectCode: 'MATH',
      teacherId: 'teacher-ramesh',
      teacherName: 'Mr. Ramesh Sharma',
      title: 'Linear Equations in One Variable',
      description:
          'Solve Exercise 2.3 Questions 1 to 10 in your class notebook. Show all intermediate steps and verification.',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      attachments: const [
        MediaAttachmentItem(
          title: 'Board Notes (Exercise 2.3).jpg',
          url:
              'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=1000',
          type: 'image',
          sizeKb: 180,
        ),
      ],
      isCompleted: false,
    ),
    Homework(
      id: 'hw-2',
      classSectionId: 'class-8b',
      subjectId: 'sub-sci',
      subjectName: 'Science',
      subjectCode: 'SCI',
      teacherId: 'teacher-sunita',
      teacherName: 'Mrs. Sunita Rao',
      title: 'Nitrogen Cycle Diagram & Experiment',
      description:
          'Draw and label the neat diagram of the Nitrogen Cycle in your practical file. Read section 2.4 on food preservation.',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      attachments: const [
        MediaAttachmentItem(
          title: 'Science Lab Manual - Unit 2.pdf',
          url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          type: 'pdf',
          sizeKb: 320,
        ),
      ],
      isCompleted: true,
    ),
    Homework(
      id: 'hw-3',
      classSectionId: 'class-8b',
      subjectId: 'sub-eng',
      subjectName: 'English',
      subjectCode: 'ENG',
      teacherId: 'teacher-vikram',
      teacherName: 'Mr. Vikram Singh',
      title: 'Active & Passive Voice Worksheet',
      description:
          'Convert the 15 sentences in Worksheet #4 into Passive Voice. Highlight the subject and object transforms.',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      attachments: const [
        MediaAttachmentItem(
          title: 'English Worksheet 4.pdf',
          url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          type: 'pdf',
          sizeKb: 140,
        ),
      ],
      isCompleted: false,
    ),
    Homework(
      id: 'hw-4',
      classSectionId: 'class-8b',
      subjectId: 'sub-sst',
      subjectName: 'Social Science',
      subjectCode: 'SST',
      teacherId: 'teacher-amit',
      teacherName: 'Mr. Amit Patel',
      title: 'Preamble to the Indian Constitution',
      description:
          'Write a short paragraph analyzing the key values in the Preamble: Sovereign, Socialist, Secular, Democratic, Republic.',
      dueDate: DateTime.now(),
      attachments: const [],
      isCompleted: true,
    ),
  ];

  // Demo Syllabus
  final List<Syllabus> _syllabi = [
    const Syllabus(
      id: 'syl-math-half',
      classSectionId: 'class-8b',
      subjectId: 'sub-math',
      subjectName: 'Mathematics',
      subjectCode: 'MATH',
      examTerm: 'half_yearly',
      title: 'Half Yearly Examination Syllabus (Maths)',
      chaptersOverview:
          '• Chapter 1: Rational Numbers (8 Marks)\n• Chapter 2: Linear Equations in One Variable (12 Marks)\n• Chapter 3: Understanding Quadrilaterals (10 Marks)\n• Chapter 4: Practical Geometry (10 Marks)\n• Chapter 5: Data Handling & Histograms (12 Marks)\n• Chapter 6: Squares and Square Roots (14 Marks)\n• Chapter 7: Cubes and Cube Roots (14 Marks)',
      attachments: [
        MediaAttachmentItem(
          title: 'Class 8 Maths Half Yearly Syllabus.pdf',
          url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          type: 'pdf',
          sizeKb: 240,
        ),
      ],
    ),
    const Syllabus(
      id: 'syl-sci-half',
      classSectionId: 'class-8b',
      subjectId: 'sub-sci',
      subjectName: 'Science',
      subjectCode: 'SCI',
      examTerm: 'half_yearly',
      title: 'Half Yearly Examination Syllabus (Science)',
      chaptersOverview:
          '• Chapter 1: Crop Production and Management (10 Marks)\n• Chapter 2: Microorganisms: Friend and Foe (14 Marks)\n• Chapter 3: Synthetic Fibres and Plastics (10 Marks)\n• Chapter 4: Materials: Metals and Non-Metals (16 Marks)\n• Chapter 5: Coal and Petroleum (10 Marks)\n• Chapter 6: Combustion and Flame (10 Marks)\n• Practical Lab Skills & Viva (10 Marks)',
      attachments: [
        MediaAttachmentItem(
          title: 'Class 8 Science Syllabus & Weightage.pdf',
          url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          type: 'pdf',
          sizeKb: 290,
        ),
      ],
    ),
    const Syllabus(
      id: 'syl-eng-half',
      classSectionId: 'class-8b',
      subjectId: 'sub-eng',
      subjectName: 'English',
      subjectCode: 'ENG',
      examTerm: 'half_yearly',
      title: 'Half Yearly Examination Syllabus (English)',
      chaptersOverview:
          '• Honeydew: The Best Christmas Present, The Tsunami, Glimpses of the Past, Bepin Choudhury\n• Poetry: The Ant and the Cricket, Geography Lesson\n• Grammar: Tenses, Modals, Active-Passive Voice, Reported Speech\n• Writing: Formal Letter & Story Writing',
      attachments: [],
    ),
  ];

  // Demo Exam Results
  late final List<ExamResult> _examResults = [
    // Aarav Sharma (Roll 1)
    const ExamResult(
      id: 'res-aarav-eng',
      examId: 'exam-half-yearly',
      examName: 'Half Yearly Examination',
      studentId: 'student-aarav',
      studentRollNo: 1,
      studentName: 'Aarav Sharma',
      classSectionId: 'class-8b',
      subjectId: 'sub-eng',
      subjectName: 'English',
      subjectCode: 'ENG',
      marksObtained: 88,
      maxMarks: 100,
      grade: 'A2',
      subjectRemarks: 'Good vocabulary, enhance cursive handwriting.',
    ),
    const ExamResult(
      id: 'res-aarav-math',
      examId: 'exam-half-yearly',
      examName: 'Half Yearly Examination',
      studentId: 'student-aarav',
      studentRollNo: 1,
      studentName: 'Aarav Sharma',
      classSectionId: 'class-8b',
      subjectId: 'sub-math',
      subjectName: 'Mathematics',
      subjectCode: 'MATH',
      marksObtained: 95,
      maxMarks: 100,
      grade: 'A1',
      subjectRemarks: 'Outstanding analytical clarity!',
    ),
    const ExamResult(
      id: 'res-aarav-sci',
      examId: 'exam-half-yearly',
      examName: 'Half Yearly Examination',
      studentId: 'student-aarav',
      studentRollNo: 1,
      studentName: 'Aarav Sharma',
      classSectionId: 'class-8b',
      subjectId: 'sub-sci',
      subjectName: 'Science',
      subjectCode: 'SCI',
      marksObtained: 91,
      maxMarks: 100,
      grade: 'A1',
      subjectRemarks: 'Neat diagrams and thorough concepts.',
    ),
    const ExamResult(
      id: 'res-aarav-sst',
      examId: 'exam-half-yearly',
      examName: 'Half Yearly Examination',
      studentId: 'student-aarav',
      studentRollNo: 1,
      studentName: 'Aarav Sharma',
      classSectionId: 'class-8b',
      subjectId: 'sub-sst',
      subjectName: 'Social Science',
      subjectCode: 'SST',
      marksObtained: 84,
      maxMarks: 100,
      grade: 'A2',
      subjectRemarks: 'Good answers in History.',
    ),
    const ExamResult(
      id: 'res-aarav-hin',
      examId: 'exam-half-yearly',
      examName: 'Half Yearly Examination',
      studentId: 'student-aarav',
      studentRollNo: 1,
      studentName: 'Aarav Sharma',
      classSectionId: 'class-8b',
      subjectId: 'sub-hin',
      subjectName: 'Hindi',
      subjectCode: 'HIN',
      marksObtained: 89,
      maxMarks: 100,
      grade: 'A2',
      subjectRemarks: 'Grammar and comprehension are solid.',
    ),

    // Kabir Verma (Roll 2)
    const ExamResult(
      id: 'res-kabir-eng',
      examId: 'exam-half-yearly',
      examName: 'Half Yearly Examination',
      studentId: 'student-kabir',
      studentRollNo: 2,
      studentName: 'Kabir Verma',
      classSectionId: 'class-8b',
      subjectId: 'sub-eng',
      subjectName: 'English',
      subjectCode: 'ENG',
      marksObtained: 76,
      maxMarks: 100,
      grade: 'B1',
    ),
    const ExamResult(
      id: 'res-kabir-math',
      examId: 'exam-half-yearly',
      examName: 'Half Yearly Examination',
      studentId: 'student-kabir',
      studentRollNo: 2,
      studentName: 'Kabir Verma',
      classSectionId: 'class-8b',
      subjectId: 'sub-math',
      subjectName: 'Mathematics',
      subjectCode: 'MATH',
      marksObtained: null,
      maxMarks: 100,
      status: 'absent',
      grade: '-',
      subjectRemarks: 'Absent due to viral fever.',
    ),
    const ExamResult(
      id: 'res-kabir-sci',
      examId: 'exam-half-yearly',
      examName: 'Half Yearly Examination',
      studentId: 'student-kabir',
      studentRollNo: 2,
      studentName: 'Kabir Verma',
      classSectionId: 'class-8b',
      subjectId: 'sub-sci',
      subjectName: 'Science',
      subjectCode: 'SCI',
      marksObtained: 81,
      maxMarks: 100,
      grade: 'A2',
    ),
    const ExamResult(
      id: 'res-kabir-sst',
      examId: 'exam-half-yearly',
      examName: 'Half Yearly Examination',
      studentId: 'student-kabir',
      studentRollNo: 2,
      studentName: 'Kabir Verma',
      classSectionId: 'class-8b',
      subjectId: 'sub-sst',
      subjectName: 'Social Science',
      subjectCode: 'SST',
      marksObtained: 72,
      maxMarks: 100,
      grade: 'B1',
    ),
    const ExamResult(
      id: 'res-kabir-hin',
      examId: 'exam-half-yearly',
      examName: 'Half Yearly Examination',
      studentId: 'student-kabir',
      studentRollNo: 2,
      studentName: 'Kabir Verma',
      classSectionId: 'class-8b',
      subjectId: 'sub-hin',
      subjectName: 'Hindi',
      subjectCode: 'HIN',
      marksObtained: 79,
      maxMarks: 100,
      grade: 'B1',
    ),
  ];

  // Demo Announcements
  late final List<Announcement> _announcements = [
    Announcement(
      id: 'ann-1',
      title: '🏖️ Tomorrow is a Holiday on account of Guru Nanak Jayanti',
      body:
          'The school will remain closed on Tuesday for Guru Nanak Jayanti. Classes and lab sessions will resume as per regular timetable on Wednesday.',
      category: AnnouncementCategory.holiday,
      isPinned: true,
      eventOrHolidayDate: DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      authorName: 'Principal Office',
      attachments: const [],
    ),
    Announcement(
      id: 'ann-2',
      title: '📝 Half-Yearly Examination Date Sheet & Syllabus Live',
      body:
          'The schedule and chapter blueprints for Half-Yearly Examinations 2026-27 have been published. Check your Syllabus Vault for topic weightage.',
      category: AnnouncementCategory.exam,
      isPinned: false,
      eventOrHolidayDate: DateTime.now().add(const Duration(days: 10)),
      targetGrade: 8,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      authorName: 'Academic Coordinator',
      attachments: const [
        MediaAttachmentItem(
          title: 'Half Yearly Date Sheet 2026.pdf',
          url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          type: 'pdf',
          sizeKb: 180,
        ),
      ],
    ),
    Announcement(
      id: 'ann-3',
      title: '🚨 Winter Uniform Transition from Next Monday',
      body:
          'All students from Grade 1 to 12 must transition to formal winter navy blue blazers with crest, grey trousers, and school woollen ties starting Monday.',
      category: AnnouncementCategory.urgent,
      isPinned: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      authorName: 'Administration',
    ),
  ];

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
      admissionNo: admissionNo ?? 'ADM2026${100 + rollNo}',
      classSectionId: cls.id,
      parentName: parentName,
      parentPhone: parentPhone,
      house: house.toLowerCase(),
      pinHash: pin,
      homeworkStreak: 1,
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
    if (records.isEmpty) return 92.4; // Default pleasant stat
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
    return _examResults.where((r) => r.studentId == studentId).toList();
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
      examId: 'exam-half-yearly',
      examName: examName,
      studentId: studentId,
      totalObtained: obtained,
      totalMax: maxTotal,
      percentage: double.parse(percentage.toStringAsFixed(1)),
      overallGrade: grade,
      rankInClass: 1,
      classTeacherRemarks:
          'Aarav is an exemplary student with top-tier performance in Mathematics and Science.',
    );
  }

  @override
  Future<List<ExamResult>> getClassExamResults(
    String classSectionId,
    String examName,
  ) async {
    return _examResults
        .where((r) => r.classSectionId == classSectionId)
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
    final cleanCode = loginCode.trim().toLowerCase();
    if (cleanCode == 'ramesh' && pin == '1234') {
      return {
        'id': 'teacher-ramesh',
        'role': 'teacher',
        'full_name': 'Mr. Ramesh Sharma',
        'homeroom_class_id': 'class-8b',
        'homeroom_class_name': 'Class 8-B',
        'homeroom_class_code': '8B-K9X2',
      };
    } else if (cleanCode == 'admin' && pin == '1234') {
      return {
        'id': 'admin-office',
        'role': 'admin',
        'full_name': 'Office Administration',
      };
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherSubjectAllocations(
    String teacherId,
  ) async {
    if (teacherId == 'teacher-ramesh') {
      return [
        {
          'class_section_id': 'class-8b',
          'class_name': 'Class 8-B',
          'subject_name': 'Mathematics',
          'subject_code': 'MATH',
          'is_homeroom': true,
        },
        {
          'class_section_id': 'class-6a',
          'class_name': 'Class 6-A',
          'subject_name': 'Mathematics',
          'subject_code': 'MATH',
          'is_homeroom': false,
        },
        {
          'class_section_id': 'class-7c',
          'class_name': 'Class 7-C',
          'subject_name': 'Mathematics',
          'subject_code': 'MATH',
          'is_homeroom': false,
        },
      ];
    }
    return [];
  }
}
