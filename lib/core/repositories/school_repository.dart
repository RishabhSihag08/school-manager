import '../models/models.dart';

/// Abstract contract for School data access across Mobile & Web.
/// Provides mock demo implementation and can be backed by Supabase.
abstract class SchoolRepository {
  // --- Class Code & Student Onboarding ---
  Future<ClassSection?> findClassByCode(String code);

  Future<Student> registerStudentWithCode({
    required String classCode,
    required String fullName,
    required int rollNo,
    String? admissionNo,
    required String parentName,
    required String parentPhone,
    required String house,
    required String pin,
  });

  Future<Student?> loginStudent({
    required String classSectionId,
    required int rollNo,
    required String pin,
  });

  Future<List<Student>> getSiblings(List<String> studentIds);

  Future<Student?> getStudentById(String studentId);

  Future<Student> updateStudent(Student student);

  // --- Class Sections & Roster ---
  Future<ClassSection?> getClassSectionById(String classSectionId);

  Future<List<ClassSection>> getAllClassSections();

  Future<ClassSection> createClassSection({
    required int grade,
    required String section,
    required String classCode,
    String? classTeacherId,
    String? classTeacherName,
    String? customName,
  });

  Future<List<Student>> getStudentsForClass(String classSectionId);

  Future<List<Student>> getAllStudents();

  Future<void> updateStudentRollNo(String studentId, int newRollNo);

  Future<void> setClassCodeLocked(String classSectionId, bool isLocked);

  Future<String> regenerateClassCode(String classSectionId);

  Future<void> deleteClassSection(String classSectionId);

  // --- Attendance ---
  Future<List<Attendance>> getAttendanceForDate(
    String classSectionId,
    DateTime date,
  );

  Future<List<Attendance>> getAttendanceForStudent(
    String studentId, {
    int? month,
    int? year,
  });

  Future<double> getStudentAttendancePercentage(String studentId);

  Future<void> submitClassAttendance({
    required String classSectionId,
    required DateTime date,
    required Map<String, AttendanceStatus> attendanceMap,
    required String markedBy,
  });

  // --- Timetable ---
  Future<void> updateClassTimetableUrl(String classSectionId, String url);

  Future<List<TimetablePeriod>> getTimetableForDay(
    String classSectionId,
    int dayOfWeek,
  );

  Future<List<TimetablePeriod>> getFullTimetable(String classSectionId);

  Future<void> saveTimetable(
    String classSectionId,
    List<TimetablePeriod> periods,
  );

  // --- Syllabus ---
  Future<List<Syllabus>> getSyllabiForClass(
    String classSectionId, {
    String? examTerm,
  });

  Future<void> saveSyllabus(Syllabus syllabus);

  // --- Homework ---
  Future<List<Homework>> getHomeworksForClass(
    String classSectionId, {
    String? studentId,
  });

  Future<void> toggleHomeworkCompletion({
    required String homeworkId,
    required String studentId,
    required bool isCompleted,
  });

  Future<void> createHomework(Homework homework);

  // --- Exams & Results ---
  Future<List<String>> getAvailableExams();

  Future<List<ExamResult>> getStudentExamResults(
    String studentId,
    String examName,
  );

  Future<ExamStudentSummary?> getStudentExamSummary(
    String studentId,
    String examName,
  );

  Future<List<ExamResult>> getClassExamResults(
    String classSectionId,
    String examName,
  );

  Future<void> publishExamResults({
    required String examName,
    required String classSectionId,
    required List<ExamResult> results,
  });

  // --- Announcements ---
  Future<List<Announcement>> getAnnouncements({
    int? grade,
    String? classSectionId,
  });

  Future<Announcement?> getPinnedAnnouncement({
    int? grade,
    String? classSectionId,
  });

  Future<void> createAnnouncement(Announcement announcement);

  Future<void> deleteAnnouncement(String announcementId);

  // --- Staff & Teachers ---
  Future<Map<String, dynamic>?> loginStaff({
    required String loginCode,
    required String pin,
  });

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
    List<String>? teachingClassIds,
  });

  Future<List<Map<String, dynamic>>> getTeacherSubjectAllocations(
    String teacherId,
  );

  Future<List<Map<String, dynamic>>> getAllSubjectAllocations();
}
